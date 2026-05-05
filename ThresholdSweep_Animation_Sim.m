clc; clear; close all;

%% 1. LOAD THE SIGNAL POWER DATA
% Automatically find the most recent simulation file
fileInfo = dir('ConnectivitySimResults_20260426_192457.mat');
if isempty(fileInfo)
    error('No PowerSimResults file found. Run Power_Sim.m first.');
end
[~, idx] = max([fileInfo.datenum]); 
latestFile = fileInfo(idx).name;
fprintf('Loading power matrix for animation from: %s\n', latestFile);
load(latestFile); 

%% 2. INITIALIZE SIMULATOR
% Reconstruct the simulator using the saved clusters
allClusters = [clusters{:}];
sim = WirelessSimulator(allClusters);

% Inject the saved power matrix back into the object
sim.StoredSS = globalPowerMatrix; 

% Get all node locations for easy plotting
allLocs = sim.AllLocations;

%% 3. VIDEO SETUP
videoFilename = 'ConnectivityThresholdSweep.mp4';
v = VideoWriter(videoFilename, 'MPEG-4');
v.FrameRate = 8; % Adjust frame rate (frames per second) for speed
open(v);

fprintf('Video file initialized. Starting animation generation...\n');

%% 4. SET UP THE 3D FIGURE
% Make the figure large and white for a clean video
fig = figure('Color', 'w', 'Name', 'Connectivity Sweep Animation', 'Position', [100, 100, 900, 700]);
hold on; grid on;

colors = ['r'; 'b'; 'g'; 'y'];
labels = {'Ship 1 + Drones (C1)', 'Ship 2 + Drones (C2)', 'Overhead 1 (C3)', 'Overhead 2 (C4)'};

% Plot the static nodes first
for i = 1:length(clusters)
    locs = clusters{i}.Locations;
    scatter3(locs(:,2), locs(:,1), locs(:,3), 60, colors(i,:), 'filled', ...
             'MarkerEdgeColor', 'k', 'DisplayName', labels{i});
end

xlabel('Longitude (deg)'); ylabel('Latitude (deg)'); zlabel('Altitude (m)');
legend('Location', 'northeastoutside');
view(3); % Set 3D perspective
axis tight; 
% Freeze the axis limits so the camera doesn't jump around during the video
xlim(xlim); ylim(ylim); zlim(zlim);

% Create an empty line plot object for the links
% We will continuously update this object's data inside the loop
linkPlot = plot3(NaN, NaN, NaN, 'Color', [0.7 0.7 0.7 0.4], ...
                 'LineWidth', 0.5, 'DisplayName', 'Active Links');

%% 5. RUN THE SWEEP AND RECORD FRAMES
thresholds = -55:1:-5; 

for i = 1:length(thresholds)
    currentThresh = thresholds(i);
    
    % Compute connectivity (using "Binary" to show exactly what connects)
    [conn, ~] = sim.computeConnectivity("Binary", currentThresh);
    
    % Find active links
    [txRow, rxCol] = find(conn);
    numLinks = length(txRow);
    
    if numLinks > 0
        % Prepare coordinates using the "NaN separation" trick
        allX = [allLocs(txRow, 2), allLocs(rxCol, 2), NaN(numLinks,1)]';
        allY = [allLocs(txRow, 1), allLocs(rxCol, 1), NaN(numLinks,1)]';
        allZ = [allLocs(txRow, 3), allLocs(rxCol, 3), NaN(numLinks,1)]';
        
        % Update the existing plot line data
        set(linkPlot, 'XData', allX(:), 'YData', allY(:), 'ZData', allZ(:));
    else
        % Clear the links if none are active
        set(linkPlot, 'XData', NaN, 'YData', NaN, 'ZData', NaN);
    end
    
    % Update the Title dynamically
    title(sprintf('Connectivity Threshold Sweep | Threshold: %d dBm | Active Links: %d', currentThresh, numLinks), ...
          'FontSize', 14);
    
    % Force MATLAB to draw the graphics immediately
    drawnow; 
    
    % Capture the frame from the figure and write it to the video file
    frame = getframe(fig);
    writeVideo(v, frame);
    
    % Optional: print progress to console
    if mod(i, 10) == 0
        fprintf('Processed threshold %d dBm...\n', currentThresh);
    end
end

%% 6. FINALIZE
close(v); % Close the video file to save it safely
fprintf('Video successfully saved as: %s\n', videoFilename);