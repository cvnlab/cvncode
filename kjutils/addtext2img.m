% new_img = addtext2img(img, txtargs, alias_amt)
%
% img = image to add text to
% txtargs = cell array where each cell contains:
%       {x, y, yourtext, 'textproperty1',textval1,...}
% alias_amt = amount of anti-aliasing (blurring) to do
%       1=none, 2=default
%
% txtargs example:
% { {0,0,'text1'},...
%   {100, 100, 'text2', 'FontSize', 10}, ...
%   {200, 200, 'text3', 'VerticalAlignment','top'} };

% Update 2016-02-16 KJ: use image() since imshow() won't work in terminal

function new_img = addtext2img(img, txtargs, alias_amt)

if(~iscell(txtargs{1}))
    txtargs = {txtargs};
end

if(nargin < 3)
    alias_amt = 2;
end

alias_amt = max(1,min(alias_amt,4));

fig=figure('Position',[0 0 size(img,2) size(img,1)],'Visible','off');
set(fig,'PaperPositionMode','auto');
set(gca,'Position',[0 0 1 1]);

%imshow(255*ones(size(img)));
if(isequal(class(img),'uint8'))
    bgcolor=[1 2 3];
    set(fig,'color',bgcolor/255);
else
    bgcolor=[1 2 3]/255;
    set(fig,'color',bgcolor);
end
bgimg=cast(repmat(reshape(bgcolor,[1 1 3]),size(img,1),size(img,2)),'like',img);
%imshow(bgimg);
image(bgimg);
axis off;

for i = 1:numel(txtargs)
    text(txtargs{i}{:});
end

if(alias_amt == 1 && exist('screenimage.m','file')==2 && 0)
    screenimg = screenimage(gca); %without anti-aliasing
else
    screenimg = export_fig(gca,'-nocrop',['-a' num2str(alias_amt)]);
end
close(fig);

if(ndims(screenimg) < 3)
    screenimg = repmat(screenimg,[1 1 3]);
end

%because screenimg sometimes has an extra row/column
screenimg = screenimg(1:size(img,1), 1:size(img,2), :);

%on some systems, export_fig might return a different class than the input
if(~isequal(class(img),'uint8') && isequal(class(screenimg),'uint8'))
    screenimg=cast(screenimg,'like',img)/255;
elseif(isequal(class(img),'uint8') && ~isequal(class(screenimg),'uint8'))
    screenimg=cast(screenimg*255,'like',img);
end

textmask = any(screenimg~=bgimg,3); %find non-white pixels
% %textmask = any(screenimg<255,3); %find non-white pixels
textmask = repmat(textmask,[1 1 3]); %make sure it includes r,g,and b

new_img = img;
new_img(textmask) = screenimg(textmask);
