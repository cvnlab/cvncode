function cvnconstructlowres(subjectid,numlayers,layerprefix,fstruncate,meanvolfile,alignfile,targetreses,polydeg,validfile)

% function cvnconstructlowres(subjectid,numlayers,layerprefix,fstruncate,meanvolfile,alignfile,targetreses,polydeg,validfile)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate> is like 'pt'
% <meanvolfile> is like '/home/stone-ext1/fmridata/20160212-ST001-E002/preprocessVER1/mean.nii'
% <alignfile> is like   '/home/stone-ext1/fmridata/20160212-ST001-E002/freesurferalignment/alignment.mat'
% <targetreses> is a vector of voxel sizes to simulate
% <polydeg> is the polynomial degree to use when removing coil bias
% <validfile> is like   '/home/stone-ext1/fmridata/20160212-ST001-E002/preprocessVER1SURFC1051/valid.mat'
%
% Take the volume-based mean volume in <meanvolfile> and perform Fourier-based smoothing according
% to <targetreses>. We modify the intensity values but leave the matrix size the same.
% Note that we use padding ('replicate') before filtering in order to reduce edge effects.
% Be careful that the invalid voxels are treated as 0 and this affects the results.
% Results are saved to files named like 'mean_2pt5mm.nii'.
%
% We then map these smoothed volumes to the surface based on <alignfile> using
% cubic interpolation. Results are saved in [stripfile(meanvolfile) '/surf']
% using files named like 'lh.MEAN_2PT5MM_layerA1_DENSETRUNCpt.mgz'.
%
% Finally, we remove coil bias from these surface-based values. In this process,
% we consider only the valid vertices as indicated in <validfile>, and we
% ensure that results for invalid vertices are set to NaN. Results are
% saved to files named like 'mean_2pt5mm_biascorrected.mat'.
% 
% Notes:
% - We skip cases where the target voxel size (in <targetreses>)
%   is smaller than the native resolution of <meanvolfile>.

%%%%%%%%%%%% SETUP

% internal constants
padfactor = 3;                               % how many fat voxels to pad by (roughly)
homogenizeknobs = [99 1/4 polydeg Inf];      % knobs used during homogenization

% define
hemis = {'lh' 'rh'};

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

%%%%%%%%%%%% LOAD THE VOLUME

a1 = load_untouch_nii(meanvolfile);

%%%%%%%%%%%% SMOOTH THE VOLUME

% process each voxel size
vols = {};      % cell vector of volumes (double format)
prefixes = {};  % e.g. {'MEAN_1PT5MM' 'MEAN_2MM' ...}
for zz=1:length(targetreses)

  % calc
  origsz = round(100*a1.hdr.dime.pixdim(2:4))/100;      % original voxel size
  targsz = repmat(targetreses(zz),[1 3]);               % target voxel size

  % check that original voxels are isotropic
  assert(all(origsz==origsz(1)));

  % if target is smaller than original, just skip
  if targsz(1) <= origsz(1)
    continue;
  end

  % pad the volume   [NOTE: THIS IS A RED FLAG]
  pads = round(padfactor*targsz./origsz);
  vol = padarray(double(a1.img) * a1.hdr.dime.scl_slope + a1.hdr.dime.scl_inter,pads,'replicate','both');
  
  % perform the smoothing   [ANOTHER RED FLAG: THE INVALID VOXELS ARE TREATED AS 0]
  vol = smoothvolumes(vol,origsz,targsz,1);      
  
  % remove padding       
  vol = subscript(vol,{(pads(1)+1):(size(vol,1)-pads(1)) ...
                       (pads(2)+1):(size(vol,2)-pads(2)) ...
                       (pads(3)+1):(size(vol,3)-pads(3))});

  % construct a nice string label (e.g. '2pt5')
  nicelabel = regexprep(num2str(targetreses(zz)),'\.','pt');
  prefixes{end+1} = sprintf('MEAN_%sMM',upper(nicelabel));  % will be used later

  % save the results to a .nii file
  a2 = a1;
  a2.img = cast(vol,class(a1.img));  % 'int16' typically
  save_untouch_nii(a2,sprintf('%s_%smm.nii',stripext(meanvolfile),nicelabel));  % files are like 'mean_2pt5mm.nii'

  % record results
  vols{end+1} = double(a2.img);
  
end

%%%%%%%%%%%% PUT SMOOTHED VOLUMES ON SURFACE (USING CUBIC INTERPOLATION)

% saved files are like 'surf/lh.MEAN_2PT5MM_layerA1_DENSETRUNCpt.mgz'
cvnmapvolumetosurface(subjectid,numlayers,layerprefix,fstruncate, ...
  vols,prefixes,[],origsz(1),'cubic',alignfile,[stripfile(meanvolfile) '/surf']);

%%%%%%%%%%%% REMOVE COIL BIAS FROM THESE SURFACE VALUES (code inherited from cvnremovecoilbias.m)

% load in coordinates of layer vertices (6-element cell vector, each is (L+R)x3)
layerverts = {};
for i=1:numlayers
  [surfL,surfR] = cvnreadsurface(subjectid,hemis,sprintf('layer%s%d',layerprefix,i),sprintf('DENSETRUNC%s',fstruncate));
  layerverts{i} = [surfL.vertices; surfR.vertices];
end

% load in the values (6 x N cell matrix, each is a column vector that is (L+R)x1)
vals = {};
for i=1:numlayers
  for zz=1:length(prefixes)
    vals{i,zz} = cvnloadmgz(sprintf('%s/surf/*.%s_layer%s%d_DENSETRUNC%s.mgz',stripfile(meanvolfile),prefixes{zz},layerprefix,i,fstruncate));
  end
end

% load in valid mask
V = load(validfile);  % V.data is 1 x 6 x (L+R)
validmask = squish(permute(V.data,[3 2 1]),2);  % use only the VALID vertices (L+R)*6 x 1

% do it (newvals is (L+R)*6 x N)
[newvals,brainmask,polymodel] = ...
  homogenizevolumes(cell2mat(vals),homogenizeknobs,[],validmask,catcell(1,layerverts));
newvals(~validmask,:) = NaN;  % set invalid voxels to NaN

% save results
for zz=1:length(prefixes)
  T = setfield(V,'data',permute(reshape(newvals(:,zz),[],numlayers),[3 2 1]));  % 1 x 6 x (L+R)
  save(sprintf('%s/%s_biascorrected.mat',stripfile(meanvolfile),lower(prefixes{zz})),'-struct','T','-v7.3');
end
