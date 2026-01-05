function cvnMNIandbrainmask(subjectid,brainmaskname)

% function cvnMNIandbrainmask(subjectid,brainmaskname)
%
% <subjectid> is:
%   (1) subjectid (FreeSurfer ID) where use cvnpath('freesurfer')/subjectid/mri/T1.nii.gz
%       and an <outputdir> of cvnpath('anatomicals')/subjectid
%   (2) {<t1file> <outputdir>} which specifies the T1 and output directory directly.
% <brainmaskname> (optional) is the prefix name for the brain mask.
%   Default: 'brainmask'.
%
% Using the input T1, determine MNI alignment using fnirt. On basis of the 
% determined alignment, we backproject to the native subject space
% a liberal brain mask (named <brainmaskname>.nii.gz.). 
% Various outputs are written to <outputdir>.
%
% Some template files are taken and used from nsddata.

% # Based on
% # https://github.com/Washington-University/HCPpipelines/blob/master/PreFreeSurfer/scripts/BrainExtraction_FNIRTbased.sh

% setup
if iscell(subjectid)
  Input = subjectid{1};
  outputdir = subjectid{2};
else
  fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
  Input = sprintf('%s/mri/T1.nii.gz',fsdir);                         % master T1
  outputdir = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
end
if ~exist('brainmaskname','var') || isempty(brainmaskname)
  brainmaskname = 'brainmask';
end
nsddatadir = '/home/surly-raid3/kendrick-data/nsd/nsddata';

% define
Ref = sprintf('%s/templates/MNI152_T1_1mm.nii.gz',nsddatadir);          % MNI template
RefMask = sprintf('%s/templates/MNI152_T1_1mm_brain_mask_dil.nii.gz',nsddatadir);  % MNI liberal brain mask
RefMask2 = sprintf('%s/templates/MNI152_T1_1mm_brain_mask_dil_dilM.nii.gz',nsddatadir);
WD = sprintf('%s/MNI',outputdir);
BaseName = 'T1';
OutputBrainMask = sprintf('%s/%s.nii.gz',outputdir,brainmaskname);        % output file
ConfigFile = sprintf('%s/templates/T1_2_MNI152_2mm.cnf',nsddatadir);    % fnirt config

% make dir
mkdirquiet(WD);

% affine to MNI
unix_wrapper(sprintf('flirt -interp spline -dof 12 -in "%s" -ref "%s" -omat "%s"/roughlin.mat -out "%s"/"%s"_to_MNI_roughlin.nii.gz -nosearch',Input,Ref,WD,WD,BaseName));

% nonlinear to MNI
unix_wrapper(sprintf('fnirt --in="%s" --ref="%s" --aff="%s"/roughlin.mat --refmask="%s" --fout="%s"/str2standard.nii.gz --jout="%s"/NonlinearRegJacobians.nii.gz --refout="%s"/IntensityModulatedT1.nii.gz --iout="%s"/"%s"_to_MNI_nonlin.nii.gz --logout="%s"/NonlinearReg.txt --intout="%s"/NonlinearIntensities.nii.gz --cout="%s"/NonlinearReg.nii.gz --config="%s"',Input,Ref,WD,RefMask,WD,WD,WD,WD,BaseName,WD,WD,WD,ConfigFile));
  % str2standard.nii.gz is the warpfield?
  % T1_to_MNI_nonlin.nii.gz - resampled T1 (linear interp) [but, alternatively, could use applywarp...]

% invert the warp
unix_wrapper(sprintf('invwarp --ref="%s" -w "%s"/str2standard.nii.gz -o "%s"/standard2str.nii.gz',Input,WD,WD));  % NOTE: Should be Input, not Ref!

% use nearest-neighbor to get brain mask in subject native space
unix_wrapper(sprintf('applywarp --rel --interp=nn --in="%s" --ref="%s" -w "%s"/standard2str.nii.gz -o "%s"',RefMask2,Input,WD,OutputBrainMask));
