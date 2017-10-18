function f = cvntransfersphere(surfdir_or_subject,vals,hemi,sourcesuffix,destsuffix,interptype,surftype)
% newvals = cvntransfersphere(surfdir_or_subject,vals,hemi,sourcesuffix,destsuffix,interptype,surftype)
% Interpolate to obtain <vals> defined on the new sphere surface.
%
% Inputs:
%   surfdir_or_subject: Either a directory where surfaces are found, or the freesurfer subject ID
%   hemi:               'lh' or 'rh'
%   vals:               Nx1 values on source vertices (if empty, use vals=1:N) to generate lookup index
%   sourcesuffix:       source sphere is <hemi>.sphere<sourcesuffix> 
%                       (ie: '' for lh.sphere, or '.reg' for lh.sphere.reg)
%                         N=#vertices in source surface
%   destsuffix:         destination sphere is <hemi>.sphere<destsuffix> 
%                       (ie: '' for lh.sphere, or '.reg' for lh.sphere.reg)
%   interptype:         'linear' or 'nearest'
%   surftype:           'sphere' (default), 'inflated' etc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(~exist('surftype','var') || isempty(surftype))
    surftype='sphere';
end

surfdir=[];
if(ischar(surfdir_or_subject) && sum(surfdir_or_subject=='/' | surfdir_or_subject=='\')==0)
    freesurfdir=cvnpath('freesurfer');
    surfdir=sprintf('%s/%s/surf',freesurfdir,surfdir_or_subject);
elseif(exist(surfdir_or_subject,'dir'))
    surfdir=surfdir_or_subject;
end
assert(exist(surfdir,'dir')>0);


% calc
surf1file = sprintf('%s/%s.%s%s',surfdir,hemi,surftype,sourcesuffix);
surf2file = sprintf('%s/%s.%s%s',surfdir,hemi,surftype,destsuffix);

% load surfaces (note that we skip the post-processing of vertices and faces since unnecessary for what we are doing)
clear surf1;
[surf1.vertices,surf1.faces] = freesurfer_read_surf_kj(surf1file);
clear surf2;
[surf2.vertices,surf2.faces] = freesurfer_read_surf_kj(surf2file);

if(isempty(vals))
    vals=1:size(surf1.vertices,1);
end

% do it
f = griddata(surf1.vertices(:,1),surf1.vertices(:,2),surf1.vertices(:,3),vflatten(vals), ...
             surf2.vertices(:,1),surf2.vertices(:,2),surf2.vertices(:,3),interptype);
