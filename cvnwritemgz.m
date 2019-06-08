function fsmgh = cvnwritemgz(subjectid,name,vals,hemi,outputdir,surfsuffix,fsmgh)

% function cvnwritemgz(subjectid,name,vals,hemi,outputdir,surfsuffix)
%
% <subjectid> is like 'C0041' (can be 'fsaverage')
%   can also be a full path to the FreeSurfer subject directory.
% <name> is a string
% <vals> is a vector of values (1 x V) for the surface.
%   can also be multiple vectors (D x V).
% <hemi> is 'lh' or 'rh'
% <outputdir> (optional) is the directory to write the file to.
%   Default is cvnpath('freesurfer')/<subjectid>/surf/
% <surfsuffix> (optional) is a suffix to tack onto <hemi>, e.g., 'DENSETRUNCpt'.
%   Special case is 'orig' which is equivalent to using a suffix of ''.
%   Default: 'orig'.
%
% Write a file like <hemi><surfsuffix>.<name>.mgz.
% 
% Note that we make certain assumptions about what fields to mangle (see code).

% history:
% - 2019/06/08 - update to be compatible with multiple datasets in one file;
%                add some more fields to ensure maximum compatibility.

% calc
if ~isempty(regexp(subjectid,filesep))
  fsdir = subjectid;
else
  fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
end

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
if ~(exist('fsmgh','var') && ~isempty(fsmgh))
  file0 = sprintf('%s/surf/%s.w-g.pct.mgh',fsdir,hemi(1:2));
  if ~exist(file0,'file')  % fsaverage doesn't have the above file, so let's use this one:
    file0 = sprintf('%s/surf/%s.orig.avg.area.mgh',fsdir,hemi(1:2));
  end
  fsmgh = MRIread(file0);
end

% calc
if isequal(surfsuffix,'orig')
  suffstr = '';
else
  suffstr = surfsuffix;
end
file = sprintf('%s/%s%s.%s.mgz',outputdir,hemi,suffstr,name);
d = size(vals,1);
v = size(vals,2);

% sanity check
if v==1
  error('<vals> should have data oriented along the rows');
end

% mangle fields
fsmgh.fspec = file;
fsmgh.vol = reshape(permute(vals,[2 1]),1,v,1,d);  % 1 x V x 1 x D
fsmgh.volsize = [1 v 1];
fsmgh.height = 1;
fsmgh.width = v;
fsmgh.depth = 1;
fsmgh.nframes = d;
fsmgh.nvoxels = v;

% write
MRIwrite(fsmgh,file);

%%%%%%%%%%%%%%%%%%

% % load truncate if supplied
% if ~isempty(fstruncate)
%   a1 = load(sprintf('%s/surf/%s.DENSETRUNC%s.mat',fsdir,hemi,fstruncate));
%   a1.validix
% end
