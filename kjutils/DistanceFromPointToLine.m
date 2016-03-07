function distance = DistanceFromPointToLine(points, linept1, linept2)
%distance = DistanceFromPointToLine(points, linept1, linept2)
% points = Nx3 matrix of points to evaluate
% linept1,linept2 = 1x3 points on the line

    numpt = size(points,1);
    
    q_vec = linept2-linept1;
    q_mag = norm(q_vec);

    v1 = repmat(q_vec,numpt,1);
    v2 = points - repmat(linept1,numpt,1);
    
    distance = sqrt(sum(cross(v1,v2,2).^2,2))/q_mag;
