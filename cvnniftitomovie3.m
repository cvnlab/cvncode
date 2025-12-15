function cvnniftitomovie3(nifti0,mov0,framerate,rots,flips,reorder,specialdrop,crf)

% function cvnniftitomovie3(nifti0,mov0,framerate,rots,flips,reorder,specialdrop,crf)
%
% <nifti0> is a wildcard matching one or more 4D NIFTI files (or DICOM directories).
%   Alternatively, can be the data directly like X x Y x Z x T or a cell vector of 
%   things like that.
% <mov0> is the .mp4 movie file to write, e.g. 'output.mp4'
% <framerate> is the desired number of frames per second.
% <rots> (optional) is 3-element vector with number of CCW rotations
%   to perform for each view. Default: [0 0 0].
% <flips> (optional) is 3-element vector with whether to left-right
%   flip each view (after the <rots> are dealt with). Default: [0 0 0].
% <reorder> (optional) is new permutation order for the three slice views.
%   Default: [1 2 3] (i.e. do nothing).
% <specialdrop> (optional) is number of trailing volumes to drop at the end
%   of each run after loading it in. Default: 0.
% <crf> (optional) controls the movie compression. The scale is 1-51
%   where 1 is very low compression, 23 is default, and 51 is high compression.
%   Default: 18.
%
% Create output.mp4 file. We visualize the middle slice along each 
% of the three dimensions, and show every volume in every run.
%
% We also create a outputSCRUB.mp4 version. This is 120 frames
% equally spaced from beginning to end (rounded to nearest frame)
% and at fps of 120.
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

% internal constants
magicfps = 120;

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
if ~exist('specialdrop','var') || isempty(specialdrop)
  specialdrop = 0;
end
if ~exist('crf','var') || isempty(crf)
  crf = 18;
end

% special scrub filename
mov1 = [mov0(1:end-4) 'SCRUB.mp4'];

% make a temporary directory
temp0 = tempname;
mkdirquiet(temp0);
temp1 = tempname;
mkdirquiet(temp1);

% delete the movie file if it exists
delete(mov0);
delete(mov1);

% calc
isalreadydata = isnumeric(nifti0) || (iscell(nifti0) && isnumeric(nifti0{1}));  % is nifti0 already the data?

% match the NIFTI files
if isalreadydata
  if ~iscell(nifti0)
    nifti0 = {nifti0};
  end
  numruns = length(nifti0);
else
  runs = matchfiles(nifti0);
  numruns = length(runs);
end

% do it
cnt = 1;
for zz=1:numruns

  % load data
  if isalreadydata
    data = nifti0{zz};
  else
    if exist(runs{zz},'dir')  % DICOM dir?
      data = dicomloaddir(runs{zz});
      assert(length(data)==1);
      data = data{1};
    else
      data = getfield(load_untouch_nii(runs{zz}),'img');  % note: no slope/intercept adjustment!!
    end
  end
  
  % drop?
  if ~isequal(specialdrop,0)
    data = data(:,:,:,1:end-specialdrop);
  end

  % determine rng
  if zz==1
    rng = prctile(flatten(double(data(:,:,:,1))),[.5 99.5]);
    mx = max(sizefull(data,3));  % what is the largest of all three dimensions?
  end

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

  % write each volume
  for p=1:size(data,4)
    
    % create 2D images
    im1 = placematrix(rng(1)*ones(mx,mx),flip1(rotatematrix(data(:,:,round(end/2),p),          1,2,rots(1))),[1 1]);
    im2 = placematrix(rng(1)*ones(mx,mx),flip2(rotatematrix(squish(data(:,round(end/2),:,p),2),1,2,rots(2))),[1 1]);
    im3 = placematrix(rng(1)*ones(mx,mx),flip3(rotatematrix(squish(data(round(end/2),:,:,p),2),1,2,rots(3))),[1 1]);

    % deal with reorder
    im = cat(3,im1,im2,im3);
    im = im(:,:,reorder);
    
    % make a single montage image
    im = cat(2,im(:,:,1),im(:,:,2),im(:,:,3));

    % put square    
    if p==1
      im(1:10,1:10) = rng(2);
    end

    % write png file
    imwrite(uint8(255*makeimagestack(im,rng)),gray(256),sprintf('%s/image%05d.png',temp0,cnt));

    % increment
    cnt = cnt + 1;

  end

end

% make a special 120 frames, 1-s version
extractix = round(linspace(1,cnt-1,magicfps));
for p=1:length(extractix)
  assert(copyfile(sprintf('%s/image%05d.png',temp0,extractix(p)),sprintf('%s/image%05d.png',temp1,p)));
end

% create a movie from image files
unix_wrapper(sprintf('ffmpeg -framerate %d -pattern_type glob -i ''%s/image*.png'' -crf %d -c:v libx264 -pix_fmt yuv420p -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" %s',framerate,temp0,crf,mov0));
unix_wrapper(sprintf('ffmpeg -framerate %d -pattern_type glob -i ''%s/image*.png'' -crf %d -c:v libx264 -pix_fmt yuv420p -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" %s',magicfps,temp1,crf,mov1));

% clean up
rmdirquiet(temp0);
rmdirquiet(temp1);
