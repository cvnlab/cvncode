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
%imshow(img);
imshow(nan(size(img)));

for i = 1:numel(txtargs)
    text(txtargs{i}{:});
end

if(alias_amt == 1 && exist('screenimage','file')==2 && 0)
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

%textmask = any(screenimg<255,3); %find non-white pixels
textmask=any(~isnan(screenimg),3);

textmask = repmat(textmask,[1 1 3]); %make sure it includes r,g,and b

new_img = img;
new_img(textmask) = screenimg(textmask);
