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
            x = (rand(obj.ClusterSize, 1) - 0.5) * obj.YBoundary;   % YBoudary, XBoundary (e.g.,0.001,0.002,etc.) = 0.001degree * 111139degree/m = 111.139m  
            y = (rand(obj.ClusterSize, 1) - 0.5) * obj.XBoundary;
            z = obj.HeightRange(1) + (obj.HeightRange(2) - obj.HeightRange(1)) * rand(obj.ClusterSize, 1);

            ClusterLocation = [obj.CentralizedLat + x, obj.CentralizedLon + y, z]; 
            obj.Locations = ClusterLocation;
        end 
    end

    methods (Access = private)
        function generateDomeLocations(obj)
            N = obj.ClusterSize;

            constant = 111139;
            cx = obj.CentralizedLat * constant; 
            cy = obj.CentralizedLon * constant;
            r = (obj.HeightRange(2) - obj.HeightRange(1));  % Convert to degree
            
            x = cx + (rand(N, 1) - 0.5) * 2*r;
            y = cy + (rand(N, 1) - 0.5) * 2*r;
            z = obj.HeightRange(1) + (obj.HeightRange(2) - obj.HeightRange(1)).*rand(N,1); 
            
            inside = (cx - x).^2 + (cy - y).^2 + (obj.HeightRange(1) - z).^2 <= r.^2;

            lat = x(inside) ./ constant; 
            lon = y(inside) ./ constant; 
            height = z(inside);
            obj.Locations = [lat, lon, height]; 
            obj.ClusterSize = size(obj.Locations, 1);
        end
            
        function generateDomeSliceLocations(obj)
            N  = obj.ClusterSize;
            
            constant = 111139; 
            cx = obj.CentralizedLat * constant; 
            cy = obj.CentralizedLon * constant;
            r = obj.HeightRange(2) - obj.HeightRange(1);
            epilson = (obj.HeightRange(2) - obj.HeightRange(1)) * 0.05; 

            x = cx + (rand(N, 1) - 0.5) * 2 * r;
            y = ones(N, 1) .* cy;
            z = obj.HeightRange(1) + (obj.HeightRange(2) - obj.HeightRange(1)).*rand(N,1); 
            
            mask = abs(y - cy) < epilson;  
            inside = (cx - x).^2 + (cy - y).^2 + (obj.HeightRange(1) - z).^2 <= r.^2; 
            isInside = inside & mask; 
            
            lat = x(isInside) ./ constant; 
            lon = y(isInside) ./ constant; 
            height = z(isInside);

            obj.Locations = [lat, lon, height]; 
            obj.ClusterSize = size(obj.Locations, 1);
        end 
    end 
end