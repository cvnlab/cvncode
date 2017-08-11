function [faces, patchmask] = cleanflatpatch(faces,vertices)
% [faces, patchmask] = cleanflatpatch(faces,vertices)
%
% Detect outlier vertices in a flat triangle mesh (outside 2D polygon loop)
% and remove faces that contain bad vertices
% 
% Inputs
%   faces: Fx3 vertex indices defining patch faces
%   vertices: Nx3 x,y,z (Note: z is not used, assuemed to be = 0)
%
% Ouputs
%   faces: (<=F)x3 vertex indices with some faces possibly removed
%   patchmask: Nx1 boolean = true for each vertex in the cleaned patch

% Iterate a few times in case vertex pruning changes face selection
% In practice, this doesn't seem to require more than 3-4 iterations max
for i = 1:10
    patchmask=false(size(vertices,1),1);
    patchmask(unique(faces(:)))=true;
    
    nF=size(faces,1);
    nP=sum(patchmask);
    
    edgeloop=patchedgeloop(faces,true); %only return longest loop (if multiple exist)
    
    inp=false(size(patchmask));
    inp(patchmask)=inpoly(vertices(patchmask,1:2),vertices(edgeloop,1:2));
    
    patchmask = patchmask & inp;
    
    faces=faces(sum(patchmask(faces),2)==3,:);
    
    if(size(faces,1)==nF && sum(patchmask)==nP)
        break;
    end
end

if(nargout>1)
    patchmask=false(size(vertices,1),1);
    patchmask(unique(faces(:)))=true;
end