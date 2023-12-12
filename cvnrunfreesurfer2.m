function cvnrunfreesurfer2(subjectid,extraflags)

% function cvnrunfreesurfer2(subjectid,extraflags)
%
% <subjectid> is like 'C0001'
% <extraflags> (optional) is a string with extra flags to pass to recon-all.
%   Default: ''
%
% This is part 2/2 for pushing anatomical data through FreeSurfer.
% see code for assumptions.

% input
if ~exist('extraflags','var') || isempty(extraflags)
  extraflags = '';
end

% calc
dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% make subject anatomical directory
assert(mkdir(dir0));

%%%%% convert some miscellaneous files

% convert .thickness files to ASCII
unix_wrapper(sprintf('mris_convert -c %s/surf/lh.thickness %s/surf/lh.white %s/surf/lh.thickness.asc',fsdir,fsdir,fsdir));
unix_wrapper(sprintf('mris_convert -c %s/surf/rh.thickness %s/surf/rh.white %s/surf/rh.thickness.asc',fsdir,fsdir,fsdir));

% convert .curv files to ASCII
unix_wrapper(sprintf('mris_convert -c %s/surf/lh.curv %s/surf/lh.white %s/surf/lh.curv.asc',fsdir,fsdir,fsdir));
unix_wrapper(sprintf('mris_convert -c %s/surf/rh.curv %s/surf/rh.white %s/surf/rh.curv.asc',fsdir,fsdir,fsdir));

%%%%% make mid-gray surface

unix_wrapper(sprintf('mris_expand -thickness %s/surf/lh.white 0.5 %s/surf/lh.graymid',fsdir,fsdir));
unix_wrapper(sprintf('mris_expand -thickness %s/surf/rh.white 0.5 %s/surf/rh.graymid',fsdir,fsdir));

%%%%% consolidate mid-gray surface stuff into a .mat file

prefixes = {'lh' 'rh'};
for p=1:length(prefixes)
  prefix0 = prefixes{p};

  % read .graymid surface
  [vertices,faces] = freesurfer_read_surf_kj(sprintf('%s/surf/%s.graymid',fsdir,prefix0));

  % construct vertices (4 x V)
  vertices = bsxfun(@plus,vertices',[128; 129; 128]);  % NOTICE THIS!!! THIS IS NOT QUITE RIGHT. see cvncheckfreesurfer.m
  vertices(4,:) = 1;

  % NOTE: THIS MIDGRAY.MAT FILE IS DEPRECATED ANYWAY, SO WE WILL NOT FIX THIS VERTEX TRANSFORMATION ISSUE

  % construct faces (F x 3)
  faces = faces(:,[1 3 2]);  % necessary to convert freesurfer to matlab

  % load auxiliary info (V x 1)
  thickness = subscript(load(sprintf('%s/surf/%s.thickness.asc',fsdir,prefix0)),{':' 5});
  curvature = subscript(load(sprintf('%s/surf/%s.curv.asc',fsdir,prefix0)),     {':' 5});

  % get freesurfer labels (fslabels is V x 1)
  [d,fslabels,colortable] = read_annotation(sprintf('%s/label/%s.aparc.annot',fsdir,prefix0),1);

  % REMOVED vertices from the save below on Oct 28 2023, because
  % it is wrong (see above) and since this is obsolete probably anyway.

  % save
  save(sprintf('%s/%s/%smidgray.mat',cvnpath('anatomicals'),subjectid,prefix0), ...
       'faces','thickness','curvature','fslabels');

end

%%%%% calculate gray-matter information

if 0  % HACKED THIS OUT ON Oct 28 2023, since vertices is wrong (see above) and since this is obsolete anyway
if isempty(regexp(extraflags,'hires'))

  % load ribbon
  [rib,M,mr_parms,volsz] = load_mgh(sprintf('%s/mri/ribbon.mgz',fsdir));
  rib = fstoint(rib);

  % load coordinates of surface vertices
  coord0 = cat(2,loadmulti(sprintf('%s/%s/lhmidgray.mat',cvnpath('anatomicals'),subjectid),'vertices'), ...
                 loadmulti(sprintf('%s/%s/rhmidgray.mat',cvnpath('anatomicals'),subjectid),'vertices'));

  % compute distances to vertices [i.e. create a volume where gray matter voxels have certain informative values]
  [dist,mnix] = surfaceslice2(ismember(rib,[3 42]),coord0,3,4);  % NOTICE HARD-CODED VALUES HERE

  % save
    % 1-mm volume with, for each gray matter voxel, distance to closest vertex (of mid-gray surface)
  save_mgh(inttofs(dist),sprintf('%s/mri/ribbonsurfdist.mgz' ,fsdir),M,mr_parms);
    % 1-mm volume with, for each gray matter voxel, index of closest vertex (of mid-gray surface)
  save_mgh(inttofs(mnix),sprintf('%s/mri/ribbonsurfindex.mgz',fsdir),M,mr_parms);

end
end

%%%%% calculate transfer functions

% calc
[tfunFSSSlh,tfunFSSSrh,tfunSSFSlh,tfunSSFSrh] = ...
  cvncalctransferfunctions([cvnpath('freesurfer') '/fsaverage/surf/lh.sphere.reg'], ...
                           [cvnpath('freesurfer') '/fsaverage/surf/rh.sphere.reg'], ...
                           sprintf('%s/%s/surf/lh.sphere.reg',cvnpath('freesurfer'),subjectid), ...
                           sprintf('%s/%s/surf/rh.sphere.reg',cvnpath('freesurfer'),subjectid));

% save
save(sprintf('%s/%s/tfun.mat',cvnpath('anatomicals'),subjectid),'tfunFSSSlh','tfunFSSSrh','tfunSSFSlh','tfunSSFSrh');

%%%%% write out some useful mgz files (inherited from cvnmakelayers.m)

% calc
hemis = {'lh' 'rh'};

% do it
for p=1:length(hemis)

  % load
  a1 = load(sprintf('%s/%smidgray.mat',dir0,hemis{p}));
  a3 = read_curv(sprintf('%s/surf/%s.sulc',fsdir,hemis{p}));

  % write mgz
  cvnwritemgz(subjectid,'thickness',a1.thickness,hemis{p});
  cvnwritemgz(subjectid,'curvature',a1.curvature,hemis{p});
  cvnwritemgz(subjectid,'sulc',     a3,          hemis{p});

end
