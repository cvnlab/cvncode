function [vertvals,A] = mesh_diffuse_fast(vertvals, faces_or_adjacency, iter)
% [vertvals,A] = mesh_diffuse_fast(vertvals, faces_or_adjacency)
%
% Smooth values on a triangle mesh using iterative neighbor averaging.
% Implemented as a sparse array multiplication for speed.
%
% Inputs:
%   vertvals:           VxT values at each of V vertices in mesh (if empty,
%                       just compute and return sparse diffusion matrix A)
%
%                   OR  1x1 scalar value containing V, the total of verts
%                       in your mesh.  This is only needed if you are just
%                       computing the adjacency matrix and there are
%                       vertices that are NOT contained in any faces.
%
%   faces_or_adjacency: Fx3 faces matrix specifying vertex indices for each
%                       triangular face in the mesh
%                   OR  VxV sparse diffusion matrix (output from previous
%                       call to function)
%
%   iter:               number of times to iterate smoothing (Default=1)
%                       If fractional, use weighted sum of smoothings with
%                       floor(iter) and floor(iter)+1
%
% Outputs:
%   vertvals:           VxT smoothed values
%
%   A:                  sparse VxV neighbor matrix that can multiplied by
%                       VxT data for fast smoothing.  
% 
% Note: Each row in A contains the value 1/(N+1) in columns corresponding to 
%   itself (diagonal) and N vertices that share a face
%   e.g.: If vertex 1 is connected to vertices 7,8,9,10, the first row of
%       A is [ .2 0 0 0 0 0 .2 .2 .2 .2 0 0 0 0 ....]
%
% Examples:
% surfL=cvnreadsurface('C0041','lh','layerA1','DENSETRUNCpt');
% prfdir=sprintf('%s/C0041/PRF_results/mgz',cvnpath('freesurfer'));
% vertvals=load_mgh(sprintf('%s/lh.lh_ang_mean.mgz',prfdir));
% smoothvals=mesh_diffuse_fast(vertvals,surfL.faces,10);
%
% vertvalsB=load_mgh(sprintf('%s/lh.lh_ecc_mean.mgz',prfdir));
% [smoothvals,A]=mesh_diffuse_fast(vertvals,surfL.faces,10);
% smoothvalsB1=A*vertvalsB;
% smoothvalsB10=mesh_diffuse_fast(vertvalsB,A,10);
%
% KJ 2016/02/23
% KJ 2016/04/01 Cast input to double and back for sparse mult

if(~exist('iter','var') || isempty(iter))
    iter=1;
end

numverts=[];
if(numel(vertvals)==1)
    numverts=vertvals;
    vertvals=[];
elseif(numel(vertvals)>1)
    numverts=size(vertvals,1);
end

if(issparse(faces_or_adjacency))
    A=faces_or_adjacency;
else
    
    f = double(faces_or_adjacency);

    A = sparse([f(:,1); f(:,1); f(:,2); f(:,2); f(:,3); f(:,3)], ...
               [f(:,2); f(:,3); f(:,1); f(:,3); f(:,1); f(:,2)], ...
               1.0);

    % avoid double links
    A = double(A>0);


    A=A+speye(size(A));
    sA=sum(A,2);
    sA(sA==0)=1;
    sA=sparse(1:size(A,1),1:size(A,1),1./sA);
    A=sA*A;
    
    if(~isempty(numverts) && (size(A,1)<numverts || size(A,2)<numverts))
        Atmp=A;
        A=speye(numverts,numverts);
        A(1:size(Atmp,1),1:size(Atmp,2))=Atmp;
    end
end

if(isempty(vertvals))
    vertvals=[];
    return;
end

iterfrac=iter-floor(iter);

itertol=1e-4;
if(iterfrac<itertol)
    iter=floor(iter);
elseif(iterfrac<1-itertol)
    iter=ceil(iter);
end

inputclass=class(vertvals);
vertvals=double(vertvals);
for i = 1:floor(iter)
    vertvals=A*vertvals;
end

if(iterfrac>itertol)
    vertvals=(1-iterfrac)*vertvals+iterfrac*(A*vertvals);
end

vertvals=cast(vertvals,inputclass);
