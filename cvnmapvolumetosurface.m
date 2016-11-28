function cvnmapvolumetosurface(subjectid,numlayers,layerprefix,fstruncate,volfiles,names,datafun)

% function cvnmapvolumetosurface(subjectid,numlayers,layerprefix,fstruncate,volfiles,names,datafun)
%
% <subjectid> is like 'C0051'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate' is like 'pt'
% <volfiles> is a wildcard or cell vector matching one or more NIFTI files. can also be raw matrices.
% <names> is a string (or cell vector of strings) to be used as prefixes in output filenames.
%   There should be a 1-to-1 correspondence between <volfiles> and <names>.
% <datafun> (optional) is a function (or cell vector of functions) to apply to the data 
%   right after loading them in. If you pass only one function, we apply that function
%   to each volume.
%
% Use cubic interpolation to transfer the volume data in <volfiles> onto the layer 
% surfaces (e.g. layerA1-A6) as well as the white and pial surfaces.
% Save the results as .mgz files.
%
% The volumes in <volfiles> are assumed to be in our standard FreeSurfer 
% 320 x 320 x 320 0.8-mm space.

% internal constants [NOTE!!!]
fsres = 256;
newres = 320;

% input
if ~exist('datafun','var') || isempty(datafun)
  datafun = @(x) x;
end
if ~iscell(names)
  names = {names};
end

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
hemis = {'lh' 'rh'};

% figure out surface names
surfs = {}; surfsB = {};
for p=1:numlayers
  surfs{p} =  sprintf('layer%s%dDENSETRUNC%s', layerprefix,p,fstruncate);  % six layers, dense, truncated
  surfsB{p} = sprintf('layer%s%d_DENSETRUNC%s',layerprefix,p,fstruncate);  % six layers, dense, truncated
end
surfs{end+1} =  sprintf('whiteDENSETRUNC%s', fstruncate);  % white
surfsB{end+1} = sprintf('white_DENSETRUNC%s',fstruncate);  % white
surfs{end+1} =  sprintf('pialDENSETRUNC%s', fstruncate);   % pial
surfsB{end+1} = sprintf('pial_DENSETRUNC%s',fstruncate);   % pial

% load surfaces
vertices = {};
for p=1:length(hemis)
  for q=1:length(surfs)
    vertices{p,q} = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,hemis{p},surfs{q}));
    vertices{p,q} = bsxfun(@plus,vertices{p,q}',[128; 129; 128]);  % NOTICE THIS!!!
    vertices{p,q} = (vertices{p,q} - .5)/fsres * newres + .5;  % DEAL WITH DIFFERENT RESOLUTION
    vertices{p,q}(4,:) = 1;  % now: 4 x V
  end
end

% load volumes
data = cvnloadstandardnifti(volfiles);
assert(isequal(sizefull(data,3),[newres newres newres]));  % sanity check
assert(size(data,4)==length(names));                       % sanity check

% expand datafun
if ~iscell(datafun)
  datafun = {datafun};
end
if length(datafun)==1
  datafun = repmat(datafun,[1 size(data,4)]);
end

% interpolate volume onto surface and save .mgz file
for p=1:size(data,4)
  tempdata = feval(datafun{p},data(:,:,:,p));
  for q=1:length(hemis)
    for r=1:length(surfs)
      temp = ba_interp3_wrapper(tempdata,vertices{q,r}(1:3,:),'cubic');
      cvnwritemgz(subjectid,sprintf('%s_%s',names{p},surfsB{r}),temp,hemis{q});
    end
  end
end
