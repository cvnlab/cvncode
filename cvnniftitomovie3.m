function cvnniftitomovie3(nifti0,mov0,framerate,rots)

% function cvnniftitomovie3(nifti0,mov0,framerate,rots)
%
% <nifti0> is a wildcard matching one or more 4D NIFTI files
% <mov0> is the .mp4 movie file to write
% <framerate> is the desired number of frames per second.
% <rots> (optional) is 3-element vector with number of CCW rotations
%   to perform for each view. Default: [0 0 0].
%
% Create a .mp4 file. We visualize the middle slice along each 
% of the three dimensions, and show every volume in every run.
%
% The range used is set by the 0.5 and 99.5th percentile of the values
% in the first volume of the first run. To distinguish runs from each 
% other, we place a white square (10-pixel wide) at the upper left for
% the first volume in each run.
% 
% Note that we require ffmpeg to create the .mp4 file.
%
% Example:
% nsd_savenifti(randn(50,50,30,100),[1 1 1],'test1.nii.gz');
% nsd_savenifti(randn(50,50,30,100),[1 1 1],'test2.nii.gz');
% cvnniftitomovie3('test*.nii.gz','test.mp4',30);

% inputs
if ~exist('rots','var') || isempty(rots)
  rots = [0 0 0];
end

% make a temporary directory
temp0 = tempname;
mkdirquiet(temp0);

% delete the movie file if it exists
delete(mov0);

% match the NIFTI files
runs = matchfiles(nifti0);

% do it
cnt = 1;
for zz=1:length(runs)

  % load data
  data = getfield(load_untouch_nii(runs{zz}),'img');  % note: no slope/intercept adjustment

  % determine rng
  if zz==1
    rng = prctile(flatten(double(data(:,:,:,1))),[.5 99.5]);
    mx = max(sizefull(data,3));  % what is the largest of all three dimensions?
  end

  % write each volume
  for p=1:size(data,4)
    im1 = placematrix(rng(1)*ones(mx,mx),rotatematrix(data(:,:,round(end/2),p),          1,2,rots(1)),[1 1]);
    im2 = placematrix(rng(1)*ones(mx,mx),rotatematrix(squish(data(:,round(end/2),:,p),2),1,2,rots(2)),[1 1]);
    im3 = placematrix(rng(1)*ones(mx,mx),rotatematrix(squish(data(round(end/2),:,:,p),2),1,2,rots(3)),[1 1]);
    im = cat(2,im1,im2,im3);
    if p==1
      im(1:10,1:10) = rng(2);
    end
    imwrite(uint8(255*makeimagestack(im,rng)),gray(256),sprintf('%s/image%05d.png',temp0,cnt));
    cnt = cnt + 1;
  end

end

% create a movie from image files
unix_wrapper(sprintf('ffmpeg -framerate %d -pattern_type glob -i ''%s/image*.png'' -crf 22 -c:v libx264 -pix_fmt yuv420p -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" %s',framerate,temp0,mov0));

% clean up
rmdirquiet(temp0);
