classdef Cluster < handle
    properties
        CentralizedLat        
        CentralizedLon              
        ClusterSize     
        XBoundary      % X sizing (Longitude spread)
        YBoundary      % Y sizing (Latitude spread)
        HeightRange    % Z sizing [MinHeight, MaxHeight]
        Locations        
    end
    
    methods (Access = public)
        function obj = Cluster(lat, lon, nodes, xBound, yBound, zBounds, mode)
            obj.CentralizedLat = lat;
            obj.CentralizedLon = lon;
            obj.ClusterSize = nodes;
            obj.XBoundary = xBound;
            obj.YBoundary = yBound;
            obj.HeightRange = zBounds;

            if nargin <7
                mode = "box"; 
            end

            if mode == "box"
                obj.generateLocations();
            elseif mode == "dome"
                obj.generateDomeLocations(); 
            elseif mode == "slice"
                obj.generateDomeSliceLocations();
            end 
        end
        
        function generateLocations(obj)
            latOffset = (rand(obj.ClusterSize, 1) - 0.5) * obj.YBoundary;   % YBoudary, XBoundary (e.g.,0.001,0.002,etc.) = 0.001degree * 111139degree/m = 111.139m  
            lonOffset = (rand(obj.ClusterSize, 1) - 0.5) * obj.XBoundary;
            RandomHeights = obj.HeightRange(1) + (obj.HeightRange(2) - obj.HeightRange(1)) * rand(obj.ClusterSize, 1);

            ClusterLocation = [obj.CentralizedLat + latOffset, obj.CentralizedLon + lonOffset, RandomHeights]; 
            obj.Locations = ClusterLocation;
        end 
    end

    methods (Access = private)
        function generateDomeLocations(obj)
            constant = 111139; 
            N = obj.ClusterSize; 
            radius = (obj.HeightRange(2) - obj.HeightRange(1)) / constant; % Convert to degree
            centralizedLat = obj.CentralizedLat; 
            centralizedLon = obj.CentralizedLon;
            
            latOffset = centralizedLat + (rand(N, 1) - 0.5) * 2 * radius;
            lonOffset = centralizedLon + (rand(N, 1) - 0.5) * 2 * radius;
            HeightOffSet = obj.HeightRange(1) + (obj.HeightRange(2) - obj.HeightRange(1)).*rand(N,1); 
            
            inside = (centralizedLat - latOffset).^2 + (centralizedLon - lonOffset).^2 + (obj.HeightRange(1) - HeightOffSet).^2 <= radius.^2;
            obj.Locations = [latOffset(inside), lonOffset(inside), HeightOffSet(inside)]; % Convert back to lat and lon (unit:degree) by ./111139
            obj.ClusterSize = size(obj.Locations, 1);
        end
            
        function generateDomeSliceLocations(obj)
            constant = 111139; 
            N  = obj.ClusterSize; 
            radius = obj.HeightRange(2) - obj.HeightRange(1); 
            epilson = (obj.HeightRange(2) - obj.HeightRange(1)) * 0.05; 
            centralizedLat = obj.CentralizedLat * constant; 
            centralizedLon = obj.CentralizedLon * constant;

            latOffset = centralizedLat + (rand(N, 1) - 0.5) * 2 * radius;
            lonOffset = ones(N, 1) .* centralizedLon;
            HeightOffSet = obj.HeightRange(1) + (obj.HeightRange(2) - obj.HeightRange(1)).*rand(N,1); 
            
            sliceMask = abs(lonOffset - centralizedLon) < epilson;  
            inside = (centralizedLat - latOffset).^2 + (centralizedLon - lonOffset).^2 + (obj.HeightRange(1) - HeightOffSet).^2 <= radius.^2; 
            isInside = inside & sliceMask; 
            obj.Locations = [latOffset(isInside) ./ constant, lonOffset(isInside) ./ constant, HeightOffSet(isInside)];
            obj.ClusterSize = size(obj.Locations, 1);
        end 
    end 
end