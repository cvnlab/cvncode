%%
function V = fillmask(mask,maskeddata)
sz=size(maskeddata);
V=zeros([size(mask,1) sz(2:end)]);
V(mask,:,:,:,:)=maskeddata;
end
