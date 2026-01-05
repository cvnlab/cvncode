function cvninspectT1T2freesurfer(subjectid,outputdir)

% function cvninspectT1T2freesurfer(subjectid,outputdir)
%
% <subjectid> is like 'cvn7002'
% <outputdir> (optional) is the directory to write to.
%   Default: cvnpath('ppresults')/subjectid
%
% Write out inspections of the T1.nii.gz and T2.nii.gz files from FreeSurfer.

% inputs
if ~exist('outputdir','var') || isempty(outputdir)
  outputdir = [];
end

% calc
if isempty(outputdir)
  pp0 = sprintf('%s/%s',cvnpath('ppresults'),subjectid);
else
  pp0 = outputdir;
end
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% find the NIFTIs
t1nifti = sprintf('%s/mri/T1.nii.gz',fsdir);
t2nifti = sprintf('%s/mri/T2.nii.gz',fsdir);

% inspect the results
makeimagestack3dfiles(t1nifti,sprintf('%s/T1T2freesurfer/T1',pp0),[5 5 5],[-1 1 0],[],1);
makeimagestack3dfiles(t2nifti,sprintf('%s/T1T2freesurfer/T2',pp0),[5 5 5],[-1 1 0],[],1);
