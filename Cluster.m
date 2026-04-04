classdef Cluster
    properties
        CentralizedLat        % Latitude of the ship
        CentralizedLon        % Longitude of the ship
        CentralizedHeight       % Height of the ship
        NumDrones        % Number of drones in this cluster
        XBoundary        % [min, max] spread of drones in the x
        YBoundary        % [min, max] spread of drones in the y
        HeightRange      % [min, max] drone altitude
        IncludeShip = true % If you want to add drones without the ships
        Locations        % Resulting N x 3 matrix [Lat, Lon, Alt]
    end
    
    methods
        function obj = DroneCluster(lat, lon, shipH, nDrones, xBound, yBound, hRange)
            obj.CentralizedLat = lat;
            obj.CentralizedLon = lon;
            obj.CentralizedHeight = shipH;
            obj.NumDrones = nDrones;
            obj.XBoundary = xBound;
            obj.YBoundary = yBound;
            obj.HeightRange = hRange;
            if nargin > 7, obj.IncludeShip = incShip; end
            obj = obj.generateLocations();
        end
        
        function obj = generateLocations(obj)
            % Generate drone offsets
            latOffset = (rand(obj.NumDrones, 1) - 0.5) * obj.YBoundary;
            lonOffset = (rand(obj.NumDrones, 1) - 0.5) * obj.XBoundary;
            
            % Random drone heights
            droneHeights = obj.HeightRange(1) + ...
                (obj.HeightRange(2) - obj.HeightRange(1)) * rand(obj.NumDrones, 1);
            
            % Combine Ship (only if we want ships) + Drones for location
            drones = [obj.CentralizedLat + latOffset, obj.CentralizedLon + lonOffset, droneHeights];
            
            if obj.IncludeShip
                % Add ship at row 1
                obj.Locations = [obj.CentralizedLat, obj.CentralizedLon, obj.CentralizedHeight; drones];
            else
                % Drones only
                obj.Locations = drones;
            end
        end
    end
end