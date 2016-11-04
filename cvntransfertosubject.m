function f = cvntransfertosubject(sourcesubject,destsubject,vals,hemi,interptype,sourcesuffix,destsuffix)

% function f = cvntransfertosubject(subjectid,vals,hemi,interptype,surftype)
%
% <sourcesubject> is like 'C0041'
% <destsubject> is like 'CVNS005' or 'fsaverage'
% <vals> is a column vector of values defined on the regular sphere surface (one hemi)
% <hemi> is 'lh' or 'rh'
% <interptype> is 'linear' or 'nearest'
% <sourcesuffix> is 'orig|DENSE|DENSETRUNCpt'
% <destsuffix> is 'orig|DENSE|DENSETRUNCpt'
%
% Use freesurfer sphere.reg to transfer values from one subject to another
% (eg: transfer from one subject to fsaverage)
%
% Hm: only 'nearest' works.

if(~exist('sourcesuffix','var'))
    sourcesuffix='DENSE';
end

if(~exist('destsuffix','var'))
    destsuffix='DENSE';
end

if(isequal(sourcesuffix,'orig'))
    sourcesuffix='';
end

if(isequal(destsuffix,'orig'))
    destsuffix='';
end

if(~exist('interptype','var') || isempty(interptype))
    interptype='nearest';
end

fsdirFROM = sprintf('%s/%s',cvnpath('freesurfer'),sourcesubject);
fsdirTO = sprintf('%s/%s',cvnpath('freesurfer'),destsubject);

% calc
surf1file = sprintf('%s/surf/%s.sphere.reg%s',     fsdirFROM,hemi,sourcesuffix);
surf2file = sprintf('%s/surf/%s.sphere.reg%s',fsdirTO,hemi,destsuffix);

% load surfaces (note that we skip the post-processing of vertices and faces since unnecessary for what we are doing)
clear surf1;
[surf1.vertices,surf1.faces] = freesurfer_read_surf_kj(surf1file);
clear surf2;
[surf2.vertices,surf2.faces] = freesurfer_read_surf_kj(surf2file);

% do it
f = griddata(surf1.vertices(:,1),surf1.vertices(:,2),surf1.vertices(:,3),vflatten(vals), ...
             surf2.vertices(:,1),surf2.vertices(:,2),surf2.vertices(:,3),interptype);

