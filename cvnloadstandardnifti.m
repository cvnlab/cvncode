function data = cvnloadstandardnifti(volfiles)

% function data = cvnloadstandardnifti(volfiles)
%
% <volfiles> is a path or wildcard matching one or more NIFTI volume files.
%   Can also mix-and-match raw matrices with paths. Each volume is presumed to 
%   be in FreeSurfer's space and to have the same spatial dimensions
%   (e.g. the 256 or 320 space).
%
% Return the volumes as X x Y x Z x N where N corresponds to different volumes.
% In the case of NIFTI files, we use fstoint.m to bring the volumes to our
% internal MATLAB space. We ensure that the data are returned in double format.
%
% history:
% - 2016/11/28 - allow mix-and-match with raw matrices
% - 2016/12/05 - allow loading of 4D nifti

% match the files
if ~iscell(volfiles)
  volfiles = {volfiles};
end
newfiles = {};
for p=1:length(volfiles)
  if ischar(volfiles{p})
    newfiles = [newfiles fullfilematch(volfiles{p})];
  else
    newfiles{end+1} = volfiles{p};
  end
end

% load them
data = [];
for p=1:length(newfiles)
  if ischar(newfiles{p})
    a1 = load_untouch_nii(newfiles{p});
    vol = fstoint(double(a1.img) * a1.hdr.dime.scl_slope + a1.hdr.dime.scl_inter);
  else
    vol = double(newfiles{p});
  end
  data=cat(4,data,vol);
end
