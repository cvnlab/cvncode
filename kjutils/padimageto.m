function new_img = padimageto(img, finalsize, location, bgcolor)
%location = quadrant 1,2,3,4 or 5=center

if(nargin < 3 || isempty(location) || ~isnumeric(location) || location < 1 || location > 5)
    location = 5;
end

sz = size(img);

sz = sz(1:2);
finalsize = finalsize(1:2);

sizediff = max(finalsize-sz,[0 0]);

switch location
    case 1
        padwidth = [0 sizediff(2) sizediff(1) 0];
    case 2
        padwidth = [0 0 sizediff(1) sizediff(2)];
    case 3
        padwidth = [sizediff(1) 0 0 sizediff(2)];
    case 4
        padwidth = [sizediff(1) sizediff(2) 0 0 ];
    case 5
        tlpad = fix(sizediff/2);
        brpad = sizediff-tlpad;
        padwidth = [tlpad(1) tlpad(2) brpad(1) brpad(2)];
end

if(nargin < 4)
    new_img = padimage(img, padwidth);
else
    new_img = padimage(img, padwidth,bgcolor);    
end