classdef WirelessSimulator < handle
    properties
        Clusters            % Array of Cluster objects
        PropModel = "Longley-rice"
        Frequency = 915e6
        TransmitPower = 1
        RxSensitivity = -100
        ClimateZone = "maritime-over-sea"
        Sigma = 5           
        
        % Data Storage
        StoredSS            % Cached Signal Strength matrix
        Connectivity        % Resulting link matrix
        AllLocations        % Combined [Lat, Lon, Alt] of all clusters
    end
    
    methods
        function obj = WirelessSimulator(clusters)
            obj.Clusters = clusters;
            obj.updateAggregatedLocations();
        end
        
        function updateAggregatedLocations(obj)
            % Combine all Cluster locations into one master matrix
            obj.AllLocations = [];
            for i = 1:length(obj.Clusters)
                obj.AllLocations = [obj.AllLocations; obj.Clusters(i).Locations];
            end
            obj.StoredSS = []; % Clear cache if the fleet layout changes
        end
        
        function ss = runPropagation(obj, forceRecompute)
            if nargin < 2, forceRecompute = false; end
            
            % Return cached data if available to save time
            if ~isempty(obj.StoredSS) && ~forceRecompute
                ss = obj.StoredSS;
                return;
            end
            
            n = size(obj.AllLocations, 1);
            txs = txsite("Latitude", obj.AllLocations(:,1), ...
                         "Longitude", obj.AllLocations(:,2), ...
                         "AntennaHeight", obj.AllLocations(:,3), ...
                         "TransmitterFrequency", obj.Frequency, ...
                         "TransmitterPower", obj.TransmitPower);
                     
            rxs = rxsite("Latitude", obj.AllLocations(:,1), ...
                         "Longitude", obj.AllLocations(:,2), ...
                         "AntennaHeight", obj.AllLocations(:,3), ...
                         "ReceiverSensitivity", obj.RxSensitivity);

            pm = propagationModel(lower(obj.PropModel), "ClimateZone", obj.ClimateZone);
            
            % Execute and cache signal strength
            obj.StoredSS = sigstrength(rxs, txs, pm);
            ss = obj.StoredSS;
        end
        
        function conn = computeConnectivity(obj, modelType, threshold)
            if isempty(obj.StoredSS), obj.runPropagation(); end
            ss = obj.StoredSS;
            
            if modelType == "Binary"
                conn = ss >= threshold;
            elseif modelType == "Bernoulli"
                P_link = 1 ./ (1 + exp(-(ss - threshold) / obj.Sigma));
                conn = rand(size(ss)) < P_link;
            end
            
            conn(logical(eye(size(conn)))) = 0; % Remove self-links
            obj.Connectivity = conn;
        end
        
        function plotNodes(obj)
            figure('Color', 'w'); hold on; grid on;
            lat = obj.AllLocations(:,1);
            lon = obj.AllLocations(:,2);
            [row, col] = find(obj.Connectivity);
            for k = 1:length(row)
                plot([lon(row(k)) lon(col(k))], [lat(row(k)) lat(col(k))], 'r-', 'LineWidth', 0.5);
            end
            scatter(lon, lat, 60, 'filled', 'b');
            title('Node Connectivity Plot');
        end
    end
end