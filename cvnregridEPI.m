function cvnregridEPI(subjectid,aligndir,targetresolution,mode,crop)

% function cvnregridEPI(subjectid,aligndir,targetresolution,mode,crop)
%
% <subjectid> is like 'cvn7002'
% <aligndir> is a specific directory like '/path/to/FSalignmentZ_run01'
% <targetresolution> is a number in mm (e.g. 0.5)
% <mode> (optional) is
%   0 means use a canonical box parallel to the FreeSurfer anatomy
%   1 means conform a box.
%   Default: 0.
% <crop> (optional) is {A:B C:D E:F} where these are 1-based index ranges.
%   Default: [] which means perform no crop.
%
% Based on the ANTS transformation telling us how the EPI data are registered
% to the T2 anatomy, this function determines a new "regridding" of
% the EPI data. The basic steps are: determine EPI voxel space 1-based indices
% in the T2 volume; use a (somewhat crazy) algorithm to determine a new 3D
% slice slab that minimizes the sum of squares of the range of valid EPI 
% locations (this is the "conform a box" idea); and then save a test NIFTI 
% volume out (regridEPI.nii.gz) that has the calculated sform headers. Some 
% intermediary useful quantities are saved to regridEPI.mat.
%
% Note that if the dimensions of the mapped EPI volume are comparable in spatial
% extent (i.e. field-of-view), there may be some instability in terms of the 
% result of the algorithm (e.g. x and y may be incidentally swapped). We could
% revisit this if this proves to be a problem.
%
% If <mode> is 1, the conform-box idea described above is used. If <mode> is
% 0, this is a simpler case that assumes a slice slab parallel and matched to
% the T2 anatomy.
%
% The new slice slab is sampled at a resolution of <targetresolution>; and,
% in order to help save memory requirements, is then subject to the crop 
% described in <crop>.

%% Setup

% inputs
if ~exist('mode','var') || isempty(mode)
  mode = 0;
end
if ~exist('crop','var') || isempty(crop)
  crop = [];
end

% basic setup
epifile = sprintf('%s/EPI.nii.gz',aligndir);
fsdir =   sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
t2file =  sprintf('%s/mri/T2.nii.gz',fsdir);
trans1file  = sprintf('%s/EPIsyn_1Warp.nii.gz',aligndir);
trans2file  = sprintf('%s/EPIsyn_0GenericAffine.mat',aligndir);
itrans1file = sprintf('%s/EPIsyn_1InverseWarp.nii.gz',aligndir);
itrans2file = sprintf('"[%s/EPIsyn_0GenericAffine.mat,1]"',aligndir);
outputfile =  sprintf('%s/regridEPI.mat',aligndir);
outputfile2 = sprintf('%s/regridEPI.nii.gz',aligndir);

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

%% Determine points to create data at

% calculate 4 x points in 0-based voxel units
[X,Y,Z] = ind2sub(sizefull(coords,3),find(coords(:,:,:,1)~=9999));
pts = [X(:) Y(:) Z(:)]'-1;
pts(4,:) = 1;

% transform to 4 x points in world units
T = [c1.hdr.hist.srow_x; c1.hdr.hist.srow_y; c1.hdr.hist.srow_z];
T(4,:) = [0 0 0 1];
pts2 = T*pts;

% this is the conform-box case
if isequal(mode,1)

  % subtract the centroid
  centroid = mean(pts2(1:3,:),2);  % 3 x 1
  pts3 = zeromean(pts2,2);
  pts3(4,:) = 1;

  % from the EPI volume, determine the natural basis implied by that
  % volume. we will use this as a starting point for u.
  T2 = [a1.hdr.hist.srow_x; a1.hdr.hist.srow_y; a1.hdr.hist.srow_z];
  T2(4,:) = [0 0 0 1];
  basis = T2*[eye(3); 1 1 1] - T2*[zeros(3); 1 1 1];  % for each of three directions, vector in world units
  u = unitlength(basis(1:3,:),1);  % 3 x 3

  % minimize sum of squares of the ranges of pts3 projected onto the 3-dimensional basis.
  % prepare u as an orthonormal basis.
  options = optimset('Display','off','FunValCheck','on','MaxFunEvals',Inf,'MaxIter',Inf,'TolFun',1e-6,'TolX',1e-6);
  helperfun = @(x) quickgramschmidt(reshape(x,[3 3]));
  [params,d,d,exitflag,output] = lsqnonlin(@(a) range(pts3(1:3,:)'*helperfun(a),1),flatten(u),[],[],options);
  assert(exitflag > 0);
  u = helperfun(params);

  % compute min and max along each dimension
  temp = pts3(1:3,:)'*u(:,1:3);   % pts x 3
  mns = min(temp,[],1);  % 1 x 3
  mxs = max(temp,[],1);  % 1 x 3

  % start at min and grid according to user's preference.
  % this creates 4 x points in world units.
  [X2,Y2,Z2] = ndgrid(mns(1):targetresolution:mxs(1), ...  % each something like 216 x 214 x 64
                      mns(2):targetresolution:mxs(2), ...
                      mns(3):targetresolution:mxs(3));

  % apply crop
  if ~isempty(crop)
    X2 = subscript(X2,crop);
    Y2 = subscript(Y2,crop);
    Z2 = subscript(Z2,crop);
  end
  
  % create the desired gridding as 4 x points in world units
  % Let's call this "G".
  pts4 = X2(:)*u(:,1)' + Y2(:)*u(:,2)' + Z2(:)*u(:,3)';  % voxels x 3
  pts4 = pts4' + centroid;  % add centroid back in
  pts4(4,:) = 1;
  pts4 = single(pts4);  % to save memory, but be careful!
  %figure;scatter3(pts4(1,1:1000:end),pts4(2,1:1000:end),pts4(3,1:1000:end));
  pts4dim = size(X2);   % the matrix dimensions
  
% this is the canonical FreeSurfer case
elseif isequal(mode,0)

  % load
  t1 = load_untouch_nii(t2file);
  t1res = t1.hdr.dime.pixdim(2:4);
  
  % calc
  nd1 = floor((t1res(1)*size(t1.img,1))/targetresolution);  % we round down!
  nd2 = floor((t1res(2)*size(t1.img,2))/targetresolution);
  nd3 = floor((t1res(3)*size(t1.img,3))/targetresolution);
  pad1 = ((t1res(1)*size(t1.img,1)) - (nd1*targetresolution))/2;  % extra pad in mm on one side
  pad2 = ((t1res(2)*size(t1.img,2)) - (nd2*targetresolution))/2;
  pad3 = ((t1res(3)*size(t1.img,3)) - (nd3*targetresolution))/2;

  % grid according to user's preference. 
  % this creates 1-based index units of the t2file.
  [X2,Y2,Z2] = ndgrid((-(nd1*targetresolution)/2 + targetresolution/2 : targetresolution : (nd1*targetresolution)/2 - targetresolution/2) / t1res(1) + ((1+size(t1.img,1))/2), ...
                      (-(nd2*targetresolution)/2 + targetresolution/2 : targetresolution : (nd2*targetresolution)/2 - targetresolution/2) / t1res(2) + ((1+size(t1.img,2))/2), ...
                      (-(nd3*targetresolution)/2 + targetresolution/2 : targetresolution : (nd3*targetresolution)/2 - targetresolution/2) / t1res(3) + ((1+size(t1.img,3))/2));

  % apply crop
  if ~isempty(crop)
    X2 = subscript(X2,crop);
    Y2 = subscript(Y2,crop);
    Z2 = subscript(Z2,crop);
  end

  % this creates 4 x points in 0-based index units of the t2file.
  pts5 = [X2(:) Y2(:) Z2(:)]'-1;
  pts5(4,:) = 1;
  
  % transform to world units
  % Let's call this "G".
  pts4 = T*pts5;
  pts4 = single(pts4);  % to save memory, but be careful!
  pts4dim = size(X2);   % the matrix dimensions
  
end

% save precious results
save(outputfile,'pts4','pts4dim','T');

%% Determine EPI indices to sample at

% take G in world units, use NIFTI header of the T2 to map to 0-based voxel units.
% this is 4 x points with "where in the T2 to prepare data at".
pts5 = inv(T)*double(pts4);

% change to 1-based voxel units and interpolate through H to determine 1-based decimal EPI indices
Cnew = single([]);
for p=1:3
  Cnew(p,:) = single(ba_interp3_wrapper(coords(:,:,:,p),pts5(1:3,:)+1,'linear'));
end
extratrans = {reshape(Cnew(1,:),pts4dim) ...
              reshape(Cnew(2,:),pts4dim) ...
              reshape(Cnew(3,:),pts4dim)};   % NOTE: single format

%% Create our sample test volume

% let's use extratrans to interpolate through the EPI volume
testdata = ba_interp3_wrapper(a1.img,[extratrans{1}(:) extratrans{2}(:) extratrans{3}(:)]','cubic');
testdata = single(reshape(testdata,size(extratrans{1})));

% use brute force to figure out the nifti sform stuff
[X3,Y3,Z3] = ndgrid(0:pts4dim(1)-1,0:pts4dim(2)-1,0:pts4dim(3)-1);
XYZ3 = [X3(:) Y3(:) Z3(:)]';
XYZ3(4,:) = 1;
T3 = double(pts4)/XYZ3;  % very important to compute this in double format!

% sanity check
basis = T3*[eye(3); 1 1 1] - T3*[zeros(3); 1 1 1];  % for each of three directions, vector in world units
basis = unitlength(basis(1:3,:),1);
assert(allzero(basis'*basis - eye(3)));

% create and save a NIFTI
nsd_savenifti(zeros(size(testdata),class(testdata)),repmat(targetresolution,[1 3]),outputfile2);
s1 = load_untouch_nii(outputfile2);
s1.img = testdata;
s1.hdr.hist.srow_x = T3(1,:);
s1.hdr.hist.srow_y = T3(2,:); 
s1.hdr.hist.srow_z = T3(3,:);
save_untouch_nii(s1,outputfile2);
