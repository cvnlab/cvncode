function new_img = padimage(img, padwidth, bgcolor)
% new_img = padimage(img, padwidth, bgcolor)
% padwidth = [L T R B], or [L&R T&B], or [uniform]

sz = size(img);
nd = ndims(img);

if(nd == 2) %2d arrays are handles slightly differently
    nd = 1;
end

if(nargin == 2)
    bgcolor = repmat(255,[1 nd]);
end

if(numel(bgcolor) < nd)
    bgcolor = repmat(bgcolor,1,nd);
end


%padwidth needs to be LTRB, so repeat elements if just 1 val or LT
if(numel(padwidth) == 1)
    padsize = [padwidth padwidth padwidth padwidth];
elseif(numel(padwidth) == 2)
    padsize = [padwidth padwidth];
else
    padsize = padwidth;
end

new_sz = [sz(1)+padsize(1)+padsize(3), sz(2)+padsize(2)+padsize(4), nd];
%new_img = uint8(zeros(new_sz));
new_img = cast(zeros(new_sz),class(img));

for n = 1:nd
    new_img(:,:,n) = bgcolor(n);    
end

new_img(padsize(1)+[1:sz(1)], padsize(2)+[1:sz(2)], :) = img;
