function m = regexpimatch(varargin)
v = varargin{1};
vfun = @(x)(element({'',x},ischar(x)+1));
if(iscell(v))
    v=cellfun(vfun,v,'uniformoutput',false);
else
    v=vfun(v);
end
r=regexpi(v,varargin{2:end});
if(iscell(r))
    m = ~cellfun(@isempty,r);
else
    m = ~isempty(r);
end
