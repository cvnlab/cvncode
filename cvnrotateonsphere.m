function newvals = cvnrotateonsphere(surfdir_or_subject,vals,hemi,sourcesuffix,interptype,refvector,rotdeg)

% function newvals = cvnrotateonsphere(surfdir_or_subject,vals,hemi,sourcesuffix,interptype,refvector,rotdeg)
%
% Randomly rotate data defined on a sphere with respect to <refvector> and then
% interpolate to get a new set of values (back on the original sphere).
%
% This routine is compatible with truncated surfaces, but be careful about
% edge effects and missing data issues.
%
% Inputs:
%   surfdir_or_subject: Either a directory where surfaces are found, or the freesurfer subject ID
%   vals:               Nx1 values on vertices. can have multiple columns.
%   hemi:               'lh' or 'rh'
%   sourcesuffix:       source sphere is <hemi>.sphere<sourcesuffix> 
%                       (ie: '' for lh.sphere, or '.reg' for lh.sphere.reg)
%                         N=#vertices in source surface
%   interptype:         'linear' or 'nearest'
%   refvector:          [X Y Z] coordinates of the reference vector (note: this is in the "raw" space from freesurfer_read_surf_kj.m)
%   rotdeg:             number of degrees of CCW rotation

% define
surftype = 'sphere';

% figure out surfdir
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

% load surface (note that we skip the post-processing of vertices and faces since unnecessary for what we are doing)
clear surf1;
[surf1.vertices,surf1.faces] = freesurfer_read_surf_kj(surf1file);

% prepare coordinates as 4 x V
XYZ = [surf1.vertices ones(size(surf1.vertices,1),1)]';

% figure out rotation matrix to get refvector to the positive z-axis
rotmatrix = xyzrotatetoz(refvector);

% rotate all vertices so that refvector is along z+ axis
XYZ0 = rotmatrix*XYZ;

% rotate around the z+ axis
XYZ0 = xyzrotate_z(rotdeg)*XYZ0;

% undo the first rotation
XYZ0 = inv(rotmatrix)*XYZ0;

% sample data onto the original surface, acting as if the real surface is the rotated one.
if isequal(interptype,'nearest')
  tempix = griddata(XYZ0(1,:)',XYZ0(2,:)',XYZ0(3,:)',(1:size(vals,1))', ...
                    surf1.vertices(:,1),surf1.vertices(:,2),surf1.vertices(:,3),interptype);
  newvals = vals(tempix,:);
else
  newvals = [];
  for zz=1:size(vals,2)
    newvals(:,zz) = griddata(XYZ0(1,:)',XYZ0(2,:)',XYZ0(3,:)',vals(:,zz), ...
                       surf1.vertices(:,1),surf1.vertices(:,2),surf1.vertices(:,3),interptype);
  end
end
