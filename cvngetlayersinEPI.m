function f = cvngetlayersinEPI(subjectid,datadir,numlayers,layerprefix,fstruncate,alignmentdir,mode)

% function f = cvngetlayersinEPI(subjectid,datadir,numlayers,layerprefix,fstruncate,alignmentdir,mode)
%
% <subjectid> is like 'C0001'
% <datadir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test'
% <numlayers> is like 6 or [] (indicating graymid)
% <layerprefix> is like 'A' (only matters if <numlayers> is not [])
% <fstruncate' is like 'pt' (only matters if <numlayers> is not [])
%   if [], we do not do "DENSETRUNC" surfaces.
% <alignmentdir> (optional) is like 'freesurferalignment' (default)
% <mode> (optional) is
%   0 means original interpretation of FS volumes (heuristic and slighly inaccurate)
%   1 means new interpretation of FS volumes (based on vox2ras-tkr)
%   Default: 0.
%
% Based on an existing EPI alignment (<alignmentdir>/alignment.mat),
% return the locations of the vertices (4 x V) in the EPI space.
%
% We return vertices concatenated in the following order:
%   if <numlayers>,<layerprefix>,<fstruncate> are specified:
%     lh.layerA1DENSETRUNCpt
%     rh.layerA1DENSETRUNCpt
%     lh.layerA2DENSETRUNCpt
%     rh.layerA2DENSETRUNCpt
%       etc.
% OR
%   if <numlayers> is []:
%     lh.graymid
%     rh.graymid
% OR
%   if <numlayers>,<layerprefix> are specified:
%     lh.layerA1
%     rh.layerA1
%     lh.layerA2
%     rh.layerA2
%       etc.
%
% History:
% - 2020/05/09 - update (mode==1) to use vox2ras-tkr instead of the previous method (which was slightly inaccurate)

% input
if ~exist('alignmentdir','var') || isempty(alignmentdir)
  alignmentdir = 'freesurferalignment';
end
if ~exist('mode','var') || isempty(mode)
  mode = 0;
end

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
prefixes = {'lh' 'rh'};
if isempty(numlayers)
  surfs = {'graymid'};
else
  surfs = {};
  for p=1:numlayers
    if isempty(fstruncate)
      surfs{p} = sprintf('layer%s%d',layerprefix,p);                         % layers
    else
      surfs{p} = sprintf('layer%s%dDENSETRUNC%s',layerprefix,p,fstruncate);  % layers, dense, truncated
    end
  end
end

% load transformation
load(sprintf('%s/%s/alignment.mat',datadir,alignmentdir),'tr');

% derive FS-related transforms
if mode==1
  [status,result] = unix(sprintf('mri_info --vox2ras-tkr %s/mri/T1.mgz',fsdir)); assert(status==0);
  Torig = eval(['[' result ']']);  % vox2ras-tkr
  t1vol = cvnloadmgz(sprintf('%s/mri/T1.mgz',fsdir));
  assert(all(diff(size(t1vol))==0));
end

% load surfaces
vertices = {};
for p=1:length(prefixes)
  for q=1:length(surfs)
    switch mode
    case 0
      vertices{p,q} = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,prefixes{p},surfs{q}));
      vertices{p,q} = bsxfun(@plus,vertices{p,q}',[128; 129; 128]);  % NOTICE THIS!!!
      vertices{p,q}(4,:) = 1;  % now: 4 x V
    case 1
      vertices{p,q} = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,prefixes{p},surfs{q}))';  % 3 x V
      vertices{p,q}(4,:) = 1;
      vertices{p,q} = inv(Torig)*vertices{p,q};  % map from rastkr to vox (this is 0-based where 0 is center of first voxel)
      vertices{p,q}(1:3,:) = vertices{p,q}(1:3,:) + 1;  % now 1-based
      vertices{p,q}(1:3,:) = (vertices{p,q}(1:3,:) - 0.5) / size(t1vol,1) * 256 + 0.5;  % change to matrix space for 256x256x256
    end
  end
end

% calculate the final vertex locations
f = volumetoslices(catcell(2,vertices),tr);  % take vertices to EPI space
