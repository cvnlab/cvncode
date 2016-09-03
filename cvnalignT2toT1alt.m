function cvnalignT2toT1alt(subjectid,wantmi)

% function cvnalignT2toT1alt(subjectid,wantmi)
%
% <subjectid> is like 'C0001'
% <wantmi> is whether to use mutual information as the metric
%
% Load T2 volume from T2average.nii.gz. Register to the FreeSurfer T1.nii.gz volume.  
% To perform the registration, we use flirt, using a rigid-body transformation and
% sinc interpolation.  The output is a file called T2alignedtoT1.nii.gz written to
% the FreeSurfer mri directory.
%
% See code for assumptions.

% calc
dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
pp0 = sprintf('%s/%s',cvnpath('ppresults'),subjectid);
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% find the T2 NIFTI
t2nifti = sprintf('%s/T2average.nii.gz',dir0);

% find the T1 NIFTI
t1nifti = sprintf('%s/mri/T1.nii.gz',fsdir);

% define output file
t2tot1nifti = sprintf('%s/mri/T2alignedtoT1.nii.gz',fsdir);

% call flirt to perform the alignment
if wantmi
  extrastr = '-cost mutualinfo -searchcost mutualinfo';
else
  extrastr = '';
end
unix_wrapper(sprintf('flirt -v -in %s -ref %s -out %s -interp sinc -dof 6 %s',t2nifti,t1nifti,t2tot1nifti,extrastr));

% inspect the results
makeimagestack3dfiles(t1nifti,    sprintf('%s/T1T2alignment/T1',pp0),[5 5 5],[-1 1 0],[],1);
makeimagestack3dfiles(t2tot1nifti,sprintf('%s/T1T2alignment/T2',pp0),[5 5 5],[-1 1 0],[],1);


