% NOTE: repeat for both lh and rh

%%%%% cut off parietotemporal cortex and save as rh.pt.patch.3d

tksurfer fsaverage rh inflated
- load curvature
- make binary display curvature
- select four points (3 to make plane, 1 to indicate what to keep), "cut plane"
- save patch as: rh.pt.patch.3d

%%%%% convert patch to ASCII

mris_convert -p rh.pt.patch.3d rh.pt.patch.3d.asc

%%%%% convert patch to a real freesurfer surface

% read in patch
surf = read_patch_asc('rh.pt.patch.3d.asc');
  %        faces: [298081x3 double]
  %     vertices: [149552x1 double]
  %            x: [149552x1 double]
  %            y: [149552x1 double]
  %            z: [149552x1 double]
  % faces are 0-indexes relative to the original
  % vertices are 0-indexes indicating which in the original

% read in rh.white so that we have the right verticesA
[verticesA,facesA] = freesurfer_read_surf_kj('rh.white');
verticesA = bsxfun(@plus,verticesA',[128; 129; 128]);  % NOTICE THIS!!!
verticesA(4,:) = 1;

% construct vertices (4 x V)
vertices = zeros(size(verticesA));
vertices(1:3,:) = 0;  % set by default everything to 0 (this means that missing vertices will live at (0,0,0))
vertices(1:3,surf.vertices+1) = bsxfun(@plus,[surf.x surf.y surf.z]',[128; 129; 128]);  % insert at appropriate spots (NOTICE THIS!!!)

% construct faces (F x 3)
faces = surf.faces(:,[1 3 2]) + 1;  % necessary to convert freesurfer to matlab

% at this point, we are in our internal MATLAB format

% but we need to go back to FS format in order to write out the file
vertices = bsxfun(@minus,vertices(1:3,:),[128; 129; 128])';
faces = faces(:,[1 3 2]);

% finally, write out the surface
freesurfer_write_surf_kj('rh.pt',vertices,faces);
