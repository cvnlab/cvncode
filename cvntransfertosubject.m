function f = cvntransfertosubject(sourcesubject,destsubject,vals,hemi,interptype,sourcesuffix,destsuffix)

% function f = cvntransfertosubject(sourcesubject,destsubject,vals,hemi,interptype,sourcesuffix,destsuffix)
%
% <sourcesubject> is like 'C0041' (or directory where surfaces are found)
% <destsubject> is like 'CVNS005' or 'fsaverage' (or directory where surfaces are found)
% <vals> is a column vector of values defined on the regular sphere surface (one hemi).
%   can have multiple cases as separate columns.  also, can be a row vector of indices
%   into the regular sphere surface. (in this case we ignore <interptype> and just do nearest)
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

%%%

% NEW WAY:
fsdirFROM=[];
if(ischar(sourcesubject) && sum(sourcesubject=='/' | sourcesubject=='\')==0)
    fsdirFROM=sprintf('%s/%s/surf',cvnpath('freesurfer'),sourcesubject);
elseif(exist(sourcesubject,'dir'))
    fsdirFROM=sourcesubject;
end
assert(exist(fsdirFROM,'dir')>0);

fsdirTO=[];
if(ischar(destsubject) && sum(destsubject=='/' | destsubject=='\')==0)
    fsdirTO=sprintf('%s/%s/surf',cvnpath('freesurfer'),destsubject);
elseif(exist(destsubject,'dir'))
    fsdirTO=destsubject;
end
assert(exist(fsdirTO,'dir')>0);

% OLD WAY:
% fsdirFROM = sprintf('%s/%s',cvnpath('freesurfer'),sourcesubject);
% fsdirTO = sprintf('%s/%s',cvnpath('freesurfer'),destsubject);

%%%

% calc
surf1file = sprintf('%s/%s.sphere.reg%s',fsdirFROM,hemi,sourcesuffix);
surf2file = sprintf('%s/%s.sphere.reg%s',fsdirTO,hemi,destsuffix);

% load surfaces (note that we skip the post-processing of vertices and faces since unnecessary for what we are doing)
clear surf1;
[surf1.vertices,surf1.faces] = freesurfer_read_surf_kj(surf1file);
clear surf2;
[surf2.vertices,surf2.faces] = freesurfer_read_surf_kj(surf2file);

% do it
if size(vals,1)==1
  if length(vals) > 500
    warning('might be very slow and/or memory-intensive!');
  end
  [~,f] = min(calcconfusionmatrix(surf1.vertices(vals,1:3)',surf2.vertices',4),[],1);  % 1 x N with indices
else
  f = [];
  for p=1:size(vals,2)
    f(:,p) = griddata(surf1.vertices(:,1),surf1.vertices(:,2),surf1.vertices(:,3),vals(:,p), ...
                      surf2.vertices(:,1),surf2.vertices(:,2),surf2.vertices(:,3),interptype);
  end
end
