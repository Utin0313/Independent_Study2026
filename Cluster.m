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
            
            baseZ = obj.HeightRange(1); 

            points = zeros(N,3); 
            count = 0;
            while count < N
                dx = (rand - 0.5) * 2*r;
                dy = (rand - 0.5) * 2*r;
                dz = abs((rand - 0.5) * 2*r);
             
                if dx*dx + dy*dy + dz*dz <= r*r

                    x = cx + dx; 
                    y = cy + dy;
                    z = baseZ + dz; 

                    count = count + 1; 
                    points(count, :) = [x, y, z]; 
    
                end
            end   
            obj.Locations = [points(:,1) ./ constant, points(:,2) ./ constant, points(:,3)];
        end
            
        function generateDomeSliceLocations(obj)
            N  = obj.ClusterSize;
            
            constant = 111139; 
            cx = obj.CentralizedLat * constant; 
            cy = obj.CentralizedLon * constant;

            r = obj.HeightRange(2) - obj.HeightRange(1);
            epilson = r * 0.05; 
            
            zmin = obj.HeightRange(1); 
            zmax = obj.HeightRange(2); 

            points = zeros(N,3); 
            count = 0;
            while count < N
                x = cx + (rand - 0.5) * 2*r;
                y = cy + (rand - 0.5) * 2*r;
                z = zmin + rand*(zmax - zmin);
                
                dx = cx -x; 
                dy = cy - y; 
                dz = 0; 

                inside = dx*dx + dy*dy + dz*dz <= r*r;
                mask = abs(y - cy) < epilson;  
                if inside && mask 
                   count = count + 1; 
                   points(count, :) = [x, y, z]; 
                end
            end 
            obj.Locations = [points(:,1) ./ constant, points(:,2) ./ constant, points(:,3)];
        end 
    end 
end