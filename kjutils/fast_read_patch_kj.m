%
% read_patch.m
%
% Original Author: Bruce Fischl
% CVS Revision Info:
%    $Author: nicks $
%    $Date: 2013/01/22 20:59:09 $
%    $Revision: 1.3.2.2 $
%
% Copyright © 2011 The General Hospital Corporation (Boston, MA) "MGH"
%
% Terms and conditions for use, reproduction, distribution and contribution
% are found in the 'FreeSurfer Software License Agreement' contained
% in the file 'LICENSE' found in the FreeSurfer distribution, and here:
%
% https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSoftwareLicense
%
% Reporting: freesurfer@nmr.mgh.harvard.edu
%


function patch = read_patch(fname)
% function patch = read_patch(fname)


fid = fopen(fname,'r');
if (fid == -1)
   error('could not open file %s', fname) ;
end

ver = fread(fid, 1, 'int', 0, 'b');
if (ver ~= -1)
   error('incorrect version # %d (not -1) found in file',ver) ;
end

patch.npts = fread(fid, 1, 'int', 0, 'b') ;
A = uint8(fread(fid,patch.npts*16,'uchar'));
fclose(fid);

%%
A0 = reshape(A,16,[]);
ind0 = A0(4:-1:1,:);

xyz0 = A0(end:-1:5,:);
ind = reshape(typecast(ind0(:),'int32'),1,[]);
xyz = reshape(typecast(xyz0(:),'single'),3,[]);

patch.x = double(xyz(3,:));
patch.y = double(xyz(2,:));
patch.z = double(xyz(1,:));

indn = -ind(ind < 0) - 1;
indp = ind(ind >= 0) - 1;

%add 1 for matlab
indn = indn + 1;
indp = indp + 1;

patch.ind = ind;
patch.ind(ind < 0) = indn;
patch.ind(ind >= 0) = indp;
patch.vno = patch.ind;
patch.edge = patch.ind(ind < 0);