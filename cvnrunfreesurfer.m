function cvnrunfreesurfer(subjectid,dataloc,extraflags,scanstouse,t2nifti)

% function cvnrunfreesurfer(subjectid,dataloc,extraflags,scanstouse,t2nifti)
%
% <subjectid> is like 'C0001'
% <dataloc> is:
%   (1) the scan directory like '/home/stone-ext1/fmridata/20151014-ST001-wynn,subject1'
%   (2) a NIFTI T1 .nii.gz file like '/home/stone-ext1/fmridata/AurelieData/Austin_3D.nii.gz'
% <extraflags> (optional) is a string with extra flags to pass to recon-all.
%   Default: ''
% <scanstouse> (optional) is a vector of indices of T1 scans to use.
%   For example, if there are 5 scans, [1 3 5] means to use the 1st, 3rd, and 5th.
%   Default is to use all available.
% <t2nifti> (optional) is a NIFTI T2 .nii.gz file. If you specify this case,
%   <dataloc> must be case (2).
%
% push anatomical data through FreeSurfer.
% see code for assumptions.
%
% history:
% - 2016/11/28 - major update for the new scheme with manual FS edits.

% input
if ~exist('extraflags','var') || isempty(extraflags)
  extraflags = '';
end
if ~exist('scanstouse','var') || isempty(scanstouse)
  scanstouse = [];
end
if ~exist('t2nifti','var') || isempty(t2nifti)
  t2nifti = [];
end

% calc
dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% make subject anatomical directory
assert(mkdir(dir0));

% case 1
if exist(dataloc,'dir')

  % figure out T1 files [ASSUME THAT THERE ARE AN EVEN NUMBER OF DIRECTORIES]
  t1file = matchfiles(sprintf('%s/dicom/*T1w*',dataloc));
  assert(mod(length(t1file),2)==0);
  t1file = t1file(2:2:end);   % [hint: 2nd of each pair is the one that is homogenity-corrected]

        %           % figure out T2 file [ASSUME THAT WE WILL MATCH TWO DIRECTORIES]
        %           t2file = matchfiles(sprintf('%s/*T2w*',dataloc));
        %           assert(mod(length(t2file),2)==0);
        %           t2file = t2file(2:2:end);   % [hint: 2nd of the two is the one to use, as it is homogenity-corrected]

  % convert dicoms to NIFTIs
  for p=1:length(t1file)
    unix_wrapper(sprintf('dcm2nii -o %s -r N -x N %s',dir0,t1file{p}));
  end
        %   assert(0==unix(sprintf('dcm2nii -o %s -r N -x N %s',dir0,t2file)));

  % find the NIFTIs
  t1nifti = matchfiles(sprintf('%s/dicom/*T1w*nii.gz',dir0));
        %   t2nifti = matchfiles(sprintf('%s/*T2w*nii.gz',dir0));
        %assert(length(t1nifti)==1);
        %   assert(length(t2nifti)==1);
        %t1nifti = t1nifti{1};
        %   t2nifti = t2nifti{1};
  assert(isempty(t2nifti));

% case 2
else
  assert(exist(dataloc,'file')~=0);

  % find the NIFTI
  t1nifti = matchfiles(dataloc);
      %assert(length(t1nifti)==1);
      %t1nifti = t1nifti{1};
  if ~isempty(t2nifti)
    t2nifti = matchfiles(t2nifti);
    assert(length(t2nifti)==1);
    t2nifti = t2nifti{1};
  end
  
end

% deal with scanstouse
if isempty(scanstouse)
  scanstouse = 1:length(t1nifti);
end

% call recon-all
str0 = catcell(2,cellfun(@(x) sprintf('-i %s ',x),t1nifti(scanstouse),'UniformOutput',0));  % make a string like '-i first -i second'
if isempty(t2nifti)
  extrat2stuff = '';
else
  extrat2stuff = sprintf('-T2 %s -T2pial',t2nifti);
end
unix_wrapper(sprintf('recon-all -s %s %s %s -all %s > %s/reconlog.txt',subjectid,str0,extrat2stuff,extraflags,dir0));

% convert T1 to NIFTI for external use
unix_wrapper(sprintf('mri_convert %s/mri/T1.mgz %s/mri/T1.nii.gz',fsdir,fsdir));
