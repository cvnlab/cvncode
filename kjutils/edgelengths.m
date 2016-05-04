function [L edges] = edgelengths(faces,verts)

if(size(faces,2) == 2)
    ed = faces;
elseif(size(faces,2) == 3)
    ed = [faces(:,[1 2]); faces(:,[2 3]); faces(:,[1 3])];
elseif(size(faces,2) == 4)
    ed = [faces(:,[1 2]); faces(:,[2 3]); faces(:,[1 3]); ...
        faces(:,[1 4]); faces(:,[2 4]); faces(:,[3 4]);];
end

L = sqrt(sum((verts(ed(:,1),:) - verts(ed(:,2),:)).^2,2));

if(nargout > 1)
    edges = ed;
end