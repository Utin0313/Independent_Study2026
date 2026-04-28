clc; clear; close all;

% Automatically find the most recent simulation file
fileInfo = dir('PowerSimResults_20260428_014249.mat');
if isempty(fileInfo)
    error('No saved data file found. Please run the simulation (TEST10) first.');
end
[~, idx] = max([fileInfo.datenum]); 
latestFile = fileInfo(idx).name;
fprintf('Loading data from: %s\n', latestFile);
load(latestFile); 

% --- Setup Shared Plotting Variables ---
colors = ['r'; 'b' ; 'g'; 'y']; % Red, Blue, Green, Yellow
labels = {'Ship 1 + Drones (C1)', 'Ship 2 + Drones (C2)', 'Overhead 1 (C3)', 'Overhead 2 (C4)'};

%% 2. FIGURE 1: 3D NODE LOCATIONS (NO LINKS)
figure('Color', 'w', 'Name', 'Node Locations');
hold on; grid on;

for i = 1:length(clusters)
    locs = clusters{i}.Locations;
    scatter3(locs(:,2), locs(:,1), locs(:,3), 60, colors(i,:), 'filled', ...
             'MarkerEdgeColor', 'k', 'DisplayName', labels{i});
end

xlabel('Longitude (deg)'); ylabel('Latitude (deg)'); zlabel('Altitude (m)');
title('3D Node Locations (Cluster Visualization)');
legend('Location', 'northeastoutside');
view(3); axis tight;

%% 3. FIGURE 2: 3D NETWORK TOPOLOGY (WITH LINKS)
figure('Color', 'w', 'Name', 'Network Connectivity');
hold on; grid on;

% 1. Reconstruct the global coordinate list
allLocs = [];
for i = 1:length(clusters)
    locs = clusters{i}.Locations;
    allLocs = [allLocs; locs]; 
    
    % Plot the nodes again in this second figure
    scatter3(locs(:,2), locs(:,1), locs(:,3), 60, colors(i,:), 'filled', ...
             'MarkerEdgeColor', 'k', 'DisplayName', labels{i});
end

% 2. Plot the Wireless Links ONLY if they exist in the saved file
if exist('globalConMatrix', 'var') && ~isempty(globalConMatrix)
    [txIdx, rxIdx] = find(globalConMatrix); 

    if ~isempty(txIdx)
        % Prepare coordinates: [Start; End; NaN] for every link
        allX = [allLocs(txIdx, 2), allLocs(rxIdx, 2), NaN(length(txIdx),1)]';
        allY = [allLocs(txIdx, 1), allLocs(rxIdx, 1), NaN(length(txIdx),1)]';
        allZ = [allLocs(txIdx, 3), allLocs(rxIdx, 3), NaN(length(txIdx),1)]';

        % Plot all links as ONE object
        plot3(allX(:), allY(:), allZ(:), ...
              'Color', [0.7 0.7 0.7 0.3], ... 
              'LineWidth', 0.5, ...
              'DisplayName', 'Active Links'); 
    end
else
    % If no links are found, add a text warning to the plot so you know why it's empty
    text(allLocs(1,2), allLocs(1,1), allLocs(1,3), '  No Connectivity Data Found', 'Color', 'r');
    fprintf('Note: No globalConMatrix found. Run your Connectivity script to generate links.\n');
end

% Calculate link count for the title
if exist('globalConMatrix', 'var')
    numLinks = sum(globalConMatrix(:));
else
    numLinks = 0;
end

xlabel('Longitude (deg)'); ylabel('Latitude (deg)'); zlabel('Altitude (m)');
title(['3D Wireless Connectivity Map (Active Links: ', num2str(numLinks), ')']);
legend('Location', 'northeastoutside');
view(3); axis tight;


%% CDF Plot 
figure;
hold on
for i = 1:size(globalPowerMatrix, 2)
    cdfplot(globalSSbySite{i})
    labels{i} = (sprintf("Site %d", i));
end 

hold off
title("CDF of individual Site")
xlabel("dBm")
legend(labels)