function cvnmapvolumetosurface(subjectid,numlayers,layerprefix,fstruncate, ...
  volfiles,names,datafun,specialmm,interptype,alignfile,outputdir)

% function cvnmapvolumetosurface(subjectid,numlayers,layerprefix,fstruncate, ...
%   volfiles,names,datafun,specialmm,interptype,alignfile,outputdir)
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
% <specialmm> (optional) is
%   0 means do the usual thing
%   N means interpret the matrices in <volfiles> as having a voxel size of N mm.
%     can be a vector of different mm numbers. when the N (or vector) case is used,
%     <volfiles> should be a matrix or cell vector of matrices.
%   Default: 0.
% <interptype> (optional) is 'nearest' | 'linear' | 'cubic'.  default: 'cubic'.
% <alignfile> (optional) is an alignment.mat file that indicates the positioning 
%   of the volume. if this case is used, <specialmm> should be a single scalar N
%   and should be consistent with the 'tr' variable in <alignfile>.
%   Default is to do the usual thing.
% <outputdir> (optional) is the directory to write the .mgz files to.
%   Default is cvnpath('freesurfer')/<subjectid>/surf/
%
% Use interpolation to transfer the volume data in <volfiles> onto the layer 
% surfaces (e.g. layerA1-A6) as well as the white and pial surfaces.
% Save the results as .mgz files.
%
% There are three cases:
% (1) The usual case is that the volumes in <volfiles> are assumed to 
%     be in our standard FreeSurfer 320 x 320 x 320 0.8-mm space.
% (2) A different case is when the <specialmm> mechanism is used; in this 
%     case, the user sets the voxel size and matrix size and we create 
%     volumes that share the same center location as the standard FreeSurfer space.
% (3) A third case is when the <specialmm> mechanism is used in conjunction
%     with <alignfile>. This allows the volumes to be placed in arbitrary locations.
%
% history:
% - 2016/11/30 - add <alignfile> and <outputdir> inputs
% - 2016/11/29 - add <specialmm> and <interptype> inputs

% internal constants [NOTE!!!]
fsres = 256;
newres = 320;

% input
if ~exist('datafun','var') || isempty(datafun)
  datafun = @(x) x;
end
if ~exist('specialmm','var') || isempty(specialmm)
  specialmm = 0;
end
if ~exist('interptype','var') || isempty(interptype)
  interptype = 'cubic';
end
if ~exist('alignfile','var') || isempty(alignfile)
  alignfile = [];
end
if ~exist('outputdir','var') || isempty(outputdir)
  outputdir = [];
end
if ~iscell(names)
  names = {names};
end

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
hemis = {'lh' 'rh'};

% load
if ~isempty(alignfile)
  a1 = load(alignfile);
end

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
    vertices{p,q}(4,:) = 1;  % now: 4 x V
  end
end

% load volumes
if isequal(specialmm,0)
  data = cvnloadstandardnifti(volfiles);
  assert(isequal(sizefull(data,3),[newres newres newres]));  % sanity check
  nd = size(data,4);
else
  data = volfiles;
  if ~iscell(data)
    data = {data};
  end
  if length(specialmm)==1
    specialmm = repmat(specialmm,[1 length(data)]);          % expand
  end
  nd = length(data);
end
assert(nd==length(names));                                   % sanity check

% expand datafun
if ~iscell(datafun)
  datafun = {datafun};
end
if length(datafun)==1
  datafun = repmat(datafun,[1 nd]);
end

% interpolate volume onto surface and save .mgz file:
for p=1:nd

  % this is the usual standard case
  if isequal(specialmm,0)
    tempdata = feval(datafun{p},data(:,:,:,p));
    for q=1:length(hemis)
      for r=1:length(surfs)
        coord = (vertices{q,r}(1:3,:) - .5)/fsres * newres + .5;  % DEAL WITH DIFFERENT RESOLUTION
        temp = ba_interp3_wrapper(tempdata,coord,interptype);
        cvnwritemgz(subjectid,sprintf('%s_%s',names{p},surfsB{r}),temp,hemis{q},outputdir);
      end
    end

  % this is the case where the user sets the voxel size
  else
    tempdata = feval(datafun{p},data{p});
    for q=1:length(hemis)
      for r=1:length(surfs)
      
        % in this case, the user specifies the alignment
        if ~isempty(alignfile)
          coord = volumetoslices(vertices{q,r},a1.tr);
          coord = coord(1:3,:);
          
        % in this case, we assume the center of the slab is matched
        else
          coord = bsxfun(@plus,(vertices{q,r}(1:3,:) - (1+fsres)/2) * (1/specialmm(p)),vflatten((1+sizefull(data{p},3))/2));
        end
        
        % do the interpolation
        temp = ba_interp3_wrapper(tempdata,coord,interptype);
        
        % write out the file
        cvnwritemgz(subjectid,sprintf('%s_%s',names{p},surfsB{r}),temp,hemis{q},outputdir);

      end
    end
  end

end
