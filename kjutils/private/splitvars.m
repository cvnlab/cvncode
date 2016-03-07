function varargout = splitvars(v)

nd = ndims(v);

if(nd == 2 && numel(v) == nargout)
    v = reshape(v(:),1,[]);
end
if(nd>2 || (nd==2 && size(v,2) ~= nargout) || (nd==1 && numel(v) ~= nargout))
    error('mismatch between input size and outputs');
end

if(nd==1)
    varargout = num2cell(v);
elseif(nd==2)
    for i = 1:nargout
        varargout{i} = v(:,i);
    end
end