function fn = justdir(filenames)

is1 = ~iscell(filenames);
if(~iscell(filenames))
    filenames = {filenames};
end
fn = filenames;

if(ispc)
    hasdir = cellfun(@(x)(any(x=='/' | x=='\')),filenames);

    fn(~hasdir) = filenames(~hasdir);
    fn(hasdir) = cellfun(@(x)(x(1:max(find(x=='/' | x=='\'))-1)),filenames(hasdir),'uniformoutput',false);
else
    hasdir = cellfun(@(x)(any(x=='/')),filenames);

    fn(~hasdir) = filenames(~hasdir);
    fn(hasdir) = cellfun(@(x)(x(1:max(find(x=='/'))-1)),filenames(hasdir),'uniformoutput',false);    
end
if(is1)
    fn = fn{1};
end