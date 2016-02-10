function cvnrunfreesurfer(subjectid,dataloc,extraflags,scanstouse)

% function cvnrunfreesurfer(subjectid,dataloc,extraflags,scanstouse)
%
% <subjectid> is like 'C0001'
% <dataloc> is:
%   (1) the scan directory like '/stone/ext1/fmridata/20151014-ST001-wynn,subject1'
%   (2) a NIFTI T1 .nii.gz file like '/stone/ext1/fmridata/AurelieData/Austin_3D.nii.gz'
% <extraflags> (optional) is a string with extra flags to pass to recon-all.
%   Default: ''
% <scanstouse> (optional) is a vector of indices of T1 scans to use.
%   For example, if there are 5 scans, [1 3 5] means to use the 1st, 3rd, and 5th.
%   Default is to use all available.
%
% push anatomical data through FreeSurfer.
% see code for assumptions.

% input
if ~exist('extraflags','var') || isempty(extraflags)
  extraflags = '';
end
if ~exist('scanstouse','var') || isempty(scanstouse)
  scanstouse = [];
end

% calc
dir0 = sprintf('%s/%s',cvnpath('anatomicals'),subjectid);
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% make subject anatomical directory
assert(mkdir(dir0));

% case 1
if exist(dataloc,'dir')

  % figure out T1 files [ASSUME THAT THERE ARE AN EVEN NUMBER OF DIRECTORIES]
  t1file = matchfiles(sprintf('%s/*T1w*',dataloc));
  assert(mod(length(t1file),2)==0);
  t1file = t1file(2:2:end);   % [hint: 2nd of each pair is the one that is homogenity-corrected]

        %           % figure out T2 file [ASSUME THAT WE WILL MATCH TWO DIRECTORIES]
        %           t2file = matchfiles(sprintf('%s/*T2w*',dataloc));
        %           assert(mod(length(t2file),2)==0);
        %           t2file = t2file(2:2:end);   % [hint: 2nd of the two is the one to use, as it is homogenity-corrected]

  % convert dicoms to NIFTIs
  for p=1:length(t1file)
    assert(0==unix(sprintf('dcm2nii -o %s -r N -x N %s',dir0,t1file{p})));
  end
        %   assert(0==unix(sprintf('dcm2nii -o %s -r N -x N %s',dir0,t2file)));

  % find the NIFTIs
  t1nifti = matchfiles(sprintf('%s/*T1w*nii.gz',dir0));
        %   t2nifti = matchfiles(sprintf('%s/*T2w*nii.gz',dir0));
        %assert(length(t1nifti)==1);
        %   assert(length(t2nifti)==1);
        %t1nifti = t1nifti{1};
        %   t2nifti = t2nifti{1};

% case 2
else
  assert(exist(dataloc,'file')~=0);

  % find the NIFTI
  t1nifti = matchfiles(dataloc);
      %assert(length(t1nifti)==1);
      %t1nifti = t1nifti{1};
  
end

    % do the reconstruction
    % if exist('t2nifti','var')
    %   assert(0==unix(sprintf('recon-all -s %s -i %s -T2 %s -T2pial -all %s > %s/reconlog.txt',subjectid,t1nifti,t2nifti,extraflags,dir0)));
    % else

% deal with scanstouse
if isempty(scanstouse)
  scanstouse = 1:length(t1nifti);
end

% call recon-all
str0 = catcell(2,cellfun(@(x) sprintf('-i %s ',x),t1nifti(scanstouse),'UniformOutput',0));  % make a string like '-i first -i second'
assert(0==unix(sprintf('recon-all -s %s %s -all %s > %s/reconlog.txt',subjectid,str0,extraflags,dir0)));

% end

%%%%% convert T1 to NIFTI for external use

assert(0==unix(sprintf('mri_convert %s/mri/T1.mgz %s/mri/T1.nii.gz',fsdir,fsdir)));

%%%%% convert some miscellaneous files

% convert .thickness files to ASCII
assert(0==unix(sprintf('mris_convert -c %s/surf/lh.thickness %s/surf/lh.white %s/surf/lh.thickness.asc',fsdir,fsdir,fsdir)));
assert(0==unix(sprintf('mris_convert -c %s/surf/rh.thickness %s/surf/rh.white %s/surf/rh.thickness.asc',fsdir,fsdir,fsdir)));

% convert .curv files to ASCII
assert(0==unix(sprintf('mris_convert -c %s/surf/lh.curv %s/surf/lh.white %s/surf/lh.curv.asc',fsdir,fsdir,fsdir)));
assert(0==unix(sprintf('mris_convert -c %s/surf/rh.curv %s/surf/rh.white %s/surf/rh.curv.asc',fsdir,fsdir,fsdir)));

%%%%% make mid-gray surface

assert(0==unix(sprintf('mris_expand -thickness %s/surf/lh.white 0.5 %s/surf/lh.graymid',fsdir,fsdir)));
assert(0==unix(sprintf('mris_expand -thickness %s/surf/rh.white 0.5 %s/surf/rh.graymid',fsdir,fsdir)));

%%%%% consolidate mid-gray surface stuff into a .mat file

prefixes = {'lh' 'rh'};
for p=1:length(prefixes)
  prefix0 = prefixes{p};

  % read .graymid surface
  [vertices,faces] = freesurfer_read_surf_kj(sprintf('%s/surf/%s.graymid',fsdir,prefix0));

  % construct vertices (4 x V)
  vertices = bsxfun(@plus,vertices',[128; 129; 128]);  % NOTICE THIS!!!
  vertices(4,:) = 1;

  % construct faces (F x 3)
  faces = faces(:,[1 3 2]);  % necessary to convert freesurfer to matlab

  % load auxiliary info (V x 1)
  thickness = subscript(load(sprintf('%s/surf/%s.thickness.asc',fsdir,prefix0)),{':' 5});
  curvature = subscript(load(sprintf('%s/surf/%s.curv.asc',fsdir,prefix0)),     {':' 5});

  % get freesurfer labels (fslabels is V x 1)
  [d,fslabels,colortable] = read_annotation(sprintf('%s/label/%s.aparc.annot',fsdir,prefix0),1);

  % save
  save(sprintf('%s/%s/%smidgray.mat',cvnpath('anatomicals',subjectid,prefix0), ...
       'vertices','faces','thickness','curvature','fslabels');

end

%%%%% calculate gray-matter information

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

%%%%% calculate transfer functions

% calc
[tfunFSSSlh,tfunFSSSrh,tfunSSFSlh,tfunSSFSrh] = ...
  cvncalctransferfunctions([cvnpath('freesurfer') '/fsaverage/surf/lh.sphere.reg'], ...
                           [cvnpath('freesurfer') '/fsaverage/surf/rh.sphere.reg'], ...
                           sprintf('%s/%s/surf/lh.sphere.reg',cvnpath('freesurfer'),subjectid), ...
                           sprintf('%s/%s/surf/rh.sphere.reg',cvnpath('freesurfer'),subjectid));

% save
save(sprintf('%s/%s/tfun.mat',cvnpath('anatomicals'),subjectid),'tfunFSSSlh','tfunFSSSrh','tfunSSFSlh','tfunSSFSrh');
