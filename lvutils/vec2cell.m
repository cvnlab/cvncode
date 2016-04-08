function newcell=vec2cell(vec)
%newcell=vec2cell(vec)
%
%tranforms a nx1 scalar vector to a nx1 string cell - useful for labeling 
%axis using set(gca)
%
%<vec> nx1 scalar vector 
%
%<newcell> nx1 cell

newcell=cell(length(vec),1);
for i=1:length(vec)
    newcell{i}=num2str(vec(i));
end
