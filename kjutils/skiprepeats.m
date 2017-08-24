function [newlist, newidx] = skiprepeats(origlist)
%[newlist, newidx] = skiprepeats(origlist)
%
%Return a version of origlist with sequentially repeating values removed
%
% Inputs:
%   origlist = 1-dimensional numerical vector
%
% Outputs:
%   newlist:    origlist with repeats removed
%   newidx:     newlist=origlist(newidx)

if(size(origlist,1)==1)
    newidx=[true origlist(2:end)~=origlist(1:end-1)];
else
    newidx=[true; origlist(2:end)~=origlist(1:end-1)];
end

newlist=origlist(newidx);
