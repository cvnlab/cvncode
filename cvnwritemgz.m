function cvnwritemgz(subjectid,name,vals,hemi,outputdir,surfsuffix)

% function cvnwritemgz(subjectid,name,vals,hemi,outputdir,surfsuffix)
%
% <subjectid> is like 'C0041' (can be 'fsaverage')
% <name> is a string
% <vals> is a vector of values for the surface
% <hemi> is 'lh' or 'rh'
% <outputdir> (optional) is the directory to write the file to.
%   Default is cvnpath('freesurfer')/<subjectid>/surf/
% <surfsuffix> (optional) is a suffix to tack onto <hemi>, e.g., 'DENSETRUNCpt'.
%   Special case is 'orig' which is equivalent to ''.
%   Default: 'orig'.
%
% Write a file like <hemi><surfsuffix>.<name>.mgz.
% 
% Note that we make certain assumptions about what fields to mangle (see code).

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% input
if ~exist('outputdir','var') || isempty(outputdir)
  outputdir = sprintf('%s/surf',fsdir);
end
if ~exist('surfsuffix','var') || isempty(surfsuffix)
  surfsuffix = 'orig';
end

% prep
mkdirquiet(outputdir);

% load template
file0 = sprintf('%s/surf/%s.w-g.pct.mgh',fsdir,hemi(1:2));
if ~exist(file0,'file')  % fsaverage doesn't have the above file, so let's use this one:
  file0 = sprintf('%s/surf/%s.orig.avg.area.mgh',fsdir,hemi(1:2));
end
fsmgh = MRIread(file0);

% calc
if isequal(surfsuffix,'orig')
  suffstr = '';
else
  suffstr = surfsuffix;
end
file = sprintf('%s/%s%s.%s.mgz',outputdir,hemi,suffstr,name);
n = numel(vals);

% mangle
fsmgh.fspec = file;
fsmgh.vol = flatten(vals);
fsmgh.volsize = [1 n 1];
fsmgh.width = n;
fsmgh.nvoxels = n;

% write
MRIwrite(fsmgh,file);

%%%%%%%%%%%%%%%%%%

% % load truncate if supplied
% if ~isempty(fstruncate)
%   a1 = load(sprintf('%s/surf/%s.DENSETRUNC%s.mat',fsdir,hemi,fstruncate));
%   a1.validix
% end
