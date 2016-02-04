function img=spherelookup_vert2image(vertvalues,Lookup,badval)
% helper function to map inputs to image.  
% Handles input2surf conversion when needed and extrapolation masking

if(~exist('badval','var') || isempty(badval))
    badval=0;
end
if(size(vertvalues,1)==1 && size(vertvalues,3)>1)
    vertvalues=permute(vertvalues,[2 1 3]);
elseif(size(vertvalues,1)==1 && size(vertvalues,3)==1)
    vertvalues=vertvalues.';
end
if(~isempty(Lookup.input2surf))
    fullvals=+vertvalues(Lookup.input2surf,:);
    img=fullvals(Lookup.imglookup,:);
else
    img=+vertvalues(Lookup.imglookup,:);
end

if(Lookup.is_extrapolated)
    img(Lookup.extrapmask,:)=badval;
end


img=reshape(img,Lookup.imgN,Lookup.imgN,[]);
