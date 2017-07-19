function f = cvngetlayersinEPI(subjectid,datadir,numlayers,layerprefix,fstruncate)

% function f = cvngetlayersinEPI(subjectid,datadir,numlayers,layerprefix,fstruncate)
%
% <subjectid> is like 'C0001'
% <datadir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test'
% <numlayers> is like 6       or [] (indicating graymid)
% <layerprefix> is like 'A'   or [] (indicating graymid)
% <fstruncate' is like 'pt'   or [] (indicating graymid)
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
% OR
%   lh.graymid
%   rh.graymid

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
prefixes = {'lh' 'rh'};
if isempty(numlayers)
  surfs = {'graymid'};
else
  surfs = {};
  for p=1:numlayers
    surfs{p} = sprintf('layer%s%dDENSETRUNC%s',layerprefix,p,fstruncate);  % six layers, dense, truncated
  end
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
