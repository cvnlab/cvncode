function vertices = cvnreadsurfaceintovox(subjectid,numlayers,layerprefix,fstruncate)

% function vertices = cvnreadsurfaceintovox(subjectid,numlayers,layerprefix,fstruncate)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6 or [] (indicating graymid)
% <layerprefix> is like 'A' (only matters if <numlayers> is not [])
% <fstruncate' is like 'pt' (only matters if <numlayers> is not [])
%   if [], we do not do "DENSETRUNC" surfaces.
%
% Return the locations of the vertices (4 x V) in voxel space (0-based).
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

% derive FS-related transforms
[status,result] = unix(sprintf('mri_info --vox2ras-tkr %s/mri/T1.mgz',fsdir)); assert(status==0);
Torig = eval(['[' result ']']);  % vox2ras-tkr
t1vol = cvnloadmgz(sprintf('%s/mri/T1.mgz',fsdir));
assert(all(diff(size(t1vol))==0));

% load surfaces
vertices = {};
for p=1:length(prefixes)
  for q=1:length(surfs)
    vertices{p,q} = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,prefixes{p},surfs{q}))';  % 3 x V
    vertices{p,q}(4,:) = 1;
    vertices{p,q} = inv(Torig)*vertices{p,q};  % map from rastkr to vox (this is 0-based where 0 is center of first voxel)
  end
end

% output
vertices = catcell(2,vertices);
