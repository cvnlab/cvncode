function [Rmask,Rimg,roihemi,xlim0,ylim0,figpos0] = drawroipoly(img,Lookup,Rimg,specialmode)
%[Rmask,Rimg,roihemi] = drawroipoly(himg,Lookup,Rimg)
%
%Interface for drawing ROI and converting to surface vertex mask
%
%Inputs
%   himg:        MxN image to draw on, or handle to existing GUI image handle.
%                can also be a cell vector in which case you can toggle between
%                images while drawing by using the number keys (1,2,3,...)!
%   Lookup:     cvnlookupimages Lookup struct (or cell of structs for lh,rh)
%   Rimg (optional): MxN matrix where 1s exist in the matrix.
%                    If supplied, we skip manual user drawing of the polygon
%                    and instead act as if Rimg==1 is the drawn polygon mask.
%
%Outputs
%   Rmask:      Vx1 logical (If Lookup is a single hemi, V=(numlh x 1) or (numrh x 1)
%                      If Lookup is both hemis, V=(numlh+numrh x 1)
%   Rimg:       MxN binary image of ROI as drawn
%   roihemi:    'lh' or 'rh' depending on which hemi user drew on
%
% Note: We automatically fill any holes in the drawn binary mask!
%       This is useful when Rimg is supplied by the user (there might be holes).
%
% To fully prevent holes in polygon ROI selection, please make sure to 
% draw on spherical surfaces OR flattened surfaces.
%
% Tips:
% - The first row of keys: 1,2,3,4,etc. toggles the images and starts afresh
% - The second row of keys: q,w,e,r,etc. draws "edge" images on the current image
% - The third row of keys: a,s,d,f,etc. changes the underlying image without changing
%   the current "edge" images.
% - Special key '/' will take a snapshot and write out.

% when <specialmode> is 1, we wait around for the user to toggle keys
% and when they finally press return, we toggle back to the first image
% and then return. also, all outputs are just returned as [].
%
% <xlim0>, <ylim0>, <figpos0> are the x- and y-limits and figure position upon returning.

Rmask=[];

if(~iscell(Lookup))
    Lookup={Lookup};
end


if(isempty(img))
    himg={findobj(gca,'type','image')};
else

  if ~iscell(img)
    img = {img};
  end

  himg = {}; rgbimg = {};
  for pp=1:length(img)
    if(ishandle(img{pp}))
        himg{pp}=img{pp};
        if(~isequal(get(himg{pp},'type'),'image'))
            himg{pp}=findobj(himg{pp},'type','image');
        end
        rgbimg{1,pp}=get(himg{pp},'cdata');
    else
        rgbimg{1,pp}=img{pp};
        figure;
        himg{pp}=imshow(rgbimg{1,pp});
    end
  end

end


% magic to allow positive integer keys to toggle
set(gcf,'KeyPressFcn',@(handle,event) togglefun(handle,event,rgbimg,himg));

% handle specialmode
if exist('specialmode','var') && specialmode==1
  Rmask = [];
  Rimg = [];
  roihemi = [];
  uiwait(gcf);
  xlim0 = get(get(himg{1},'Parent'),'XLim');
  ylim0 = get(get(himg{1},'Parent'),'YLim');
  figpos0 = get(get(get(himg{1},'Parent'),'Parent'),'Position');
  return;
end

wantbypass = exist('Rimg','var') && ~isempty(Rimg);

imgroi=[];
%Press Escape to erase and start again
%double click on final vertex to close polygon
%or right click on first vertex, and click "Create mask" to view the result
%Keep going until user closes the window
if ~wantbypass
  fprintf('Press Escape to erase and start again\n');
  fprintf('Double click on final vertex to close polygon\n');
  fprintf('Right click on first vertex, and click "Create mask" to view the result\n');
  fprintf('When finished, close window to continue\n');
end
while(ishandle(himg{1}))
    if wantbypass
      [ry,rx] = ind2sub(size(Rimg),find(Rimg==1));
      rimg = double(Rimg==1);
    else
      [rimg,rx,ry]=roipoly();
    end

    if ishandle(himg{1})
      xlim0 = get(get(himg{1},'Parent'),'XLim');
      ylim0 = get(get(himg{1},'Parent'),'YLim');
      figpos0 = get(get(get(himg{1},'Parent'),'Parent'),'Position');
    end
    
    rimgNEW = imfill(rimg,'holes');
    if ~isequal(rimgNEW,rimg)
      fprintf('** NOTE: There were holes, so we are using imfill to fill holes!\n');
      rimg = rimgNEW;
    end

    if(isempty(rimg))
        continue;
    end
    
    %Which hemisphere did we draw on?
    if(any(rx>Lookup{1}.imgsize(2)))
        h=2;
        rimg=rimg(:,Lookup{1}.imgsize(2)+1:end);
    else
        h=1;
        rimg=rimg(:,1:Lookup{1}.imgsize(2));
    end
    
    % Rmask = (hemi vertices)x1 binary vector for a single hemisphere
    Rmask=spherelookup_image2vert(rimg,Lookup{h})>0;
    
    imgroi=spherelookup_vert2image(Rmask,Lookup{h},0);
    if(numel(Lookup)>1)
        if(h==1)
            imgroi=[imgroi zeros(Lookup{2}.imgsize)];
        else
            imgroi=[zeros(Lookup{1}.imgsize) imgroi];
        end
    end
    
    %quick way to merge rgbimg background with roi mask
    currentrgb = get(himg{1},'CData');
    tmprgb=bsxfun(@times,currentrgb,.75*imgroi + .25);
    set(himg{1},'cdata',tmprgb);

    if wantbypass
      close;
    end
end


if(numel(Lookup)>1)
    %make sure to use inputN for numlh, numrh, since vertsN will be DENSE for
    %when input type is DENSETRUNCpt
    numlh=0;
    numrh=0;
    for hi = 1:numel(Lookup)
        if(isequal(Lookup{hi}.hemi,'lh'))
            numlh=Lookup{hi}.inputN;
        elseif(isequal(Lookup{hi}.hemi,'rh'))
            numrh=Lookup{hi}.inputN;
        end
    end

    vertidx=find(Rmask);
    if(isequal(Lookup{h}.hemi,'rh'))
        vertidx=vertidx+numlh;
    end

    Rmask=zeros(numlh+numrh,1);
    Rmask(vertidx)=1;
end

Rimg=imgroi;
roihemi=Lookup{h}.hemi;

%%%%%%%%%%%%%%%%%

function togglefun(handle,event,rgbimg,himg)

% the first time through, we need to save state
if isempty(guidata(handle))
  guidata(handle,rgbimg);
end

% get the current state
rgbimg = guidata(handle);

if isequal(event.Key,'return')
  set(himg{1},'CData',rgbimg{1,1});  % go back to the first one!
  uiresume(gcf);
end

if isequal(event.Key,'slash')
  im0 = get(himg{1},'CData');
  files0 = matchfiles('screenshot???.png');
  cnt = 1;
  if ~isempty(files0)
    f = regexp(files0{end},'screenshot(\d+).png','tokens');
    if ~isempty(f) && ~isempty(f{1})
      cnt = str2double(f{1}{1}) + 1;
    end
  end
  outfile0 = sprintf('screenshot%03d.png',cnt);
  imwrite(uint8(255*im0),outfile0);
  fprintf('screenshot file %s written.\n',outfile0);
  return;
end

possiblekeys0 = {'1' '2' '3' '4' '5' '6' '7' '8' '9' '0' 'hyphen'};
possiblekeys = {'q' 'w' 'e' 'r' 't' 'y' 'u' 'i' 'o' 'p' 'leftbracket'};
possiblekeysB = {'a' 's' 'd' 'f' 'g' 'h' 'j' 'k' 'l' 'semicolon' 'quote'};
ix0 = find(ismember(possiblekeys0,event.Key));
ix = find(ismember(possiblekeys,event.Key));
ixB = find(ismember(possiblekeysB,event.Key));

% e.g., command key invalidates everything
if ~isempty(event.Modifier)
  ix0 = [];
  ix = [];
  ixB = [];
end

% init
temp = [];

% if first row, reset edge images
if ~isempty(ix0)
  rgbimg{3,1} = [];
  temp = ix0;
end

% if third row, we need to draw the base image, so simulate it
if ~isempty(ixB)
  temp = ixB;
end

% draw base image
if ~isempty(temp) && isint(temp) && temp >= 1 && temp <= size(rgbimg,2)
  %%currenth = findobj(gca,'type','image');
  set(himg{1},'CData',rgbimg{1,temp});
end

% do we have second or third row to handle?
if ~isempty(ix) || ~isempty(ixB)

  % expand rgbimg if necessary
  if size(rgbimg,1) < 3
    rgbimg{3,1} = [];
  end
  
  % if second row, add to the state and do it
  if ~isempty(ix)
    rgbimg{3,1} = union(rgbimg{3,1},ix);
    listtodo = ix;
  end
  
  % if third row, we need to do all of the current ones again
  if ~isempty(ixB)
    listtodo = rgbimg{3,1};
  end
  
  for zz=1:length(listtodo)
    todo = listtodo(zz);
  
    if todo >= 1 && todo <= size(rgbimg,2)
  
      % create edge image if necessary
      if isempty(rgbimg{2,todo})
        grayim = rgb2gray(rgbimg{1,todo});
        if calccorrelation(grayim(:),vflatten(mean(rgbimg{1,todo},3))) > .9999  % if image appears to be grayscale
          rgbimg{2,todo} = repmat(detectedges(grayim,0.5),[1 1 3]);
        else
          rgbimg{2,todo} = detectedges(rgbimg{1,todo}-repmat(rgb2gray(rgbimg{1,todo}),[1 1 3]),0.5);
        end
        rgbimg{2,todo} = rgbimg{2,todo}/sqrt(mean(rgbimg{2,todo}(:).^2))/3;  % normalize such that RMS at 1/3
      end
    
      % within constraints of a mask, superimpose the edge image on the current image
      mask = mean(rgbimg{2,todo},3) > 0.1;
      set(himg{1},'CData',copymatrix(get(himg{1},'CData'),repmat(mask,[1 1 3]),rgbimg{2,todo}(repmat(mask,[1 1 3]))));

    end
  
  end
  
end

% store the state
guidata(handle,rgbimg);
