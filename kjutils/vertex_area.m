function A=vertex_area(vertices,faces)
%A = vertex_area(vertices,faces)
%
%For each vertex, compute mean of the areas of all triangular faces
%   containing this vertex (aka: average surface area per vertex ASAPV)
%
%Inputs:
%vertices: [Nx3] x,y,z coordinates for each of N vertices
%faces: [Fx3] the indices of the 3 vertices that make up each of F faces
%
%Ouputs:
%A: [Nx1] average surface area per vertex
%
%Note: requires mex function vertex_area_double.  If not available, 
% cd to this folder in matlab and type 'mex vertex_area_double.c'


if(~isa(vertices,'double'))
    vertices=double(vertices);
end
if(~isa(faces,'double'))
    faces=double(faces);
end

A=vertex_area_double(faces(:,1),faces(:,2),faces(:,3),vertices(:,1),vertices(:,2),vertices(:,3));
