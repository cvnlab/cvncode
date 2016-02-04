function f = cvngetlayersinEPI(subjectid,datadir,numlayers,layerprefix,fstruncate)

% function f = cvngetlayersinEPI(subjectid,datadir,numlayers,layerprefix,fstruncate)
%
% <subjectid> is like 'C0001'
% <datadir> is like '/stone/ext1/fmridata/20151008-ST001-kk,test'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate' is like 'pt'
%
% Based on an existing EPI alignment (freesurferalignment/alignment.mat),
% return the locations of the vertices (4 x V) in the EPI space.
%
% We return vertices concatenated in the following order:
%   lh.layerA1DENSETRUNCpt
%   rh.layerA1DENSETRUNCpt
%   lh.layerA2DENSETRUNCpt
%   rh.layerA2DENSETRUNCpt
%     etc.

% calc
fsdir = sprintf('/software/freesurfer/subjects/%s',subjectid);
prefixes = {'lh' 'rh'};
surfs = {};
for p=1:numlayers
  surfs{p} = sprintf('layer%s%dDENSETRUNC%s',layerprefix,p,fstruncate);  % six layers, dense, truncated
end

% load transformation
load(sprintf('%s/freesurferalignment/alignment.mat',datadir),'tr');

% load surfaces
vertices = {};
for p=1:length(prefixes)
  for q=1:length(surfs)
    vertices{p,q} = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,prefixes{p},surfs{q}));
    vertices{p,q} = bsxfun(@plus,vertices{p,q}',[128; 129; 128]);  % NOTICE THIS!!!
    vertices{p,q}(4,:) = 1;  % now: 4 x V
  end
end

% calculate the final vertex locations
f = volumetoslices(catcell(2,vertices),tr);  % take vertices to EPI space
