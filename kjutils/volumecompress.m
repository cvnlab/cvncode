function volstruct = volumecompress(V,Vmask)
%volstruct = volumecompress(V,[Vmask])
%
%Compress a volume by storing only non-zero values
%If Vmask is provided, use that, otherwise use V~=0
%
%Decompress using volumedecompress(volstruct)


if(~exist('Vmask','var') || isempty(Vmask))
    Vmask=V~=0;
end

volsize=size(V);
maskidx=find(Vmask(:)~=0);
maskval=V(maskidx);
volstruct=fillstruct(volsize,maskidx,maskval);
