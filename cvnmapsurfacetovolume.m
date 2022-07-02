function f = cvnmapsurfacetovolume(subjectid,numlayers,layerprefix,fstruncate,data,emptyval,outputprefix,datafun,specialmode)

% function f = cvnmapsurfacetovolume(subjectid,numlayers,layerprefix,fstruncate,data,emptyval,outputprefix,datafun,specialmode)
%
% <subjectid> is like 'C0051'
% <numlayers> is like 6.  can be [] which means non-dense case.
% <layerprefix> is like 'A'.  can be [] which means non-dense case.
% <fstruncate> is like 'pt'.  can be [] which means non-dense case.
% <data> is:
%   (1) a layer .mat file (with D x 6 (or 1) x V), where D indicates different datasets to map
%   (2) a matrix with values as D x 6 (or 1) x V
% <emptyval> is the value to use when no vertices map to a voxel
% <outputprefix> (optional) is one or more filename prefixes, like:
%     {'/home/stone/generic/Dropbox/cvnlab/inout/vals' ...}
%   If provided, we write out NIFTIs to these locations, appending .nii.gz extensions.
%   Note that if provided, there should be a 1-to-1 correspondence between the number
%   of datasets in <data> and the number of elements in <outputprefix>.
% <datafun> (optional) is a function to use to transform <data> after loading
% <specialmode> (optional) is:
%   0 means do the usual thing
%   N means treat the data as positive integers from 1 through N and perform a
%     winner-take-all voting mechanism. in this case, D must be 1.
%   Default: 0.
%
% Take the data in <data> and convert these data into volumes, where these volumes 
% are in our standard FreeSurfer 320 x 320 x 320 0.8-mm space.
%
% If <outputprefix> is supplied, we also write NIFTI files using single format.
%
% Notes on how the conversion is done:
% - We obtain the XYZ coordinates from the layer (or graymid) surfaces.
%   All of the XYZ coordinates are aggregated together (across hemispheres and layers).
% - Each vertex contributes a linear kernel that has a size of exactly 2 x 2 x 2 voxels.
%   This means +/- 0.8 mm in all three spatial dimensions. (Think of a "tent".)
% - All of the linear kernels are added up, and values are obtained at the centers
%   of all of the volumetric voxels (0.8-mm).
% - Each voxel is interpreted as performing a weighted average of the contributing 
%   vertices. Thus, we are really just locally averaging the surface data.
% - If no weights are given to a voxel, that voxel gets assigned <emptyval>.
%
% Notes on <specialmode>:
% - Our strategy is to split the data into separate channels (e.g. data==1, data==2, etc.)
%   and sum up the weights from each channel at each voxel.  The channel with the 
%   biggest sum of weights wins.
% - Voxels that have no vertices mapping to them get <emptyval>.
% - Note that this implicitly means that all voxels within 0.8 mm of any vertex with a 
%   label will get a label.  This is arbitrary, and there are other things we can do,
%   such as enforcing minimum distances and/or using only gray-matter voxels from FS, etc.
%
% History:
% - 2020/05/09 - update to use vox2ras-tkr instead of the previous method (which was slightly inaccurate)
% - 2019/06/08 - refactor code to use cvnmapsurfacetovolume_helper.m
% - 2017/11/28 - implement non-dense case
% - 2016/11/29 - add <specialmode>; load from T1 and explicitly cast to 'single'

% input
if ~exist('outputprefix','var') || isempty(outputprefix)
  outputprefix = [];
end
if ~exist('datafun','var') || isempty(datafun)
  datafun = [];
end
if ~exist('specialmode','var') || isempty(specialmode)
  specialmode = 0;
end
if ~isempty(outputprefix) && ischar(outputprefix)
  outputprefix = {outputprefix};
end

% internal constants [NOTE!!!]
fsres = 256;
newres = 320;

% get data
if ischar(data)
  data = loadmulti(data,'data');
end

% transform data
if ~isempty(datafun)
  data = feval(datafun,data);
end

% massage data dimensions
data = squish(permute(data,[3 2 1]),2)';  % D x V*(6 or 1)

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
hemis = {'lh' 'rh'};

% figure out surface names
surfs = {};
if isempty(numlayers)
  surfs{1} = 'graymid';
else
  for p=1:numlayers
    surfs{p} = sprintf('layer%s%dDENSETRUNC%s',layerprefix,p,fstruncate);  % six layers, dense, truncated
  end
end

% derive FS-related transforms
[status,result] = unix(sprintf('mri_info --vox2ras-tkr %s/mri/T1.mgz',fsdir)); assert(status==0);
Torig = eval(['[' result ']']);  % vox2ras-tkr

% load surfaces (the vertices are now in 320 space)
vertices = {};
for p=1:length(hemis)
  for q=1:length(surfs)
    vertices{p,q} = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,hemis{p},surfs{q}))';  % 3 x V
    vertices{p,q}(4,:) = 1;
    vertices{p,q} = inv(Torig)*vertices{p,q};  % map from rastkr to vox (this is 0-based where 0 is center of first voxel)
    vertices{p,q}(1:3,:) = vertices{p,q}(1:3,:) + 1;  % now 1-based
% OLD:
%     vertices{p,q} = bsxfun(@plus,vertices{p,q}',[128; 129; 128]);  % NOTICE THIS!!!
%     vertices{p,q} = (vertices{p,q} - .5)/fsres * newres + .5;  % DEAL WITH DIFFERENT RESOLUTION
%     vertices{p,q}(4,:) = 1;  % now: 4 x V
  end
end

% aggregate coordinates across hemis and layers (3 x vertices*(6 or 1))
allvertices = subscript(catcell(2,vertices),{1:3 ':'});

% do the heavy lifting (map surface vertices to volume voxels)
f = cvnmapsurfacetovolume_helper(data,allvertices,newres,specialmode>0,emptyval);

% save files?
if ~isempty(outputprefix)
  vol1orig = load_untouch_nii(sprintf('%s/mri/T1.nii.gz',fsdir));  % NOTE: hard-coded!
  for p=1:size(f,4)
    vol1orig.img = cast(f(:,:,:,p),'single');  %inttofs
    vol1orig.hdr.dime.datatype = 16;  % single (float) format
    vol1orig.hdr.dime.bitpix = 16;
    vol1orig.hdr.dime.scl_slope = 1;
    vol1orig.hdr.dime.scl_inter = 0;
    file0 = [outputprefix{p} '.nii'];
    save_untouch_nii(vol1orig,file0); gzip(file0); delete(file0);
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  % INSPECT:
  % vol1orig = load_untouch_nii(gunziptemp('/stone/ext1/freesurfer/subjects/C0051/mri/T2alignedtoT1.nii.gz'));
  % %vol1orig.img = inttofs(cast(reshape(wtssum,[newres newres newres]),class(vol1orig.img)));
  % %file0 = '/home/stone/generic/Dropbox/cvnlab/inout/wtssum.nii';
  % vol1orig.img = inttofs(cast(reshape(f,[newres newres newres]),class(vol1orig.img)));
  % file0 = '/home/stone/generic/Dropbox/cvnlab/inout/vals.nii';
  % save_untouch_nii(vol1orig,file0); gzip(file0); delete(file0);
