function data = cvnloadstandardnifti(volfiles)

% function data = cvnloadstandardnifti(volfiles)
%
% <volfiles> is a path or wildcard matching one or more NIFTI volume files.
%   Each volume is presumed to be in FreeSurfer's space and to have
%   the same spatial dimensions (e.g. the 256 or 320 space).
%
% Return the volumes as X x Y x Z x N where N corresponds to different volumes.
% We use fstoint.m to bring the volumes to our internal MATLAB space.
% We ensure that the data are returned in double format.

% match the files
volfiles = matchfiles(volfiles);

% load them
data = [];
for p=1:length(volfiles)
  a1 = load_untouch_nii(gunziptemp(volfiles{p}));
  data(:,:,:,p) = fstoint(double(a1.img));
end
