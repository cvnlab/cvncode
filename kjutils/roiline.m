function rxy = roiline(hfig,img,xy)
%rxy = roiline(hfig,img,xy)
%
%Interactive multi-point line-drawing tool.
%
% Left-click to add new points
% Left-click and drag existing point to move it
% Left-click a line segment's midpoint to create a new point (split the
%   segment)
% Right-click an existing point to remove it
% Right-click anywhere else on the image to return the current points
%
%Inputs:
% hfig = figure handle for line drawing (default: gcf)
% img  = image matrix to display and draw on (default: current image)
% xy   = Nx2 initial xy points for roiline (default: [])
%
%Outputs:
% rxy  = Nx2 [x y] coordinates of points in the specified line
%
%Example:
% [~,Lookup,rgbimg] = cvnlookupimages(...)
% figure;
% imshow(rgbimg);
% rxy = roiline
% %draw line segments....
% %right click to return
% rxy =
%
%          24.578          43.628
%          35.638          37.195
%          42.320          26.961
%          57.066          26.377

rxy=[];

if(~exist('hfig','var') || isempty(hfig))
    hfig=gcf;
end

if(~exist('img','var') || isempty(img))
    img=[];
end

if(~exist('xy','var') || isempty(xy))
    xy=[nan nan];
end

if(~isempty(img))
    himg=image(img);
else
    himg=findobj(hfig,'type','image');
end


if(isempty(himg))
    return;
end
ax=get(himg,'Parent');

set(himg,'hittest','off');
set(ax,'buttondownfcn',@roiline_callback);
set(hfig,'windowbuttonmotionfcn',@roiline_mousemove,'windowbuttonupfcn',@roiline_mouseup);
set(hfig,'windowkeypressfcn',@roiline_keypress);

roilinestyle={'-','color','b','tag','roiline'};
roipointstyle={'o','color','b','markerfacecolor','w','markersize',9,'tag','roipoint'};
roimidpointstyle={'d','color','b','markerfacecolor','w','markersize',7,'tag','roimidpoint'};
points=xy;
if(size(points,1)>1)
    midpoints=(points(1:end-1,:)+points(2:end,:))/2;
else
    midpoints=[nan nan];
end

hl=findobj(hfig,'tag','roiline');
if(~isempty(hl))
    delete(hl);
end
hp=findobj(hfig,'tag','roipoint');
if(~isempty(hp))
    delete(hp);
end
hp=findobj(hfig,'tag','roimidpoint');
if(~isempty(hp))
    delete(hp);
end

hold on;
hl=plot(ax,points(:,1),points(:,2),roilinestyle{:});
hp=plot(ax,points(:,1),points(:,2),roipointstyle{:});
hmp=plot(ax,midpoints(:,1),midpoints(:,2),roimidpointstyle{:});

htag=plot(ax,nan,nan,'tag','roiline_is_drawing');

set([hp hmp],'hittest','on','buttondownfcn',@roiline_callback);

mousedown=false;
mousedown_pointidx=0;
M=fillstruct(hfig,ax,himg,points,midpoints,hp,hl,hmp,htag,...
    roilinestyle,roipointstyle,roimidpointstyle,mousedown,mousedown_pointidx);
setappdata(hfig,'data',M);

%%%%%
fprintf('\nroiline instructions:\n');
fprintf('======================\n');
fprintf('Left-click to add new points\n');
fprintf('Left-click and drag existing point to move it\n');
fprintf('Left-click a line segment''s midpoint to create a new point (split the segment)\n');
fprintf('Right-click an existing point to remove it\n');
fprintf('\nRight-click anywhere else on the image to return the current points\n');
fprintf('Close window or press Escape to cancel\n');

%%%%%
waitfor(htag);
if(~ishandle(hfig))
    return;
end
M=getappdata(hfig,'data');
set(ax,'buttondownfcn',[]);
set(hfig,'windowbuttonmotionfcn',[],'windowbuttonupfcn',[]);
set(hfig,'windowkeypressfcn',[]);
set([hp hmp],'buttondownfcn',[]);
rxy=M.points;

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiline_update(hfig)
M=getappdata(hfig,'data');
if(isempty(M.points))
    set(M.hl,'xdata',nan,'ydata',nan);
    set(M.hp,'xdata',nan,'ydata',nan);
else
    set(M.hl,'xdata',M.points(:,1),'ydata',M.points(:,2));
    set(M.hp,'xdata',M.points(:,1),'ydata',M.points(:,2));
end

if(isempty(M.midpoints))
    set(M.hmp,'xdata',nan,'ydata',nan);
else
    set(M.hmp,'xdata',M.midpoints(:,1),'ydata',M.midpoints(:,2));
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function roiline_callback(gcbo,eventdata)
hfig=gcbf;
M=getappdata(hfig,'data');

rightclick = strcmpi(get(hfig,'SelectionType'),'alt');


p=get(M.ax,'currentpoint');
p=p(1,[1 2]);

if(isequal(get(gcbo,'tag'),'roipoint'))
    D=distance(M.points.',p.');
    [~,idx]=min(D(:));

    if(rightclick)
        if(size(M.points,1)>0)
            M.points(idx,:)=[];
        end
    else
        M.mousedown=true;
        M.mousedown_pointidx=idx;
    end
elseif(isequal(get(gcbo,'tag'),'roimidpoint'))
    D=distance(M.midpoints.',p.');
    [~,idx]=min(D(:));

    if(rightclick)
        %nothing to do for right click on midpoint
    else

        points=zeros(size(M.points,1)+1,2);
        points(1:idx,:)=M.points(1:idx,:);
        points(idx+1,:)=M.midpoints(idx,:);
        points(idx+2:end,:)=M.points(idx+1:end,:);
        
        M.points=points;
        M.mousedown_pointidx=idx+1;
        M.mousedown=true;
    end

else
    %new click add point

    if(rightclick)
        delete(M.htag);
    else
        %add point
        if(isempty(M.points) || isnan(M.points(1,1)))
            M.points=p;
        else
            M.points=[M.points; p];
        end
        %get(M.ax)
        %get(M.ax,'view')
        %get(M.ax,'ydir')
        %get(M.ax,'xdir')
    end
end
if(size(M.points,1)>1)
    M.midpoints=(M.points(1:end-1,:)+M.points(2:end,:))/2;
else
    M.midpoints=[nan nan];
end

setappdata(hfig,'data',M);
roiline_update(hfig);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiline_mousemove(gcbo,eventdata)
hfig=gcbf;
M=getappdata(hfig,'data');
if(~M.mousedown)
    return;
end

p=get(M.ax,'currentpoint');
p=p(1,[1 2]);
if(M.mousedown_pointidx > 0)
    M.points(M.mousedown_pointidx,:)=p;
    if(size(M.points,1)>1)
        M.midpoints=(M.points(1:end-1,:)+M.points(2:end,:))/2;
    else
        M.midpoints=[nan nan];
    end
end

setappdata(hfig,'data',M);
roiline_update(hfig);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiline_mouseup(gcbo,eventdata)
hfig=gcbf;
M=getappdata(hfig,'data');
if(~M.mousedown)
    return;
end
M.mousedown=false;
M.mousedown_pointidx=0;
setappdata(hfig,'data',M);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiline_keypress(gcbo,eventdata)
hfig=gcbf;
M=getappdata(hfig,'data');
switch eventdata.Key
    case 'escape'
        M.points=[];
        setappdata(hfig,'data',M);
        delete(M.htag);
end
