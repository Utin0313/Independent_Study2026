clear classes; clear; clc;

% -- PARAMETERS -- 
deg_per_m = 1/111139; 

% Converting distance in METER to DEGREE for ship and drone cluster spacing
d1_m = 1000; d2_m = 0;
d1_deg = d1_m * deg_per_m; 
d2_deg = d2_m * deg_per_m;

lat_c1 = 42.32054; lon_c1 = -70.95181;
lat_c2 = lat_c1 + d1_deg; lon_c2 = lon_c1 + d2_deg;         

% CLUSTER BOUNDARY
low_altitude_bounds = [20, 20];    % Height Boundary for nodes by the ship
high_altitude_bounds = [100, 120]; % Height Boundary for drone nodes

% Adjust the Cluster Boundary
% Cluster 1; Cluster 2; Cluster 3; Cluster 4;
C1_x = 20; C2_x = 20; C3_x = 100; C4_x = 50;
C1_y = 20; C2_y = 20; C3_y = 50; C4_y = 100;

% Converting boundary in METER to DEGREE
bound_x_deg_c1 = C1_x * deg_per_m; bound_y_deg_c1 = C1_y * deg_per_m;
bound_x_deg_c2 = C2_x * deg_per_m; bound_y_deg_c2 = C2_y * deg_per_m;
bound_x_deg_c3 = C3_x * deg_per_m; bound_y_deg_c3 = C3_y * deg_per_m;
bound_x_deg_c4 = C4_x * deg_per_m; bound_y_deg_c4 = C4_y * deg_per_m;

% CLUSTER CREATION
C1 = Cluster(lat_c1, lon_c1, 10, bound_x_deg_c1, bound_y_deg_c1, low_altitude_bounds);
C2 = Cluster(lat_c2, lon_c2, 10, bound_x_deg_c2, bound_y_deg_c2, low_altitude_bounds);
C3 = Cluster(lat_c1, lon_c1, 20, bound_x_deg_c3, bound_y_deg_c3, high_altitude_bounds);
C4 = Cluster(lat_c2, lon_c2, 20, bound_x_deg_c4, bound_y_deg_c4, high_altitude_bounds);

% SIMULATE SIGNAL STRENGTH 
clusters = {C1, C2, C3, C4};
allClusters = [clusters{:}]; % Extra all clusters from the cell array to combine all clusters

% Global Simulation
globalSim = WirelessSimulator(allClusters);
globalSim.PropModel = "Longley-rice"; 
globalPowerMatrix = globalSim.runPropagation();

% StoredSSBySite 
globalSSbySite = globalSim.storedSSbySites; 

% Individual Cluster Simulations
individualPowerMatrices = cell(1, 4);
for i = 1:4
    sim = WirelessSimulator(clusters{i});
    sim.PropModel = "Longley-rice";
    individualPowerMatrices{i} = sim.runPropagation();
end

disp('Global and Individual power simulations complete.');

% -- Save File -- 
fileName = sprintf('PowerSimResults_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));
save(fileName, 'clusters', 'individualPowerMatrices', 'globalPowerMatrix', "globalSSbySite", '-v7.3');
disp(['Successfully saved power data to: ', fileName]);