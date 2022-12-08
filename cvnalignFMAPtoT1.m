function cvnalignFMAPtoT1(subjectid,datadir,outputdir,wantaffine,tr,skips,rots)

% function cvnalignFMAPtoT1(subjectid,datadir,outputdir,wantaffine,tr,skips,rots)
%
% <subjectid> is like 'C0001'
% <datadir> is like '/home/stone-ext1/fmridata/20160609-CVNS001-ReadingE'
% <outputdir> is like [<datadir> '/fmapalignment']
% <wantaffine> (optional) is whether to use affine (instead of rigid-body). Default: 0.
% <tr> (optional) is the starting point to use. Default is to use a built-in default.
% <skips> (optional) is number of slices to skip in each of the 3 dimensions.
%   Default: [4 4 4].
% <rots> (optional) is a 3-vector with number of CCW rotations to apply for each slicing.
%   Default: [1 1 1].
%
% Perform alignment of the fieldmaps (in <datadir>/dicom/MR*field_mapping*) to the
% FS T1.nii.gz.  We process each fieldmap, considering only the first of the two volumes 
% that compose each fieldmap.
%
% Registration is automatically performed using a rigid-body (or affine) transformation
% and a correlation metric.
%
% Notes:
% - There is an initial guess for the alignment, and this may need to be revisited
%   as the need arises...
% - At the beginning of the first alignment, there is a pause for the user to manually
%   set the rough initial seed for the alignment.
% - We do not use an ellipse in the alignment (the whole fieldmap volume is used).
% - The alignment of each fieldmap is re-used as a starting point for the 
%   next fieldmap alignment.
%
% We extract slices through the fieldmaps to match the T1, and then average across
% the fieldmaps.
%
% Diagnostic images of the alignment quality are written to <outputdir>.
% We also write out FMAPalignedtoT1.nii.gz to <outputdir> (single format).

% input
if ~exist('wantaffine','var') || isempty(wantaffine)
  wantaffine = 0;
end
if ~exist('tr','var') || isempty(tr)
  tr = [];
end
if ~exist('skips','var') || isempty(skips)
  skips = [4 4 4];
end
if ~exist('rots','var') || isempty(rots)
  rots = [1 1 1];
end

% calc
dir0 =  sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
pp0 =   sprintf('%s/%s',cvnpath('ppresults'),  subjectid);
fsdir = sprintf('%s/%s',cvnpath('freesurfer'), subjectid);
t1nifti = sprintf('%s/mri/T1.nii.gz',fsdir);

% make dir
mkdirquiet(outputdir);

% load the T1 anatomy
vol1orig = load_untouch_nii(gunziptemp(t1nifti));
vol1size = vol1orig.hdr.dime.pixdim(2:4);
vol1 = double(vol1orig.img);
if vol1orig.hdr.dime.scl_slope ~= 0
  vol1 = vol1 * vol1orig.hdr.dime.scl_slope + vol1orig.hdr.dime.scl_inter;
end
vol1(isnan(vol1)) = 0;
vol1 = fstoint(vol1);  % this is necessary to get the surfaces to match the anatomy
fprintf('*** WARNING: we are performing fstoint.m, which is incompatible with new interpretation of FS vox2ras-tkr stuff (talk to Kendrick)\n');
fprintf('vol1 has dimensions %s at %s mm.\n',mat2str(size(vol1)),mat2str(vol1size));

% match fieldmap files (magnitude only)
fprintf('we found the following fieldmaps:\n');
files = matchfiles({[datadir '/dicom/MR*field_mapping*'] [datadir '/dicom/MR*fieldmap*']})
fprintf('\n');

% loop over fieldmaps
vols = [];
for p=1:length(files)

  % load the volume
  [vol2,vol2size] = dicomloaddir(files{p});
  vol2 = double(vol2{1}(:,:,1:end/2));  % TAKE THE FIRST FIELDMAP ONLY
  vol2size = vol2size{1};

  % deal with default tr
  if p==1 && isempty(tr)
    tr = maketransformation([0 0 0],[1 2 3],[129 64 119],[1 2 3],[-1.5 41 87],[96 96 28],[192 192 67.2],[1 1 -1],[0 0 0],[0 0 0],[0 0 0]);
  end

  % start the alignment
  alignvolumedata(vol1,vol1size,vol2,vol2size,tr);  % NOTICE THAT FIRST VOLUME IS THE TARGET!

  % pause to do some manual alignment (to get a reasonable starting point)
  if p==1
    keyboard;
    tr = alignvolumedata_exporttransformation;  % report to the user to save just in case
  end

  % auto-align (correlation)
  mn = [.5 .5 .5]; sd = [2 2 2];  % use the entire fieldmap!
  if wantaffine
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[4 4 4]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[2 2 2]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1]);
  else
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
  end

  % get the transformation
  tr = alignvolumedata_exporttransformation;

  % get slices from vol2 to match vol1
  matchvol = extractslices(vol1,vol1size,vol2,vol2size,tr,1);
  
  % REALLY IMPORTANT: ENSURE FINITE (e.g. flirt blows up otherwise)
  matchvol(~isfinite(matchvol)) = 0;

  % record it
  vols(:,:,:,p) = matchvol;
  
  % clean up
  close all;

end

% average across the fieldmaps
meanvol = mean(vols,4);

% deal with format
meanvol = single(meanvol);

% inspect the results
makeimagestack3dfiles(vol1,   sprintf('%s/T1',outputdir),  skips,rots,[],1);  % T1
makeimagestack3dfiles(meanvol,sprintf('%s/fmap',outputdir),skips,rots,[],-2); % fieldmap

% save NIFTI file (FMAPs matched to the T1)
vol1orig.hdr.dime.datatype = 16;  % single (float) format
vol1orig.hdr.dime.bitpix = 16;
vol1orig.img = inttofs(meanvol);
file0 = sprintf('%s/FMAPalignedtoT1.nii',outputdir);
save_untouch_nii(vol1orig,file0); gzip(file0); delete(file0);
