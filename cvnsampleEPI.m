function cvnsampleEPI(subjectid,aligndir,regridfile,outputfilename,mode)

% function cvnsampleEPI(subjectid,aligndir,regridfile,outputfilename,mode)
%
% <subjectid> is an FS ID like 'cvn7002'. Or, you can specify <subjectid> to be
%   directly the T2 NIFTI file (in this case, <regridfile> cannot be {0}).
% <aligndir> refers to multiple directories like '/path/to/FSalignmentZ_run%02d'
% <regridfile> is either
%   (1) the result of cvnregridEPI.m like '/path/to/FSalignmentZ_run01/regridEPI.mat'
%   (2) {0} which indicates graymid 
% <outputfilename> (optional) is .mat file to save. Default: 'sampleEPI.mat'.
% <mode> (optional) deals with reversing the transformation performed in
%   cvnalignEPItoFST2.m. If 0, do nothing special. If 1, this corresponds to
%   the case of cvnalignEPItoFST2's <wantspecialfun> flag set to 1.
%   Default: 1.
%
% Using the locations indicated in <regridfile>, this function
% determines the corresponding locations for each given run of EPI data 
% referred to by <aligndir>. We write these locations to <outputfilename>,
% indicating exactly where to sample in the original EPI DICOM files to 
% achieve data that reflect the desired regridded location.

% inputs
if ~exist('outputfilename','var') || isempty(outputfilename)
  outputfilename = 'sampleEPI.mat';
end
if ~exist('mode','var') || isempty(mode)
  mode = 1;
end

% setup locations
%
% handle the case of cvnregridEPI.m
if ischar(regridfile)
  load(regridfile,'pts4','pts4dim','T');
  pts5 = inv(T)*double(pts4);  % this is 4 x points with "where in the T2 to prepare data at" (0-based)

% handle the cortical surface case
elseif isequal(regridfile{1},0)
  pts5 = cvnreadsurfaceintovox(subjectid,[],[],[]);  % 4 x points in 0-based "T2" voxels
  pts4dim = [];  % just a hack to be handled specially below

end

% start the loop
runix = 1;
while 1
  
  % see if we have work to do
  aligndir0 = sprintf(aligndir,runix);
  if ~exist(aligndir0,'dir')
    return;
  end

  % basic setup
  epifile = sprintf('%s/EPI.nii.gz',aligndir0);
  if exist(subjectid,'file')==2
    t2file =  subjectid;
  else
    fsdir =   sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
    t2file =  sprintf('%s/mri/T2.nii.gz',fsdir);
  end
  trans1file  = sprintf('%s/EPIsyn_1Warp.nii.gz',aligndir0);
  trans2file  = sprintf('%s/EPIsyn_0GenericAffine.mat',aligndir0);
  itrans1file = sprintf('%s/EPIsyn_1InverseWarp.nii.gz',aligndir0);
  itrans2file = sprintf('"[%s/EPIsyn_0GenericAffine.mat,1]"',aligndir0);
  outputfile = sprintf('%s/%s',aligndir0,outputfilename);

  % load
  a1 = load_untouch_nii(epifile);  % load EPI volume

  %% Map EPI to T2 space

  % get decimal EPI coordinates in the space of the T2.
  % invalid T2 voxels (no EPI data) are assigned 9999.
  coords = [];  % X x Y x Z x 3
  for p=1:3
    a2 = a1;
    a2.img = fillmatrix(1:size(a1.img,p),size(a1.img),p);  % modulate along one dimension of EPI volume
    infile = [tempname '.nii'];
    save_untouch_nii(a2,infile);
    outfile = [tempname '.nii'];
    unix_wrapper(sprintf('antsApplyTransforms --dimensionality 3 --input %s --reference-image %s --output %s --interpolation Linear --transform %s --transform %s --default-value 9999',infile,t2file,outfile,itrans2file,itrans1file),0);
    c1 = load_untouch_nii(outfile);
    coords(:,:,:,p) = c1.img;
    delete(infile); delete(outfile);
  end

  % coords is X x Y x Z x 3.
  % it is in the T2 space and has 1-based decimal indices into EPI space.
  % Let's call this "H".

  %% Determine EPI indices to sample at

  % change to 1-based voxel units and interpolate through H to determine 1-based decimal EPI indices
  Cnew = single([]);
  for p=1:3
    Cnew(p,:) = single(ba_interp3_wrapper(coords(:,:,:,p),pts5(1:3,:)+1,'linear'));
  end
  
  % this is the surface case
  if isempty(pts4dim)
    extratrans = {cat(1,Cnew,ones(1,size(Cnew,2),'single'))};  % NOTE: single format

    if isequal(mode,1)
      % finally, we have to reverse the funny transformation we did at the beginning
      extratrans{1}(2,:) = (size(a1.img,2)+1) - extratrans{1}(2,:);  % reverse the flipdim(...,2)
      extratrans{1}([1 2],:) = extratrans{1}([2 1],:);  % reverse the permute(...,[2 1 3])
    end
  
  % this is the volume case
  else
    extratrans = {reshape(Cnew(1,:),pts4dim) ...
                  reshape(Cnew(2,:),pts4dim) ...
                  reshape(Cnew(3,:),pts4dim)};   % NOTE: single format

    if isequal(mode,1)
      % finally, we have to reverse the funny transformation we did at the beginning
      extratrans{2} = (size(a1.img,2)+1) - extratrans{2};  % reverse the flipdim(...,2)
      [extratrans{1},extratrans{2}] = swap(extratrans{1},extratrans{2});  % reverse the permute(...,[2 1 3])
    end

  end
  
  
  % save .mat
  save(outputfile,'extratrans');
  
  % increment
  runix = runix + 1;

end
