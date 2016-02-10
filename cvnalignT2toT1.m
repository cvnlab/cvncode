function cvnalignT2toT1(subjectid,dataloc,wantmi)

% function cvnalignT2toT1(subjectid,dataloc,wantmi)
%
% <subjectid> is like 'C0001'
% <dataloc> is the scan directory like '/stone/ext1/fmridata/20151028-ST001-kk,testB'
% <wantmi> is whether to use mutual information as the metric
%
% Load T2 volume from <dataloc> (DICOM format). (We use just the first T2 scan.)
% Convert to NIFTI, and then register to the FreeSurfer T1.nii.gz volume.  
% To perform the registration, we use flirt, using a rigid-body transformation and
% sinc interpolation.  The output is a file called T2alignedtoT1.nii.gz written to
% the FreeSurfer mri directory.
%
% See code for assumptions.

% calc
dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% figure out T2 file [ASSUME THAT WE WILL MATCH PAIRS OF DIRECTORIES, JUST USE THE FIRST SCAN]
t2file = matchfiles(sprintf('%s/*T2w*',dataloc));
assert(mod(length(t2file),2)==0);
t2file = t2file{2};   % [hint: 2nd of the two is the one to use, as it is homogenity-corrected]

% convert dicoms to NIFTI
assert(0==unix(sprintf('dcm2nii -o %s -r N -x N %s',dir0,t2file)));

% find the T2 NIFTI
t2nifti = matchfiles(sprintf('%s/*T2w*nii.gz',dir0));
assert(length(t2nifti)==1);
t2nifti = t2nifti{1};

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
assert(0==unix(sprintf('flirt -in %s -ref %s -out %s -interp sinc -dof 6 %s',t2nifti,t1nifti,t2tot1nifti,extrastr)));

% inspect the results
makeimagestack3dfiles(t1nifti,    sprintf('%s/T1T2alignment/T1',dir0),[5 5 5],[-1 1 0],[],1);
makeimagestack3dfiles(t2tot1nifti,sprintf('%s/T1T2alignment/T2',dir0),[5 5 5],[-1 1 0],[],1);
