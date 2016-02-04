function f = cvntransfertodense(subjectid,vals,hemi,interptype,surftype)

% function f = cvntransfertodense(subjectid,vals,hemi,interptype,surftype)
%
% <subjectid> is like 'C0041'
% <vals> is a column vector of values defined on the regular sphere surface (one hemi)
% <hemi> is 'lh' or 'rh'
% <interptype> is 'linear' or 'nearest'
% <surftype> is 'sphere' (default),'inflated',etc...
%
% Interpolate to obtain <vals> defined on the dense sphere surface.
%
% Hm: only 'nearest' works.

if(~exist('surftype','var') || isempty('surftype'))
    surftype='sphere';
end

% calc
surf1file = sprintf('/software/freesurfer/subjects/%s/surf/%s.%s',subjectid,hemi,surftype);
surf2file = sprintf('/software/freesurfer/subjects/%s/surf/%s.%sDENSE',subjectid,hemi,surftype);

% load surfaces (note that we skip the post-processing of vertices and faces since unnecessary for what we are doing)
clear surf1;
[surf1.vertices,surf1.faces] = freesurfer_read_surf_kj(surf1file);
clear surf2;
[surf2.vertices,surf2.faces] = freesurfer_read_surf_kj(surf2file);

% do it
f = griddata(surf1.vertices(:,1),surf1.vertices(:,2),surf1.vertices(:,3),vflatten(vals), ...
             surf2.vertices(:,1),surf2.vertices(:,2),surf2.vertices(:,3),interptype);
