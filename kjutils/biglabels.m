function [Lbig,n] = biglabels(B,minlabelvol,voxres,conn)
% [Lbig,n] = biglabels(B,minlabelvox,[voxres])
%
% Return only "large" bwlabeln chunks 
% 
% minlabelvol >=0 : return chunks with at least minlabelvol voxels
% minlabelvol < 0 : return N largest chunks where N=abs(minlabelvol)
%
% Optional:
%   voxres: voxel dimension (eg: 2 = 2.0 mm).  If provided, return chunks
%       at least minlabelvol mm^3 in volume (minlabelvol/voxres^3 voxels)
%
% Returns:
% Lbig = label volume (each voxel is 0 or a label index)
% n = number of chunks in label volume
%
% Example: 
%   Lbiggest = biglabels(B,-2) <--- only largest 2 labels
%   Lbig20vox = biglabels(B,20) <--- all chunks with at least 20 voxels
%   Lbig20mm = biglabels(B,20,0.7) <--- all chunks>=20mm^3, input is 0.7mm resolution

if(~exist('voxres','var') || isempty(voxres))
    voxres=1;
end
if(~exist('conn','var') || isempty(conn))
    conn=26;
end

[L,n]=bwlabeln(B~=0,conn);
c=histc(L(:),1:n);

if(minlabelvol>=0)
    %if voxres is given, minlabelvol is in size in mm^3, so use voxres
    % to convert to # voxels -> 20 mm^3 = x voxels * (mm^3)/voxel
    cbig=find(c>=minlabelvol/(voxres(1)^3));
else
    [~,sidx]=sort(c,'descend');
    cbig=sidx(1:abs(minlabelvol));
end
[Lbigmask,Lbig]=ismember(L,cbig);
Lbig=Lbig.*Lbigmask;
n=max(Lbig(:));
