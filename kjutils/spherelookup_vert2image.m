function img=spherelookup_vert2image(vertvalues,Lookup,badval)
% helper function to map vertex inputs to image.  
% Handles input2surf conversion when needed and extrapolation masking
% Can handle multiple hemispheres if vertvalues is a valstruct 
%   (i.e., a struct with 'data', 'numlh', and 'numrh' fields)

if(~exist('badval','var') || isempty(badval))
    badval=0;
end

%% Handle multi hemisphere input
if(isstruct(vertvalues) && isfield(vertvalues,'numlh'))
    if(~iscell(Lookup))
        Lookup={Lookup};
    end
    imghemi={};
    for i = 1:numel(Lookup)
        h=Lookup{i}.hemi;
        switch(h)
            case 'lh'
                idx=1:vertvalues.numlh;
            case 'rh'
                idx=(1:vertvalues.numrh)+vertvalues.numlh;
        end
        imghemi{i}=spherelookup_vert2image(vertvalues.data(idx,:,:),Lookup{i},badval);
    end
    img=cat(2,imghemi{:});
    return;
end

%%
if(size(vertvalues,1)==1 && size(vertvalues,3)>1)
    vertvalues=permute(vertvalues,[2 1 3]);
elseif(size(vertvalues,1)==1 && size(vertvalues,3)==1)
    vertvalues=vertvalues.';
end
if(~isempty(Lookup.input2surf) && Lookup.inputN==size(vertvalues,1))
    fullvals=+vertvalues(Lookup.input2surf,:);
      % critical line: make an image by using nearest-neighbor indices into vertices.
      % Lookup.imglookup is just something like [1000x1000 uint32] with indices into vertices.
    img=fullvals(Lookup.imglookup,:);
else
    img=+vertvalues(Lookup.imglookup,:);
end

if(Lookup.is_extrapolated)
    img(Lookup.extrapmask,:)=badval;
end

if(isfield(Lookup,'imgsize'))
    imgsize=Lookup.imgsize;
else
    imgsize=[Lookup.imgN Lookup.imgN];
end
img=reshape(img,imgsize(1),imgsize(2),[]);
