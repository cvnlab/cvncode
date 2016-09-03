function vertvalues = spherelookup_image2vert(img,Lookup,badval)
% helper function to map images back to vertex maps.  
% Handles input2surf conversion when needed and extrapolation masking
% Can handle multiple hemispheres if Lookup is a cell, in which case the 
%   return value is a struct with 'data', 'numlh', and 'numrh' fields.

if(~exist('badval','var') || isempty(badval))
    badval=0;
end

%%%%%%%%%%%%%%%
%handle multi-hemisphere 
if(iscell(Lookup))
    hemivals={};
    x0=0;

    for i = 1:numel(Lookup)
        
        v=spherelookup_image2vert(img(:,x0+(1:Lookup{i}.imgN)),Lookup{i},badval);
        if(isequal(Lookup{i}.hemi,'lh'))
            hemivals{1}=v;
        else
            hemivals{2}=v;
        end
        
        x0=x0+Lookup{i}.imgN;
    end
    numlh=size(hemivals{1},1);
    numrh=size(hemivals{2},1);
    vertvalues=struct('data',cat(1,hemivals{:}),'numlh',numlh,'numrh',numrh);
    return;
 end


%%%%%%%%%%%%%
assert(isequal(size(img),size(Lookup.imglookup)));
assert(~isempty(Lookup.reverselookup));

vertvalues=badval*ones(Lookup.vertsN,1);
vertvalues(Lookup.imglookup)=img;
vertvalues(Lookup.reverselookup>0)=img(Lookup.reverselookup(Lookup.reverselookup>0));
if(~isempty(Lookup.input2surf))
    v=vertvalues;
    vertvalues=badval*ones(Lookup.inputN,1);
    vertvalues(Lookup.input2surf)=v;
end
