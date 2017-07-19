function V = volume_fillindex(V,xyz,vals)
%V = volume_fillindex(V,xyz,vals)
%
%V = 3d vol to fill, or [3x1] volume size
%xyz = Nx3 volume coordinates to fill
%vals = Nx1 values to insert into volume (default = 1:N)
if(numel(V)>3)
    vsz=size(V);
else
    vsz=V;
    V=zeros(vsz);
end

if(~exist('vals','var') || isempty(vals))
    vals=1:size(xyz,1);
end

if(size(xyz,2)==1)
    V(xyz)=vals;
else
    V(sub2ind(vsz,xyz(:,1),xyz(:,2),xyz(:,3)))=vals;
end

