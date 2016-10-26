function cvntransferatlastosurface(subjectid,fsmap,hemi,outpre,fstruncate,fun,outputdir)

% function cvntransferatlastosurface(subjectid,fsmap,hemi,outpre,fstruncate,fun,outputdir)
%
% <subjectid> is like 'C0001'
% <fsmap> is the fsaverage surface file like '/software/freesurfer/fsaveragemaps/KayDataFFA1-RH.mgz'
% <hemi> is 'lh' or 'rh' indicating whether the surface file is left or right hemisphere
% <outpre> is the prefix of the destination .mgz files to write, like 'KayDataFFA1'
% <fstruncate> is the name of the truncation surface in fsaverage
% <fun> (optional) is a function to apply to <fsmap> after loading it.
%   Default is to do nothing (use values as-is).
% <outputdir> (optional) is the directory to write the .mgz files to.
%   Default is cvnpath('freesurfer')/<subjectid>/label/
%
% Take the <fsmap> file, apply <fun>, and then transfer to single-subject surface space
% using nearest-neighbor interpolation.  Values in the other hemisphere are just set to 0.
%
% We write three versions:
% (1) <hemi>.<outpre>.mgz - standard (non-dense) surface
% (2) <hemi>DENSE.<outpre>.mgz - dense surface
% (3) <hemi>DENSETRUNC<fstruncate>.<outpre>.mgz - dense, truncated surface

% NOTES FROM KEITH:
% Cvnroimask looks for label/rh[DENSE|DENSETRUNCpt].roiname.(mgz|mgh|label|annot)
% For multi-label files the label names are contained in a file called
%   label/rh[DENSE|DENSETRUNCpt].roiname.(mgz|mgh|label|annot).ctab
% Or possibly without the rh|lh

% internal constants
fsnumv = 163842;  % vertices

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% input
if ~exist('fun','var') || isempty(fun)
  fun = @(x) x;
end
if ~exist('outputdir','var') || isempty(outputdir)
  outputdir = sprintf('%s/label',fsdir);
end

% load transfer functions
a1 = load(sprintf('%s/%s/tfun.mat',     cvnpath('anatomicals'),subjectid));
a2 = load(sprintf('%s/%s/tfunDENSE.mat',cvnpath('anatomicals'),subjectid));

% load truncation indices
a3 = load(sprintf('%s/surf/%s.DENSETRUNC%s.mat',fsdir,hemi,fstruncate));  % contains 'validix'

% load fsaverage map
vals = flatten(load_mgh(fsmap));  % 1 x 163842
assert(length(vals)==fsnumv);

% apply fun and expand map into full format (1 x 2*163842)
if isequal(hemi,'rh')
  vals = [zeros(1,fsnumv) fun(vals)];
else
  vals = [fun(vals) zeros(1,fsnumv)];
end

% make destination directory if necessary
mkdirquiet(outputdir);

%%%%% STANDARD CASE (NON-DENSE)

% transfer to single subject space (using nearest neighbor interpolation)
if isequal(hemi,'rh')
  vals0 = a1.tfunFSSSrh(vals);
else
  vals0 = a1.tfunFSSSlh(vals);
end

% write mgz
cvnwritemgz(subjectid,outpre,vals0,hemi,outputdir);

%%%%% DENSE CASES (DENSE ON THE SPHERE; ALSO TRUNCATED VERSION)

% transfer to single subject space (using nearest neighbor interpolation)
if isequal(hemi,'rh')
  vals0 = a2.tfunFSSSrh(vals);
else
  vals0 = a2.tfunFSSSlh(vals);
end

% write mgz
cvnwritemgz(subjectid,outpre,vals0,[hemi 'DENSE'],outputdir);

% write mgz (truncated)
cvnwritemgz(subjectid,outpre,vals0(a3.validix),[hemi 'DENSETRUNC' fstruncate],outputdir);
