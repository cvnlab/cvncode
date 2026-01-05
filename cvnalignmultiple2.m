function cvnalignmultiple2(niifiles,niifiles2,subjectid,mcmask,skips,rots)

% function cvnalignmultiple(niifiles,niifiles2,subjectid,mcmask,skips,rots)
%
% <niifiles> is a cell vector of NIFTI files (T1 files)
% <niifiles2> is a cell vector of NIFTI files (T2 files)
% <subjectid> is 
%   (1) subjectid (in which case we write results to 
%       cvnpath('anatomicals')/subjectid and figures to 
%       cvnpath('ppresults')/subjectid
%   (2) {A} where A is the directory to write results and figures to.
% <mcmask> (optional) is {mn sd} with the mn and sd outputs of defineellipse3d.m.
%   If [] or not supplied, we prompt the user to determine these with the GUI.
% <skips> (optional) is number of slices to skip in each of the 3 dimensions.
%   Default: [4 4 4].
% <rots> (optional) is a 3-vector with number of CCW rotations to apply for each slicing.
%   Default: [0 0 0].
%
% The purpose of this function is to align and average several T1s and several T2s.
%
% We pause for the user to manually define an binary 3D ellipse on the 
% first (T1) NIFTI in order to restrict the alignment procedure to those voxels.
% Consider, for example, restricting the ellipse to cortex and maybe a little bit
% of surrounding space.
%
% We make various assumptions about the resolution and orientation of the files
% (e.g. 0.8 mm and AIL orientation); this should be generalized eventually?
%
% For T1s, we use rigid-body and correlation metrics. For T2s, we use rigid-
% body and mutual information. The target is an aggregated aligned and averaged
% T1 volume. Volumes are padded to 320 x 320 x 320 at 0.8-mm resolution.
%
% We write out final NIFTI files as well as individual (aligned) reps.
% All written NIFTI files have "clean" headers.
%
% Inspections of results are also written.

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

% calc
if iscell(subjectid)
  dir0 = subjectid{1};
  pp0 = subjectid{1};
else
  dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
  pp0 =  sprintf('%s/%s',cvnpath('ppresults'),  subjectid);
end

% match files
niifiles  = matchfiles(niifiles);
niifiles2 = matchfiles(niifiles2);

% load the first volume
vol1orig = load_untouch_nii(niifiles{1});
vol1size = vol1orig.hdr.dime.pixdim(2:4);
vol1 = double(vol1orig.img);
if vol1orig.hdr.dime.scl_slope ~= 0
  vol1 = vol1 * vol1orig.hdr.dime.scl_slope + vol1orig.hdr.dime.scl_inter;
end
vol1(isnan(vol1)) = 0;

% check original data is 0.8-mm isotropic
assert(isequal(round(vol1orig.hdr.dime.pixdim(2:4)*1000),[800 800 800]),'UNEXPECTED');

% manually define ellipse on the first volume for use in the auto alignment
if isempty(mcmask)
  [f,mn,sd] = defineellipse3d(vol1);
  mcmask = {mn sd};
  fprintf('mcmask = %s;\n',cell2str(mcmask));
else
  mn = mcmask{1};
  sd = mcmask{2};
end

% inspect first volume
makeimagestack3dfiles(vol1,sprintf('%s/%sfigures/T%d_vol%03d',pp0,'T1T2average',1,1),skips,rots,[],1);

% prep
allniifiles = [niifiles(:); niifiles2(:)];
whmode = [ones(1,length(niifiles)) 2*ones(1,length(niifiles2))];

% loop over volumes
vols = vol1;
for p=2:length(allniifiles)

  % load the volume
  vol2 = load_untouch_nii(allniifiles{p});
  vol2size = vol2.hdr.dime.pixdim(2:4);
  vol2data = double(vol2.img);
  if vol2.hdr.dime.scl_slope ~= 0
    vol2data = vol2data * vol2.hdr.dime.scl_slope + vol2.hdr.dime.scl_inter;
  end
  vol2data(isnan(vol2data)) = 0;
  
  % start the alignment
  voltemp = mean(vols(:,:,:,1:min(size(vols,4),lastel(find(whmode==1)))),4);
  alignvolumedata(vol2data,vol2size,voltemp,vol1size);  % NOTICE THAT AGGREGATED T1 VOLUME IS THE TARGET!

  switch whmode(p)
  case 1
    % auto-align (rigid-body, correlation)
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
  case 2
    % auto-align (rigid-body, mutual info)
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2],[],[],[],1);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
  end

  % get the transformation
  tr = alignvolumedata_exporttransformation;

  % get slices from vol2 to match vol1
  matchvol = extractslices(vol2data,vol2size,vol1,vol1size,tr);
  
  % REALLY IMPORTANT: ENSURE FINITE
  matchvol(~isfinite(matchvol)) = 0;

  % inspect it
  switch whmode(p)
  case 1
    num = p;
  case 2
    num = p-sum(whmode==1);
  end
  makeimagestack3dfiles(matchvol,sprintf('%s/%sfigures/T%d_vol%03d',pp0,'T1T2average',whmode(p),num),skips,rots,[],1);
  
  % record it
  vols(:,:,:,p) = matchvol;
  
  % clean up
  close all;

end

% loop over each type (T1, T2)
for zz=1:2

  % average
  ix = find(whmode==zz);
  meanvol = mean(vols(:,:,:,ix),4);

  % inspect it
  makeimagestack3dfiles(meanvol,sprintf('%s/%sfigures/T%d_volavg',pp0,'T1T2average',zz),skips,rots,[],1);

end

%%%%% proceed to writing out final files

% check finite
assert(all(isfinite(vols(:))));

% pad to 320 x 320 x 320 matrix size
padnum = [];
for dim=1:3
  padnum(dim) = (320-size(vols,dim))/2;
end
assert(all(isint(padnum)));
vols = padarray(vols,padnum,0,'both');

% data are in AIL. let's go to LPI
vols = flipdim(permute(vols,[3 1 2 4]),2);

% loop over each type (T1, T2)
for zz=1:2

  % average
  ix = find(whmode==zz);
  meanvol = mean(vols(:,:,:,ix),4);

  % write NIFTI with clean header
  nsd_savenifti(int16(meanvol),[.8 .8 .8],sprintf('%s/%s.nii.gz',dir0,sprintf('T%daverage',zz)));
  for rep=1:length(ix)
    nsd_savenifti(int16(vols(:,:,:,ix(rep))),[.8 .8 .8],sprintf('%s/%s_rep%02d.nii.gz',dir0,sprintf('T%daverage',zz),rep));
  end

end
