function cvnalignmultiple(niifiles,subjectid,outputprefix,mcmask,skips,rots)

% function cvnalignmultiple(niifiles,subjectid,outputprefix,mcmask,skips,rots)
%
% <niifiles> is a cell vector of NIFTI files
% <subjectid> is like 'C0001'
% <outputprefix> is like 'T1average'
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
% We write out a NIFTI file to <anatomicals>/<outputprefix>.nii.gz using the first NIFTI as a template.
% 
% Inspections of results are written to a directory <ppresults>/<outputprefix>figures.
%
% history:
% 2016/09/02 - change where files are written; fix the gzipping
% 2016/07/12 - switch to _untouch_
% 2016/06/10 - force non-finite values in resliced volumes to be 0 (flirt fails otherwise)
% 2016/05/29 - added visualization of residuals

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
dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
pp0 =  sprintf('%s/%s',cvnpath('ppresults'),  subjectid);

% match files
niifiles = matchfiles(niifiles);

% load the first volume
vol1orig = load_untouch_nii(niifiles{1});
vol1size = vol1orig.hdr.dime.pixdim(2:4);
vol1 = double(vol1orig.img);
if vol1orig.hdr.dime.scl_slope ~= 0
  vol1 = vol1 * vol1orig.hdr.dime.scl_slope + vol1orig.hdr.dime.scl_inter;
end
vol1(isnan(vol1)) = 0;

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
makeimagestack3dfiles(vol1,sprintf('%s/%sfigures/vol%03d',pp0,outputprefix,1),skips,rots,[],1);

% loop over volumes
vols = vol1;
for p=2:length(niifiles)

  % load the volume
  vol2 = load_untouch_nii(niifiles{p});
  vol2size = vol2.hdr.dime.pixdim(2:4);
  vol2data = double(vol2.img);
  if vol2.hdr.dime.scl_slope ~= 0
    vol2data = vol2data * vol2.hdr.dime.scl_slope + vol2.hdr.dime.scl_inter;
  end
  vol2data(isnan(vol2data)) = 0;
  
  % start the alignment
  alignvolumedata(vol2data,vol2size,vol1,vol1size);  % NOTICE THAT FIRST VOLUME IS THE TARGET!

  % auto-align (rigid-body, correlation)
  alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4]);
  alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2]);
  alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);

  % get the transformation
  tr = alignvolumedata_exporttransformation;

  % get slices from vol2 to match vol1
  matchvol = extractslices(vol2data,vol2size,vol1,vol1size,tr);
  
  % REALLY IMPORTANT: ENSURE FINITE (e.g. flirt blows up otherwise)
  matchvol(~isfinite(matchvol)) = 0;

  % inspect it
  makeimagestack3dfiles(matchvol,sprintf('%s/%sfigures/vol%03d',pp0,outputprefix,p),skips,rots,[],1);
  
  % record it
  vols(:,:,:,p) = matchvol;
  
  % clean up
  close all;

end

% average
meanvol = mean(vols,4);

%%%%% some visualizations

% inspect it
makeimagestack3dfiles(meanvol,sprintf('%s/%sfigures/volavg',pp0,outputprefix),skips,rots,[],1);

% finally, write out residual images
if size(vols,4) ~= 1  % IGNORE DEGENERATE CASE
  mx = prctile(flatten(abs(bsxfun(@minus,vols,meanvol))),99);
  for p=1:size(vols,4)
    makeimagestack3dfiles(vols(:,:,:,p)-meanvol,sprintf('%s/%sfigures/resid%03d',pp0,outputprefix,p), ...
                          skips,rots,cmapsign4(256),[-mx mx]);
  end
end

% NO LONGER WANT:
% %%%%% some finishing touches
% 
% % SPECIAL PROCESSING
% if ismember(class(vol1.img),{'single' 'double'})
%   fprintf('performing special processing.\n');
% 
%   % scale such that max is 30000
%   mx = max(meanvol(:));   fprintf('max is %.2f\n',mx);
%   fct = 30000/mx;         fprintf('applying scale factor of %.2f\n',fct);
%   meanvol = meanvol*fct;
%   
%   % check 0.8-mm isotropic
%   if ~isequal(round(vol1.hdr.dime.pixdim(2:4)*1000),[800 800 800])
%     fprintf('UNEXPECTED');
%     keyboard;
%   end
%   
%   % pad to 320 x 320 x 320 matrix size
%   padnum = [];
%   for dim=1:3
%     padnum(dim) = (320-size(meanvol,dim))/2;
%   end
%   assert(all(isint(padnum)));
%   meanvol = padarray(meanvol,padnum,0,'both');
%   assert(isequal(size(meanvol),[320 320 320]));
%   
%   % massage headers
%   vol1.hdr.dime.dim(2:4) = [320 320 320];  % NOTE: this editing may not be sufficient, but we'll see...
% 
% end

% save NIFTI file as output
vol1orig.img = cast(meanvol,class(vol1orig.img));
file0 = sprintf('%s/%s.nii',dir0,outputprefix);
save_untouch_nii(vol1orig,file0); gzip(file0); delete(file0);
