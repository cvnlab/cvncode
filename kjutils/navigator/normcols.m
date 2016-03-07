function n = normcols(v)

n = v./repmat(sqrt(sum(v.^2,1)),size(v,1),1);
