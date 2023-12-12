function transformeddata = cvnmapvolumetosurface2(fsid,data,surf,interptype, ...
  badval,outputclass,outputfile,outputdir,datafun)

% function transformeddata = cvnmapvolumetosurface2(fsid,data,surf,interptype, ...
%   badval,outputclass,outputfile,outputdir,datafun)
%
% <fsid> is the FreeSurfer subject ID (e.g. 'cvn7002')
% <data> is:
%   (1) a NIFTI file with one or more 3D volumes (X x Y x Z x D)
%   (2) {DATA T} where DATA is one or more 3D volumes and where T
%     is the 4x4 voxel-to-world transformation matrix in the
%     standard NIFTI convention. T can be [], in which case we assume
%     the transformation associated with FreeSurfer's mri/T1.nii.gz
% <surf> is the name of the surface desired (e.g. 'graymid').
%   can be a cell vector if you want to map to multiple surfaces 
%   (e.g. {'layerB1' 'pial'}).
% <interptype> is 'nearest' | 'linear' | 'cubic' | 'wta'
% <badval> (optional) is the value to use for invalid locations. Default: NaN.
% <outputclass> (optional) is the output format to use (e.g. 'single').
%   Default is to use the class of <data>. Note that we always perform
%   calculations in double format and then convert at the end.
% <outputfile> (optional) is a filename that you want to use.
%   We automatically prepend 'lh.' and 'rh.'. For example, if you 
%   specify 'results', we will write lh.results.mgz and rh.results.mgz.
%   Default is [] which means to not write out files.
% <outputdir> (optional) is the directory to write the .mgz files to.
%   Default is cvnpath('freesurfer')/<fsid>/surf/
% <datafun> (optional) is a function to apply to the data right after 
%   loading the data in.
%
% Interpolate <data> onto FreeSurfer surfaces using ba_interp3.
% The output <transformeddata> is {LH RH} with each element being
% vertices x D (multiple volumes) x S (multiple surfaces).
% If <outputfile> is specified, we write the results to disk, too.
%
% Details on 'wta':
%   This scheme is a winner-take-all scheme. The data must consist of discrete 
% integer labels. Each integer is separately mapped as a binary volume, and the integer
% resulting in the largest value at a given location is assigned to that location.
% This mechanism is useful for ROI labelings.

% input
if ~exist('badval','var') || isempty(badval)
  badval = NaN;
end
if ~exist('outputclass','var') || isempty(outputclass)
  outputclass = [];
end
if ~exist('outputfile','var') || isempty(outputfile)
  outputfile = [];
end
if ~exist('outputdir','var') || isempty(outputdir)
  outputdir = sprintf('%s/%s/surf',cvnpath('freesurfer'),fsid);
end
if ~exist('datafun','var') || isempty(datafun)
  datafun = @(x) x;
end
if ~iscell(surf)
  surf = {surf};
end

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),fsid);
hemis = {'lh' 'rh'};

% load FS T1
t1 = load_untouch_nii(sprintf('%s/mri/T1.nii.gz',fsdir));
T_t1 = [t1.hdr.hist.srow_x; t1.hdr.hist.srow_y; t1.hdr.hist.srow_z; 0 0 0 1];

% load data
if ischar(data)
  a1 = load_untouch_nii(data);
  sourceclass = class(a1.img);
  data = double(a1.img);
  if a1.hdr.dime.scl_slope ~= 0
    data = data * a1.hdr.dime.scl_slope + a1.hdr.dime.scl_inter;
  end
  T_data = [a1.hdr.hist.srow_x; a1.hdr.hist.srow_y; a1.hdr.hist.srow_z; 0 0 0 1];
else
  assert(iscell(data));
  T_data = data{2};
  data = data{1};
  sourceclass = class(data);
  if isempty(T_data)
    T_data = T_t1;
  end
end
nd = size(data,4);  % number of data volumes

% deal with outputclass
if isempty(outputclass)
  outputclass = sourceclass;
end

% deal with FS-related transforms
[status,result] = unix(sprintf('mri_info --vox2ras-tkr %s/mri/T1.mgz',fsdir)); assert(status==0);
T_orig = eval(['[' result ']']);  % vox2ras-tkr

% load surfaces (after this, we are in 0-based voxel coordinates of the data)
vertices = {};
for p=1:length(hemis)
  for q=1:length(surf)
    vertices{p,q} = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,hemis{p},surf{q}))';  % 3 x V
    vertices{p,q}(4,:) = 1;
    vertices{p,q} = inv(T_data)*T_t1*inv(T_orig)*vertices{p,q};  % map from rastkr to vox (this is 0-based where 0 is center of first voxel); map from vox to ras; map from ras to 0-based voxel coordinates of the data
  end
end

% interpolate volume onto surface
transformeddata = repmat({cast([],outputclass)},[1 2]);  % this will be {LH RH} with each element being vertices x D x NUMSURFACES
for zz=nd:-1:1  % process each volume
  tempdata = feval(datafun,data(:,:,:,zz));
  for p=1:length(hemis)
    for q=length(surf):-1:1
      coord = vertices{p,q}(1:3,:) + 1;  % ba_interp3 wants 1-based indices
      transformeddata{p}(:,zz,q) = cast(nanreplace(ba_interp3_wrapper(tempdata,coord,interptype),badval),outputclass);
      if ~isempty(outputfile)
        cvnwritemgz(fsid,outputfile,transformeddata{p}(:,zz,q).',hemis{p},outputdir);
      end
    end
  end
end
