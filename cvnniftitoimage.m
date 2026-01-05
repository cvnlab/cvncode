function cvnniftitoimage(nifti0,outputfile,rots,flips,reorder)

% function cvnniftitoimage(nifti0,outputfile,rots,flips,reorder)
%
% <nifti0> is:
%   (1) name of NIFTI file
%   (2) a loaded NIFTI file (via load_untouch_nii.m)
%   (3) the volume itself
% <outputfile> is the .png file to write
% <rots> (optional) is 3-element vector with number of CCW rotations
%   to perform for each view. Default: [0 0 0].
% <flips> (optional) is 3-element vector with whether to left-right
%   flip each view (after the <rots> are dealt with). Default: [0 0 0].
% <reorder> (optional) is new permutation order for the three slice views.
%   Default: [1 2 3] (i.e. do nothing).
%
% Write out a three-slice visualization of <nifti0>.
% We visualize the middle slice along each of the three dimensions.
% We take only the first volume (if there are multiple volumes).
% The range used is set by the 0.5 and 99.5th percentile of the values.
%
% Example:
% cvnniftitoimage(getsamplebrain(3),'test.png',[0 1 1]);

% inputs
if ~exist('rots','var') || isempty(rots)
  rots = [0 0 0];
end
if ~exist('flips','var') || isempty(flips)
  flips = [0 0 0];
end
if ~exist('reorder','var') || isempty(reorder)
  reorder = [1 2 3];
end

% load data
if ischar(nifti0)
  a1 = load_untouch_nii(nifti0);  % note: no slope/intercept adjustment!!
  data = double(a1.img(:,:,:,1));
elseif isnumeric(nifti0)
  data = double(nifti0(:,:,:,1));
else
  data = double(nifti0.img(:,:,:,1));
end

% determine rng
rng = prctile(flatten(double(data)),[.5 99.5]);
mx = max(sizefull(data,3));  % what is the largest of all three dimensions?

% prepare flip functions
if flips(1)
  flip1 = @(x) flipdim(x,2);
else
  flip1 = @(x) x;
end
if flips(2)
  flip2 = @(x) flipdim(x,2);
else
  flip2 = @(x) x;
end
if flips(3)
  flip3 = @(x) flipdim(x,2);
else
  flip3 = @(x) x;
end
  
% create 2D images
p = 1;
im1 = placematrix(rng(1)*ones(mx,mx),flip1(rotatematrix(data(:,:,round(end/2),p),          1,2,rots(1))),[1 1]);
im2 = placematrix(rng(1)*ones(mx,mx),flip2(rotatematrix(squish(data(:,round(end/2),:,p),2),1,2,rots(2))),[1 1]);
im3 = placematrix(rng(1)*ones(mx,mx),flip3(rotatematrix(squish(data(round(end/2),:,:,p),2),1,2,rots(3))),[1 1]);

% deal with reorder
im = cat(3,im1,im2,im3);
im = im(:,:,reorder);

% make a single montage image
im = cat(2,im(:,:,1),im(:,:,2),im(:,:,3));

% write png file
imwrite(uint8(255*makeimagestack(im,rng)),gray(256),outputfile);
