function files = cvncollectT1s(subjectid,dataloc)

% function files = cvncollectT1s(subjectid,dataloc)
%
% <subjectid> is like 'C0001'
% <dataloc> is a scan directory like '/stone/ext1/fmridata/20151014-ST001-wynn,subject1'
%   or a cell vector of scan directories
%
% Within the specified scan directories (in the order as given), 
% find all of the T1 DICOM directories, ignoring the 1st of each pair
% and keeping the 2nd of each pair. Then convert these DICOM directories
% to NIFTI files and return a cell vector of the resulting NIFTI filenames,
% preserving the order. See code for specific assumptions.

% calc
dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);

% make subject anatomical directory
assert(mkdir(dir0));

% massage
if ~iscell(dataloc)
  dataloc = {dataloc};
end

% figure out T1 DICOM directories [ASSUME THAT THERE ARE AN EVEN NUMBER OF DIRECTORIES IN EACH SCAN SESSION]
t1files = {};
for p=1:length(dataloc)

  % match the files
  t1files0 = matchfiles(sprintf('%s/*T1w*',dataloc{p}));
  assert(mod(length(t1files0),2)==0);
  t1files0 = t1files0(2:2:end);   % [hint: 2nd of each pair is the one that is homogenity-corrected]
  
  % collect them up
  t1files = [t1files t1files0];

end

% convert dicoms to NIFTIs and get the filenames
files = {};
for p=1:length(t1files)
  [status,result] = unix(sprintf('dcm2nii -o %s -r N -x N %s',dir0,t1files{p}));
  assert(status==0);
  temp = regexp(result,'GZip\.\.\.(.+)','tokens');
  files{p} = [dir0 '/' temp{1}{1}];
end
