function [xypoint, xyline, pixelmask] = roiline(hfig,img,xy,numlines,wantbypass)
%[xypoint, xyline, pixelmask] = roiline(hfig,img,xy)
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
% xy   = Px2 initial xy points for roiline (default: [])
% numlines = [] means do nothing special.
%            otherwise, should be the number of lines (>=2) to draw.
%            the expectation is that the user clicks 4 points
%            and we draw "fanning" lines between 1->2 and 4->3.
%            these lines are linearly and evenly spaced, and we
%            return xyline as a cell vector.
%
%Outputs:
% xypoint  = Px2 [x y] coordinates of points in the specified line
% xyline   = (>P)x2 [x y] coordinates of pixels along rasterized line
% pixelmask  = MxN binary mask of rasterized line segments
%
%Example:
% >> [~,Lookup,rgbimg] = cvnlookupimages(...)
% >> figure;
% >> imshow(rgbimg);
% >> [xypoint,xyline,pixelmask] = roiline;
% %click points to draw line segments....
% %right click to return
% xypoint =
%
%          24.578          43.628
%          35.638          37.195
%          42.320          26.961
%          57.066          26.377
% xyline = 
%     25    44
%     26    43
%     27    42
%     ...
%     54    26
%     55    26
%     56    26
%          
% >> imagesc(pixelmask);

xypoint=[];
xyline=[];
pixelmask=[];

if(~exist('hfig','var') || isempty(hfig))
    hfig=gcf;
end

if(~exist('img','var') || isempty(img))
    img=[];
end

if(~exist('xy','var') || isempty(xy))
    xy=[nan nan];
end

if(~exist('numlines','var') || isempty(numlines))
    numlines = [];
end

if(~exist('wantbypass','var') || isempty(wantbypass))
    wantbypass = 0;
end

if(~isempty(img))
    himg=image(img);
else
    himg=findobj(hfig,'type','image');
end

htag=findobj(hfig,'tag','roiline_is_drawing');
if(ishandle(htag))
    warning('roiline already in progress for this figure...\n');
    return;
end

if(isempty(himg))
    return;
end
ax=get(himg,'Parent');
imgsize=size(get(himg,'cdata'));
imgsize=imgsize(1:2);

set(himg,'hittest','off');
set(ax,'hittest','on','xtick',[],'ytick',[],'visible','on'); %if imshow(), need to make axes visible
set(ax,'buttondownfcn',@roiline_callback);
set(hfig,'windowbuttonmotionfcn',@roiline_mousemove,'windowbuttonupfcn',@roiline_mouseup);
set(hfig,'windowkeypressfcn',@roiline_keypress);

roilinestyle={'linestyle','-','color','b','tag','roiline'};
roipointstyle={'marker','o','linestyle','none','color','b','markerfacecolor','w','markersize',9,'tag','roipoint'};
roimidpointstyle={'marker','d','linestyle','none','color','b','markerfacecolor','w','markersize',7,'tag','roimidpoint'};
roipointstyle1={'markerfacecolor','g'};
roipointstyleN={'markerfacecolor','r'};

points=xy;
if(size(points,1)>1)
    midpoints=(points(1:end-1,:)+points(2:end,:))/2;
else
    midpoints=[nan nan];
end

tagdelete={'roiline','roipoint','roimidpoint'};
for td = 1:numel(tagdelete)
    hl=findobj(hfig,'tag',tagdelete{td});
    if(~isempty(hl))
        delete(hl);
    end
end

hold on;
hl=plot(ax,points(:,1),points(:,2),roilinestyle{:});

if(size(points,1)==1)
    hp1=plot(ax,points(1,1),points(1,2),roipointstyle{:},roipointstyle1{:});
    hpN=plot(ax,nan,nan,roipointstyle{:},roipointstyleN{:});
    hp=plot(ax,nan,nan,roipointstyle{:});
elseif(size(points,1)==2)
    hp1=plot(ax,points(1,1),points(1,2),roipointstyle{:},roipointstyle1{:});
    hpN=plot(ax,points(end,1),points(end,2),roipointstyle{:},roipointstyleN{:});
    hp=plot(ax,nan,nan,roipointstyle{:});
else
    hp1=plot(ax,points(1,1),points(1,2),roipointstyle{:},roipointstyle1{:});
    hpN=plot(ax,points(end,1),points(end,2),roipointstyle{:},roipointstyleN{:});
    hp=plot(ax,points(2:end-1,1),points(2:end-1,2),roipointstyle{:});
end

hmp=plot(ax,midpoints(:,1),midpoints(:,2),roimidpointstyle{:});

htag=plot(ax,nan,nan,'tag','roiline_is_drawing');

set([hp1 hpN hp hmp],'hittest','on','buttondownfcn',@roiline_callback);

mousedown=false;
mousedown_pointidx=0;
mousedown_initxy=[];
mousedown_points=[];
cursormode='draw';
M=fillstruct(hfig,ax,himg,points,midpoints,hp,hp1,hpN,hl,hmp,htag,...
    roilinestyle,roipointstyle,roimidpointstyle,roipointstyle1,roipointstyleN,...
    cursormode,mousedown,mousedown_pointidx,mousedown_initxy,mousedown_points);
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
fprintf('...\n');

%%%%% wait for user to finish

if wantbypass  % if the user just wants to immediately do a right-click
  roiline_callback([],[],hfig);
else
  waitfor(htag);
end
if(~ishandle(hfig))
    return;
end
M=getappdata(hfig,'data');
set(ax,'buttondownfcn',[]);
set(hfig,'pointer','arrow');
set(hfig,'windowbuttonmotionfcn',[],'windowbuttonupfcn',[]);
set(hfig,'windowkeypressfcn',[]);
set([hp hp1 hpN hmp],'buttondownfcn',[]);
xypoint=M.points;

fprintf('ROI selection:\n');
disp(xypoint);

if(nargout < 2)
    return;
end

% generate binary pixel mask of line segments
pixelmask=zeros(imgsize);
if(isempty(xypoint) || isnan(xypoint(1,1)))
    return;
end
if(size(xypoint,1)==1)
    xyi=round(xypoint);
    pixelmask(xyi(2),xyi(1))=1;
    return;
end

if isempty(numlines)
  xyline = roiline_calcline(xypoint);
  pixelmask(sub2ind(size(pixelmask),xyline(:,2),xyline(:,1)))=1;
else
  xyline = {};
  for zz=1:numlines
    pts1 = xypoint(1,:) + (xypoint(4,:)-xypoint(1,:)) * (zz-1)/(numlines-1);
    pts2 = xypoint(2,:) + (xypoint(3,:)-xypoint(2,:)) * (zz-1)/(numlines-1);
    xyline{zz} = roiline_calcline([pts1; pts2]);
    pixelmask(sub2ind(size(pixelmask),xyline{zz}(:,2),xyline{zz}(:,1)))=1;
  end
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function roiline_update(hfig)
M=getappdata(hfig,'data');
% 
% lstyle=M.roilinestyle;
% pstyle=M.roipointstyle;
% p1style=M.roipointstyle1;
% pNstyle=M.roipointstyleN;

mpstyle=M.roimidpointstyle;
    
if(isequal(M.cursormode,'move'))
    mpstyle=[mpstyle 'marker' 'none'];
end

if(~isempty(mpstyle))
    set(M.hmp,mpstyle{:});
end

if(isempty(M.points))
    set(M.hl,'xdata',nan,'ydata',nan);
    set(M.hp1,'xdata',nan,'ydata',nan);
    set(M.hpN,'xdata',nan,'ydata',nan);
    set(M.hp,'xdata',nan,'ydata',nan);
else
    set(M.hl,'xdata',M.points(:,1),'ydata',M.points(:,2));

    if(size(M.points,1)==1)
        set(M.hp1,'xdata',M.points(1,1),'ydata',M.points(1,2));
        set(M.hpN,'xdata',nan,'ydata',nan);
        set(M.hp,'xdata',nan,'ydata',nan);
    elseif(size(M.points,1)==2)
        set(M.hp1,'xdata',M.points(1,1),'ydata',M.points(1,2));
        set(M.hpN,'xdata',M.points(end,1),'ydata',M.points(end,2));
        set(M.hp,'xdata',nan,'ydata',nan);
    else
        set(M.hp1,'xdata',M.points(1,1),'ydata',M.points(1,2));
        set(M.hpN,'xdata',M.points(end,1),'ydata',M.points(end,2));
        set(M.hp,'xdata',M.points(2:end-1,1),'ydata',M.points(2:end-1,2));
    end
    
end

if(isempty(M.midpoints))
    set(M.hmp,'xdata',nan,'ydata',nan);
else
    set(M.hmp,'xdata',M.midpoints(:,1),'ydata',M.midpoints(:,2));
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function roiline_callback(gcbo,eventdata,bypass)

% just act like a right-click occurred
if exist('bypass','var')
  hfig=bypass;
  M=getappdata(hfig,'data');
  set(M.hmp,'visible','off');
  delete(M.htag);
  setappdata(hfig,'data',M);
  roiline_update(hfig);
  return;
end

hfig=gcbf;
M=getappdata(hfig,'data');

rightclick = strcmpi(get(hfig,'SelectionType'),'alt');


p=get(M.ax,'currentpoint');
p=p(1,[1 2]);

if(isequal(M.cursormode,'move'))
    if(rightclick)
        set(M.hmp,'visible','off');
        delete(M.htag);
        setappdata(hfig,'data',M);
        roiline_update(hfig);
    else
        M.mousedown=true;

        M.mousedown_pointidx=-1;
        M.mousedown_initxy=p;
        M.mousedown_points=M.points;
        setappdata(hfig,'data',M);
    end
    return;
end

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
        set(M.hmp,'visible','off');
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

if(isequal(M.cursormode,'move'))
    d=p-M.mousedown_initxy;
    M.points=bsxfun(@plus,M.mousedown_points,d);
    if(size(M.points,1)>1)
        M.midpoints=(M.points(1:end-1,:)+M.points(2:end,:))/2;
    else
        M.midpoints=[nan nan];
    end
else
    if(M.mousedown_pointidx > 0)
        M.points(M.mousedown_pointidx,:)=p;
        if(size(M.points,1)>1)
            M.midpoints=(M.points(1:end-1,:)+M.points(2:end,:))/2;
        else
            M.midpoints=[nan nan];
        end
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
        M.midpoints=[];
        M.cursormode='draw';
        setappdata(hfig,'data',M);
        roiline_update(hfig);
        M.points=[];
        setappdata(hfig,'data',M);
        delete(M.htag);
    case 'm'
        if(isequal(M.cursormode,'move'))
            M.cursormode='draw';
            set(hfig,'Pointer','arrow');
        else
            M.cursormode='move';
            set(hfig,'Pointer','fleur');
        end
        setappdata(hfig,'data',M);
        roiline_update(hfig);
        
end
