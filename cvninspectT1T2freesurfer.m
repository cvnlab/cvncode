function cvninspectT1T2freesurfer(subjectid)

% function cvninspectT1T2freesurfer(subjectid)
%
% <subjectid> is like 'cvn7002'
%
% Write out inspections of the T1.nii.gz and T2.nii.gz files
% in the FreeSurfer subject directory.

% calc
pp0 = sprintf('%s/%s',cvnpath('ppresults'),subjectid);
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% find the NIFTIs
t1nifti = sprintf('%s/mri/T1.nii.gz',fsdir);
t2nifti = sprintf('%s/mri/T2.nii.gz',fsdir);

% inspect the results
makeimagestack3dfiles(t1nifti,sprintf('%s/T1T2freesurfer/T1',pp0),[5 5 5],[-1 1 0],[],1);
makeimagestack3dfiles(t2nifti,sprintf('%s/T1T2freesurfer/T2',pp0),[5 5 5],[-1 1 0],[],1);
