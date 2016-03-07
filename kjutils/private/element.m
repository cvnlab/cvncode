function B = element(A,varargin)
if(isempty(A))
    B = [];
    return;
end
ii=varargin;
idx=find(cellfun(@isempty,ii));
for id=idx
  ii{id}=1:size(A,id);
end
if iscell(A)
  B=A{ii{:}};
else
  B=A(ii{:});
end

