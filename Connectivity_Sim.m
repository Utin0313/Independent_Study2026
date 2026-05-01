clc; clear; close all;

%% 1. LOAD THE SIGNAL POWER DATA
fileInfo = dir('PowerSimResults_*.mat');
[~, idx] = max([fileInfo.datenum]); 
latestFile = fileInfo(idx).name;
fprintf('Loading power matrix from: %s\n', latestFile);
load(latestFile); 

%% 2. INITIALIZE SIMULATOR WITH SAVED DATA
% Reconstruct the simulator using the saved clusters
allClusters = [clusters{:}];
sim = WirelessSimulator(allClusters);

% INJECT the saved power matrix back into the object
% This prevents the simulator from rerunning Longley-Rice
sim.StoredSS = globalPowerMatrix; 

%% 3. RUN CONNECTIVITY MODEL
% You can change these parameters
modelType = "Bernoulli"; 
threshold = -35;

% Printing what model and threshold is being used
fprintf('Computing %s connectivity at %d dBm...\n', modelType, threshold);

% Performing global connectivity
[globalConMatrix, globalProbabilityMatrix] = sim.computeConnectivity(modelType, threshold);
% Find the total number of non-zero entries (active links)
numLinks = sum(globalConMatrix(:)); 

% Display the result
fprintf('Total number of active wireless links: %d\n', numLinks);

% Performing individual connectivity
individualConMatrices = cell(1, 4);
individualProbMatrices = cell(1, 4);
for i = 1:length(clusters)
    % Create a temporary simulator for just this cluster
    tempSim = WirelessSimulator(clusters{i});
    
    % Inject the power matrix for ONLY this cluster
    % (Matches the i-th entry from your Power_Sim results)
    tempSim.StoredSS = individualPowerMatrices{i};
    
    % Run connectivity for just this cluster
    [individualConMatrices{i}, individualProbMatrices{i}] = tempSim.computeConnectivity(modelType, threshold);
    
    % Count and display links for this cluster
    clusterLinks = sum(individualConMatrices{i}(:));
    fprintf('Cluster %d links: %d\n', i, clusterLinks);
end

%% Cluster to Cluster Links
K = 100;
history = zeros(K, 6);
% Calculate indices once (since positions don't change)
numNodes = cellfun(@(c) size(c.Locations, 1), clusters);
endIdx = cumsum(numNodes);
startIdx = [1, endIdx(1:end-1) + 1];

fprintf('Running %d Bernoulli iterations on static nodes...\n', K);

% Iteration Loop
for k = 1:K
    % Run Bernoulli connectivity (uses the SAME power matrix every time)
    % but generates DIFFERENT links based on probability.
    [conn, ~] = sim.computeConnectivity("Bernoulli", threshold);
    
    % Helper to count links between cluster i and cluster j
    calcLinks = @(i, j) sum(sum(conn(startIdx(i):endIdx(i), startIdx(j):endIdx(j))));
    
    % Record the results for this "snapshot" of luck
    history(k, 1) = calcLinks(1, 2); % C1-C2
    history(k, 2) = calcLinks(1, 3); % C1-C3
    history(k, 3) = calcLinks(1, 4); % C1-C4
    history(k, 4) = calcLinks(2, 3); % C2-C3
    history(k, 5) = calcLinks(2, 4); % C2-C4
    history(k, 6) = calcLinks(3, 4); % C3-C4
end

% Plot the trends
figure('Name', 'Discrete Link Analysis');
hold on;

% Define the x-axis (Iteration 1, 2, 3...)
iterations = 1:K;

% Create a stem plot for each column of history
% We use 'MarkerFaceColor' to make the dots solid
s = stem(iterations, history, 'filled', 'LineWidth', 1.2);

% C1-C2 (Red), C1-C3 (Blue), C1-C4 (Green), C2-C3 (Yellow), C2-C4
% (Magenta), C3-C4 (Cyan)
colors = ['r'; 'b'; 'g'; 'y'; 'm'; 'c'];
for i = 1:min(6, size(history,2))
    s(i).Color = colors(i,:);
    s(i).MarkerFaceColor = colors(i,:);
end

grid on;
xlabel('Iteration');
ylabel('Number of Active Inter-Cluster Links');
title(['Link Count per Iteration ( Threshold: ', num2str(threshold), ' dBm)']);

legend({'C1-C2', 'C1-C3', 'C1-C4', 'C2-C3', 'C2-C4', 'C3-C4'}, ...
       'Location', 'northeastoutside');

% Force the X-axis to show every integer iteration
xticks(1:K); 
% Set Y-axis to start at zero
ylim([0 max(history(:)) + 2]);
%% 4. RUN POWER THRESHOLD SWEEP
thresholdRange = -55:2:-5; % Define the range you want to see
sweepCounts = zeros(size(thresholdRange));

fprintf('Performing connectivity sweep...\n');
for i = 1:length(thresholdRange)
    % Using Binary for the sweep gives a clear "upper bound" of possible links
    [tempConn, ~] = sim.computeConnectivity("Binary", thresholdRange(i));
    sweepCounts(i) = sum(tempConn(:));
end

% Plot the results
figure('Name', 'Connectivity Sensitivity');
plot(thresholdRange, sweepCounts, '-b', 'LineWidth', 1.5);
grid on;
xlabel('Power Threshold (dBm)');
ylabel('Total Active Links');
title(['Link Connectivity (Current Threshold: ', num2str(threshold), ' dBm)']);
xline(threshold, '--r', 'Current Threshold'); % Mark your chosen -50 dBm

%% 5. SAVE THE UPDATED RESULTS
fileName = sprintf('ConnectivitySimResults_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));
save(fileName, 'clusters', 'globalPowerMatrix', 'globalConMatrix', ...
    'globalProbabilityMatrix', 'individualPowerMatrices', ... 
    'individualConMatrices', 'individualProbMatrices', '-v7.3');

fprintf('Results saved to %s. Run Visual_Sim.m to see the 3D plot.\n', fileName);