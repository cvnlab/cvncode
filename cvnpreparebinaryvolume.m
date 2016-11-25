function cvnpreparebinaryvolume(subj)
% Create a binary mask that indicates the "error" places. As such, we can
% assess whether the error places lie in our ROI. The resulting file is
% binarymask.mgz
% All non brain tissue is 0. Brain tissue is 1. You can set all error
% voxels to value 2.
%
%   Input:
%       subj: subjectname, i.e. 'CVNS004'
%Example:
% cvnpreparebinaryvolume('CVNS004');


if(~exist('subj','var') || isempty(subj))
    error('Please input subject foler name, i.e. "CVNS004" ');
end

% find the path
dir = sprintf('%s/%s/mri/',cvnpath('freesurfer'),subj);

% first, make a copy of aseg.mgz
if ~exist([dir 'binaryvolume.mgz'],'file')
    copyfile([dir 'aseg.mgz'],[dir 'binaryvolume.mgz']);
    fprintf('Copy aseg.mgz to binaryolume.mgz\n');
else
    error('binaryvolume.mgz already exists. You can delete the existed binaryvolume.mgz and rerun this function');
end


% Read in the volumn
%% read the volumes
mri_binarymask = MRIread([dir 'binaryvolume.mgz']);

% set all non-zero values to 1.
mri_binarymask.vol(mri_binarymask.vol(:)~=0)=1;
fprintf(' All brain tissues are labeled using intensity 1\n');

% save the file
MRIwrite(mri_binarymask ,[dir 'binaryvolume.mgz']);


fprintf('Now you can load binary.mgz into freeview and label the error places using intensity value 2\n');
end