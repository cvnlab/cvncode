function fn = justfilename(filenames,remove_extension,depth)
%  fn = justfilename(filenames,remove_extension,depth)
%
% Return just the 'leaf' filename for a path or cell array of paths
% remove_extension: true|false(default) remove .mat, .txt, .nii.gz, etc...
% depth: number of path levels at end to retain (default=1)

if(~exist('remove_extenstion','var') || isempty(remove_extension))
    remove_extension = false;
end

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
    fn(hasdir) = cellfun(@(x)(x(max(find(x=='/' | x=='\',depth,'last'))+1:end)),filenames(hasdir),'uniformoutput',false);
else
    hasdir = cellfun(@(x)(any(x=='/')),filenames);

    fn(~hasdir) = filenames(~hasdir);
    fn(hasdir) = cellfun(@(x)(x(max(find(x=='/',depth','last'))+1:end)),filenames(hasdir),'uniformoutput',false);    
end

if(remove_extension)
    %if <filename>.nii.gz then remove the whole .nii.gz
    fn = regexprep(fn,'\.(nii\.gz|[^\.]+)$',''); %
    %hasext = cellfun(@(x)(any(x=='.')),fn);
    %fn(hasext) = cellfun(@(x)(x(1:max(find(x=='.'))-1)),fn(hasext),'uniformoutput',false);
    
end

if(is1)
    fn = fn{1};
end