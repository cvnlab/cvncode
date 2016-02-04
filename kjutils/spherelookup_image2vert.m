function vertvalues = spherelookup_image2vert(img,Lookup,badval)

if(~exist('badval','var') || isempty(badval))
    badval=0;
end

assert(isequal(size(img),size(Lookup.imglookup)));
assert(~isempty(Lookup.reverselookup));

vertvalues=badval*ones(Lookup.vertsN,1);
vertvalues(Lookup.imglookup)=img;
vertvalues(Lookup.reverselookup>0)=img(Lookup.reverselookup(Lookup.reverselookup>0));
