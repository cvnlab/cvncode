function mapLR = spherelookup_merge_hemi_map(Lookup,field,dim)
if(~exist('dim','var') || isempty(dim))
    dim=2;
end

mapLR=[];
if(iscell(Lookup))
    if(~isfield(Lookup{1},field))
        return;
    end
    for i = 1:numel(Lookup)

        if(isempty(mapLR))
            mapLR=Lookup{i}.(field);
        else
            mapLR=cat(dim,mapLR,Lookup{i}.(field));
        end
    end
elseif(isstruct(Lookup))
    if(~isfield(Lookup,field))
        return;
    end
    mapLR=Lookup.(field);
else
    error('Invalid lookup');
end
