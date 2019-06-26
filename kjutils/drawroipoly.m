function [Rmask,Rimg,roihemi] = drawroipoly(img,Lookup,Rimg)
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
        rgbimg{pp}=get(himg{pp},'cdata');
    else
        rgbimg{pp}=img{pp};
        figure;
        himg{pp}=imshow(rgbimg{pp});
    end
  end

end


% magic to allow positive integer keys to toggle
set(gcf,'KeyPressFcn',@(handle,event) togglefun(handle,event,rgbimg,himg));

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
while(ishandle(himg{end}))
    if wantbypass
      [ry,rx] = ind2sub(size(Rimg),find(Rimg==1));
      rimg = double(Rimg==1);
    else
      [rimg,rx,ry]=roipoly();
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
    currentrgb = get(himg{end},'CData');
    tmprgb=bsxfun(@times,currentrgb,.75*imgroi + .25);
    set(himg{end},'cdata',tmprgb);
    
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

temp = str2double(event.Key);
if isint(temp) && temp >= 1 && temp <= length(rgbimg)
  %%currenth = findobj(gca,'type','image');
  set(himg{end},'CData',rgbimg{temp});
end
