function files = cvncollectT1s(subjectid,dataloc,gradfile,str0,wantskip)

% function files = cvncollectT1s(subjectid,dataloc,gradfile,str0,wantskip)
%
% <subjectid> is like 'C0001'
% <dataloc> is a scan directory like '/home/stone-ext1/fmridata/20151014-ST001-wynn,subject1'
%   or a cell vector of scan directories
% <gradfile> (optional) is gradunwarp's scanner or coeff file (e.g. 'prisma').
%   Default is [] which means do not perform gradunwarp.
% <str0> (optional) is the filename match thing. Default: 'T1w'.
% <wantskip> (optional) is whether to treat as pairs and use the second of each pair.
%   (The idea is that the second of each pair might be homogeneity-corrected.)
%   Default: 1.
%
% Within the specified scan directories (in the order as given), 
% find all of the T1 (or whatever) DICOM directories, and if <wantskip>,
% ignoring the 1st of each pair and keeping the 2nd of each pair.
% Then convert these DICOM directories to NIFTI files.  
% If <gradfile> is specified, we additionally run fslreorient2std
% and gradunwarp.
%
% We return a cell vector of the final NIFTI filenames,
% preserving the order. Note that filenames will be different
% depending on whether <gradfile> is used.
%
% See code for specific assumptions.
% Turn on matlabpool before calling for speed-ups!
%
% history:
% - 2016/10/31 - add <wantskip>
% - 2016/06/03 - add <str0> input; load from the dicom directory
% - 2016/05/29 - add support for <gradfile>

% input
if ~exist('gradfile','var') || isempty(gradfile)
  gradfile = [];
end
if ~exist('str0','var') || isempty(str0)
  str0 = 'T1w';
end
if ~exist('wantskip','var') || isempty(wantskip)
  wantskip = 1;
end

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
  t1files0 = matchfiles(sprintf('%s/dicom/*%s*',dataloc{p},str0));
  if wantskip
    assert(mod(length(t1files0),2)==0);
    t1files0 = t1files0(2:2:end);   % [hint: 2nd of each pair is the one that is homogenity-corrected]
  end
  
  % collect them up
  t1files = [t1files t1files0];

end

% convert dicoms to NIFTIs and get the filenames
files = {};
for p=1:length(t1files)
  result = unix_wrapper(sprintf('dcm2nii -o %s -r N -x N %s',dir0,t1files{p}));
  temp = regexp(result,'GZip\.\.\.(.+)','tokens');
  files{p} = [dir0 '/' temp{1}{1}];
end

% get rid of dumb whitespace from filenames
for p=1:length(files)
  files{p} = regexprep(files{p},'^\s+','');
  files{p} = regexprep(files{p},'\s+$','');
end

% perform gradunwarp
if ~isempty(gradfile)

  % run Keith's fslreorient2std on each
  for p=1:length(files)
    unix_wrapper(sprintf('fslreorient2std_inplace %s',files{p}));
  end
  
  % then do the gradunwarp
  newfiles = {};
  parfor p=1:length(files)
  
    % figure out the filename prefix (without the .nii.gz)
    file0 = files{p};
    assert(isequal(file0(end-6:end),'.nii.gz'));
    file0 = file0(1:end-7);

    % call it
    unix_wrapper(sprintf('gradunwarp -w %s_warp.nii.gz -m %s_mask.nii.gz %s.nii.gz %s_gradunwarped.nii.gz %s',file0,file0,file0,file0,gradfile));
    
    % record the new filename
    newfiles{p} = [file0 '_gradunwarped.nii.gz'];

  end
  
  % use the new filenames
  files = newfiles;

end
