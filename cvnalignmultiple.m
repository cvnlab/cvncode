function cvnalignmultiple(niifiles,outputprefix,mcmask,skips,rots)

% function cvnalignmultiple(niifiles,outputprefix,mcmask,skips,rots)
%
% <niifiles> is a cell vector of NIFTI files
% <outputprefix> is like '/stone/ext1/anatomicals/C0041/T1average'
% <mcmask> (optional) is {mn sd} with the mn and sd outputs of defineellipse3d.m.
%   If [] or not supplied, we prompt the user to determine these with the GUI.
% <skips> (optional) is number of slices to skip in each of the 3 dimensions.
%   Default: [4 4 4].
% <rots> (optional) is a 3-vector with number of CCW rotations to apply for each slicing.
%   Default: [0 0 0].
%
% The purpose of this function is to align and average all of the NIFTI files
% and write out a new NIFTI file.
%
% We pause for the user to manually define an binary 3D ellipse on the 
% first NIFTI in order to restrict the alignment procedure to those voxels.
% Consider, for example, restricting the ellipse to cortex and maybe a little bit
% of surrounding space.
%
% We loop over NIFTIs after the first one to align each with the first using
% a rigid-body transformation and a correlation metric. Slices are extracted
% using cubic interpolation to derive volumes that match the first.
%
% Our final volume is the mean of all of the volumes (first volume plus the
% resliced versions of the remaining volumes).
%
% We write out a NIFTI file to <outputprefix>.nii.gz using the first NIFTI as a template.
% 
% Inspections of results are written to a directory called "<outputprefix>figures".

% input
if ~exist('mcmask','var') || isempty(mcmask)
  mcmask = [];
end
if ~exist('skips','var') || isempty(skips)
  skips = [4 4 4];
end
if ~exist('rots','var') || isempty(rots)
  rots = [0 0 0];
end

% make directory
mkdirquiet(sprintf('%sfigures',outputprefix));

% match files
niifiles = matchfiles(niifiles);

% load the first volume
vol1 = load_nii(gunziptemp(niifiles{1}));
vol1size = vol1.hdr.dime.pixdim(2:4);
vol1data = double(vol1.img);
vol1data(isnan(vol1data)) = 0;

% manually define ellipse on the first volume for use in the auto alignment
if isempty(mcmask)
  [f,mn,sd] = defineellipse3d(vol1data);
  mcmask = {mn sd};
  fprintf('mcmask = %s;\n',cell2str(mcmask));
else
  mn = mcmask{1};
  sd = mcmask{2};
end

% inspect first volume
makeimagestack3dfiles(vol1data,sprintf('%sfigures/vol%03d',outputprefix,1),skips,rots,[],1);

% loop over volumes
vols = vol1data;
for p=2:length(niifiles)

  % load the volume
  vol2 = load_nii(gunziptemp(niifiles{p}));
  vol2size = vol2.hdr.dime.pixdim(2:4);
  vol2data = double(vol2.img);
  vol2data(isnan(vol2data)) = 0;
  
  % start the alignment
  alignvolumedata(vol2data,vol2size,vol1data,vol1size);  % NOTICE THAT FIRST VOLUME IS THE TARGET!

  % auto-align (rigid-body, correlation)
  alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4]);
  alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2]);
  alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);

  % get the transformation
  tr = alignvolumedata_exporttransformation;

  % get slices from vol2 to match vol1
  matchvol = extractslices(vol2data,vol2size,vol1data,vol1size,tr);

  % inspect it
  makeimagestack3dfiles(matchvol,sprintf('%sfigures/vol%03d',outputprefix,p),skips,rots,[],1);
  
  % record it
  vols(:,:,:,p) = matchvol;
  
  % clean up
  close all;

end

% average
meanvol = mean(vols,4);

% inspect it
makeimagestack3dfiles(meanvol,sprintf('%sfigures/volavg',outputprefix),skips,rots,[],1);

% save NIFTI file as output
vol1.img = cast(meanvol,class(vol1.img));
save_nii(vol1,sprintf('%s.nii.gz',outputprefix));
