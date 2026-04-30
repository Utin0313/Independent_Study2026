classdef WirelessSimulator < handle
    properties
        Clusters            
        PropModel = "Longley-rice"
        Frequency = 915e6
        TransmitPower = 1
        RxSensitivity = -100
        ClimateZone = "maritime-over-sea"
        Sigma = 5           
        
        StoredSS
        storedSSbySites
        Connectivity
        ProbabilityMatrix
        AllLocations        
    end
    
    methods
        function obj = WirelessSimulator(clusters)
            obj.Clusters = clusters;
            obj.updateLocations();
        end
        
        function updateLocations(obj)
            totalNodes = 0; 
            for i = 1:length(obj.Clusters)
                c = obj.Clusters(i); 
                n = size(c.Locations, 1); 
                totalNodes = totalNodes + n; 
            end 

            obj.AllLocations = zeros(totalNodes, 3);
            
            lastIdx = 0;
            for i = 1:length(obj.Clusters)
                numNodes = size(obj.Clusters(i).Locations, 1);
                obj.AllLocations(lastIdx + 1 : lastIdx + numNodes, :) = obj.Clusters(i).Locations;
                lastIdx = lastIdx + numNodes;
            end
            obj.StoredSS = []; 
        end

        function ss = runPropagation(obj, forceRecompute)
            if nargin < 2 
                forceRecompute = false;
            end
            if ~isempty(obj.StoredSS) && ~forceRecompute
                ss = obj.StoredSS;
                return;
            end
            
            % -- Debug -- 
            lat = obj.AllLocations(:,1); 
            lon = obj.AllLocations(:,2); 

            disp(['Lat size: ', num2str(length(lat))])
            disp(['Lon size: ', num2str(length(lon))])
            
            if size(obj.AllLocations,1) < 1
                error("AllLocations is empty. Cluster generation failed.")
            end
            
            txs = txsite("Latitude", obj.AllLocations(:,1).', ...
                         "Longitude", obj.AllLocations(:,2).', ...
                         "AntennaHeight", obj.AllLocations(:,3).', ...
                         "TransmitterFrequency", obj.Frequency, ...
                         "TransmitterPower", obj.TransmitPower);

            rxs = rxsite("Latitude", obj.AllLocations(:,1).', ...
                         "Longitude", obj.AllLocations(:,2).', ...
                         "AntennaHeight", obj.AllLocations(:,3).', ...
                         "ReceiverSensitivity", obj.RxSensitivity);

            pm = propagationModel(lower(obj.PropModel), "ClimateZone", obj.ClimateZone);
            
            obj.StoredSS = sigstrength(rxs, txs, pm);
            ss = obj.StoredSS;
            
            obj.storedSSbySites = cell(1, size(ss, 2)); 
            for i = 1:size(ss, 2)
                cols = ss(:, i); 
                cols(i) = [];
                obj.storedSSbySites{i} = cols;
            end 

        end
       

        function [conn, P_link] = computeConnectivity(obj, modelType, threshold)
            if isempty(obj.StoredSS)
                obj.runPropagation();
            end
            ss = obj.StoredSS;
            
            if modelType == "Binary"
                P_link = double(ss >= threshold);
                conn = logical(P_link);
            elseif modelType == "Bernoulli"
                % Calculate the odds before the coin flip
                P_link = 1 ./ (1 + exp(-(ss - threshold) / obj.Sigma));
                conn = rand(size(ss)) < P_link;
            end
            
            conn(logical(eye(size(conn)))) = 0; 
            obj.ProbabilityMatrix = P_link;
            obj.Connectivity = conn;
        end
    end
end