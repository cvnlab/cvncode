function fn = justdir(filenames,depth)
% fn = justdir(filenames,depth)
%
% Return just directory name for filename or cell array of filenames
% Optional 'depth' argument removes multiple path components (default=1)

if(~exist('depth','var') || isempty(depth))
    depth=1;
end

is1 = ~iscell(filenames);
if(~iscell(filenames))
    filenames = {filenames};
end
fn = filenames;

if(ispc)
    hasdir = cellfun(@(x)(any(x=='/' | x=='\')),filenames);

    fn(~hasdir) = filenames(~hasdir);
    fn(hasdir) = cellfun(@(x)(x(1:min(find(x=='/' | x=='\',depth,'last'))-1)),filenames(hasdir),'uniformoutput',false);
else
    hasdir = cellfun(@(x)(any(x=='/')),filenames);

    fn(~hasdir) = filenames(~hasdir);
    fn(hasdir) = cellfun(@(x)(x(1:min(find(x=='/',depth,'last'))-1)),filenames(hasdir),'uniformoutput',false);    
end
if(is1)
    fn = fn{1};
end