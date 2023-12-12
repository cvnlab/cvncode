function cvnalignEPItoFST2(subjectid,outputdir,functionaldata,dicomref,synp2,synp3,imt,wantt2masked)

% function cvnalignEPItoFST2(subjectid,outputdir,functionaldata,dicomref,synp2,synp3,imt,wantt2masked)
%
% <subjectid> is like 'cvn7002'
% <outputdir> is some output directory like '/path/to/FSalignment'
% <functionaldata> is a NIFTI file with the fMRI data. Either one volume or multiple volumes.
%   We automatically take the mean across the volumes and use the result as the "fixed image".
% <dicomref> is some DICOM folder that we can use as a reference for the fMRI data.
%   For example, this can be a SBRef scan. We primarily want this to help create reasonable
%   NIFTI headers in order to provide a good starting point for the alignment.
% <synp2> (optional) with the 2nd SyN parameter. Default: 40.
% <synp3> (optional) with the 3rd SyN parameter. Default: 3.
% <imt> (optional) indicating the initial moving transform. Can be a string that refers,
%   for example, to an ANTS .mat file (e.g. 0GenericAffine.mat). Can also be 0, 1, or 2,
%   as per the ANTS specification. Default: 1.
% <wantt2masked> (optional) is whether to load T2_masked.nii.gz (as opposed to T2.nii.gz).
%   Default: 0.
%
% Perform alignment of the T2 anatomy (prepared via FreeSurfer) to the <functionaldata>.
% The <dicomref> helps us with NIFTI header stuff to get a good starting point.
% We start with rigid, then affine, and then SyN.
% Diagnostic images of the alignment quality are written to <outputdir>.

% inputs
if ~exist('synp2','var') || isempty(synp2)
  synp2 = 40;  % units are mm
end
if ~exist('synp3','var') || isempty(synp3)
  synp3 = 3;   % units are mm
end
if ~exist('imt','var') || isempty(imt)
  imt = 1;
end
if ~exist('wantt2masked','var') || isempty(wantt2masked)
  wantt2masked = 0;
end

% make directory
mkdirquiet(outputdir);

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
if wantt2masked
  t2nifti = sprintf('%s/mri/T2_masked.nii.gz',fsdir);  % we assume a _masked version has been made
else
  t2nifti = sprintf('%s/mri/T2.nii.gz',fsdir);         % we assume mri_convert created a .nii.gz version
end
epinifti = sprintf('%s/EPI.nii.gz',outputdir);
epimasknifti = sprintf('%s/EPIvalidmask.nii.gz',outputdir);

%% %%%%% Do some preparation work

% load
f1 = load_untouch_nii(functionaldata);   % this is the functional data that will serve as the fixed image
v1 = load_untouch_nii([stripfile(functionaldata) '/valid.nii']);  % this should be a simple binary mask

% convert dicom to NIFTI for the dicomref
tt = tempdir;  % temporary directory to write to
result = unix_wrapper(sprintf('dcm2nii -o %s %s',tt,dicomref));
temp = regexp(result,'GZip\.\.\.(.+)\n','tokens');
temp = temp{1}{1};                  % this is the output NIFTI
temp2 = sprintf('%s/%s',tt,temp);   % this is the full path to the output NIFTI

% load the dicomref NIFTI
r1 = load_untouch_nii(temp2);       % this is the reference NIFTI
delete(temp2);                      % clean up

% write an inspection of the dicomref
imwrite(uint8(255*makeimagestack(double(r1.img(:,:,round(end/2))),1)),gray(256),sprintf('%s/dicomrefbefore.png',outputdir));

% take the mean of the functional data and save into the official "epinifti" file
newdata = flipdim(permute(mean(single(f1.img),4),[2 1 3]),2);  % notice the strange permute and flipdim [this is because dcm2nii does some reordering]
%[newdata,~,~] = homogenizevolumes(newdata);
r1.img = cast(newdata,class(r1.img));
save_untouch_nii(r1,epinifti);

% write an inspection of the "epinifti"
imwrite(uint8(255*makeimagestack(double(r1.img(:,:,round(end/2))),1)),gray(256),sprintf('%s/dicomrefafter.png',outputdir));

% save the official "epimasknifti"
newdata = flipdim(permute(v1.img,[2 1 3]),2);  % notice the strange permute and flipdim
r1.img = cast(newdata,class(r1.img));
save_untouch_nii(r1,epimasknifti);

%% %%%%% Now do the real work

% define
file0  = t2nifti;        % moving image
file1  = epinifti;       % fixed image
file1m = epimasknifti;   % mask for fixed image

% calc
fixedres = mean(r1.hdr.dime.pixdim(2:4));  % what is the "average" resolution of fixed image

% RIGID ALIGNMENT
if ischar(imt)
  imt0 = imt;   % if <imt> is a string, use that as the initial moving transform
else
  imt0 = sprintf('[%s,%s,%d]',file1,file0,imt);  % otherwise, it's just 0 or 1 or 2
end
a = 'antsRegistration --dimensionality 3 --float 0 --output [%s,%sWarped.nii.gz] --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform %s --transform Rigid[0.1] --metric MI[%s,%s,1,32,Regular,0.25] --convergence [1000x500x250x100,1e-6,10] --shrink-factors 8x4x2x1 --smoothing-sigmas 3x2x1x0vox --masks [%s]';
pre0 = sprintf('%s/EPIrigid_',outputdir);
b = tempname;
savetext([b '.sh'],sprintf(a,pre0,pre0,imt0,file1,file0,file1m));
unix_wrapper(sprintf('sh %s',[b '.sh']));

% AFFINE ALIGNMENT
% Notice we do only the last resolution stage.
a = 'antsRegistration --dimensionality 3 --float 0 --output [%s,%sWarped.nii.gz] --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform %s/EPIrigid_0GenericAffine.mat --transform Affine[0.1] --metric MI[%s,%s,1,32,Regular,0.25] --convergence [100,1e-6,10] --shrink-factors 1 --smoothing-sigmas 0vox --masks [%s]';
pre0 = sprintf('%s/EPIaffine_',outputdir);
b = tempname;
savetext([b '.sh'],sprintf(a,pre0,pre0,outputdir,file1,file0,file1m));
unix_wrapper(sprintf('sh %s',[b '.sh']));

% SYN ALIGNMENT
% Notice the use of SyN.
% Notice we only do the last resolution stage.
a = 'antsRegistration --dimensionality 3 --float 0 --output [%s,%sWarped.nii.gz] --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform %s/EPIaffine_0GenericAffine.mat --transform SyN[0.1,%.2f,%.2f] --metric CC[%s,%s,1,4] --convergence [20,1e-6,10] --shrink-factors 1 --smoothing-sigmas 0vox --masks [%s]';
pre0 = sprintf('%s/EPIsyn_',outputdir);
b = tempname;
savetext([b '.sh'],sprintf(a,pre0,pre0,outputdir,synp2/fixedres,synp3/fixedres,file1,file0,file1m));
unix_wrapper(sprintf('sh %s',[b '.sh']));

% inspect the alignment
makeimagestack3dfiles(file1,                 sprintf('%s/epi',outputdir),             [4 4 4],[0 1 1],[],1);
makeimagestack3dfiles([pre0 'Warped.nii.gz'],sprintf('%s/anatmatchedtoepi',outputdir),[4 4 4],[0 1 1],[],1);
