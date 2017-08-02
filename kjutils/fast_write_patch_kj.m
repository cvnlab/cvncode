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


function write_patch(fname,patch)
% function patch = read_patch(fname)

[~,~,endian] = computer;
bigend = endian == 'B';


ind = int32(patch.ind(:));
[~,edgeidx] = intersect(patch.ind,patch.edge);
ind = ind - 1; %undo matlab format
ind(edgeidx) = -ind(edgeidx);
ind(ind >= 0) = ind(ind >= 0) + 1;
ind(ind < 0) = ind(ind < 0) - 1;

x = single(patch.x(:));
y = single(patch.y(:));
z = single(patch.z(:));

ind0 = typecast(ind,'uint32');
x0 = typecast(x,'uint32');
y0 = typecast(y,'uint32');
z0 = typecast(z,'uint32');

A = [ind0 x0 y0 z0];
if(~bigend)
    A = swapbytes(A);
end
A = reshape(A.',[],1);
A= typecast(A,'uint8');


fid = fopen(fname,'w');
if (fid == -1)
   error('could not open file %s', fname) ;
end
fwrite(fid, -1, 'int', 0, 'b');
fwrite(fid, patch.npts, 'int', 0, 'b') ;
fwrite(fid,A,'uchar',0,'b');
fclose(fid);
