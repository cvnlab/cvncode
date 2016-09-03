function cvnniftitomovie2(nifti0,mov0,framerate)

% function cvnniftitomovie2(nifti0,mov0,framerate)
%
% <nifti0> is a path or wildcard matching a 4D NIFTI file
% <mov0> is the movie file to write
% <framerate> (optional) is the number of frames per second. Default: 10.
%
% Load NIFTI file and write out a movie using a gray colormap.
% The range is the 0.5 and 99.5th percentile of the first volume.

% input
if ~exist('framerate','var') || isempty(framerate)
  framerate = 10;
end

% deal with file
nifti0 = matchfiles(nifti0);
assert(length(nifti0)==1);
nifti0 = nifti0{1};

% load data
data = getfield(load_untouch_nii(nifti0),'img');

% determine rng
rng = prctile(flatten(double(data(:,:,:,1))),[.5 99.5]);

% process the images
newdata = uint8([]);
for p=1:size(data,4)
  newdata(:,:,p) = uint8(255*makeimagestack(data(:,:,:,p),rng));
end

% save memory
clear data;

% make a movie
imagesequencetomovie(newdata,mov0,framerate);
