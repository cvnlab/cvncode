function cvntransferatlastovolume(subjectid,fsmap,hemi,outfile,fun)

% function cvntransferatlastovolume(subjectid,fsmap,hemi,outfile,fun)
%
% <subjectid> is like 'C0001'
% <fsmap> is the fsaverage surface file like '/software/freesurfer/fsaveragemaps/KayDataFFA1-RH.mgz'
% <hemi> is 'lh' or 'rh' indicating whether the surface file is left or right hemisphere
% <outfile> is the destination NIFTI file to write, like
%   '/software/freesurfer/subjects/C0001/mri/rois/KayDataFFA1-RH.nii.gz'
% <fun> (optional) is a function to apply to <fsmap> before writing the NIFTI.
%   Default is to do nothing (use values as-is).
%
% Take the <fsmap> file, apply <fun>, and then transfer to single-subject surface space
% using nearest-neighbor interpolation.  Values in the other hemisphere are just set to 0.
% Then, convert to a 1-mm volume where each gray-matter voxel is given the value 
% associated with the nearest vertex (of the mid-gray surface).  (Non-gray-matter is
% set to 0.)  We write the result in the same format as the subject's T1.nii.gz.
% Note that explicitly convert the output values to int16 before writing.

% internal constants
fsnumv = 163842;  % vertices

% input
if ~exist('fun','var') || isempty(fun)
  fun = @(x) x;
end

% calc
fsdir = sprintf('/software/freesurfer/subjects/%s',subjectid);

% load transfer functions
load(sprintf('/stone/ext1/anatomicals/%s/tfun.mat',subjectid));

% load gray-matter surface assignment (1-mm space)
gmsa = fstoint(load_mgh(sprintf('%s/mri/ribbonsurfindex.mgz',fsdir)));

% load fsaverage map
vals = flatten(load_mgh(fsmap));  % 1 x 163842
assert(length(vals)==fsnumv);

% apply fun and expand map into full format (1 x 2*163842)
if isequal(hemi,'rh')
  vals = [zeros(1,fsnumv) fun(vals)];
else
  vals = [fun(vals) zeros(1,fsnumv)];
end

% transfer to single subject space (using nearest neighbor interpolation)
vals = [tfunFSSSlh(vals) tfunFSSSrh(vals)];  % 1 x allvertices

% convert from surface to volume
  % vals is a 1-mm volume.  non-gray-matter voxels are left at 0.
  % each gray-matter voxel is given the value associated with the vertex
  % (on the mid-gray surface) that is closest to the voxel.
bad = isnan(gmsa);
gmsa(bad) = 1;
vals = vals(gmsa);
vals(bad) = 0;

% load subject's T1 (so that we can be sure to save in the same format)
n1 = load_nii(gunziptemp(sprintf('%s/mri/T1.nii.gz',fsdir)));
  % save_nii(n1,sprintf('~/inout/%s.nii.gz',subjectid));  % testing purposes

% make destination directory if necessary
mkdirquiet(stripfile(outfile));

% save NIFTI file, mangling the T1 values with the values we want
save_nii(setfield(n1,'img',int16(vals)),outfile);
