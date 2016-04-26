function neidist = vertex_neighbor_distance(vertices,faces,metric)
%neidist = vertex_neighbor_distance(vertices,faces,metric)
%
%For each vertex, compute mean of the distances to its neighboring vertices
%
%Inputs:
%vertices: [Nx3] x,y,z coordinates for each of N vertices
%faces: [Fx3] the indices of the 3 vertices that make up each of F faces
%metric: {'mean','min','max'} specify which metric to return (default: 'mean')
%   If metric='min', compute the distance to it's NEAREST neigboring vertex
%   If metric='max', compute the distance to it's FURTHEST neigboring vertex
%
%Ouputs:
%neidist: [Nx1] distance to neighbors for vertex
%
%Note: requires mex function vertex_distance_double.  If not available, 
% cd to this folder in matlab and type 'mex vertex_distance_double.c'

if(~exist('metric','var') || isempty(metric))
    metric='mean';
end


switch(metric)
    case 'max'
        metric=1;
    case 'min'
        metric=2;
    case 'mean'
        metric=0;
end

if(~isa(vertices,'double'))
    vertices=double(vertices);
end
if(~isa(faces,'double'))
    faces=double(faces);
end
neidist=vertex_distance_double(faces(:,1),faces(:,2),faces(:,3),vertices(:,1),vertices(:,2),vertices(:,3),metric);
