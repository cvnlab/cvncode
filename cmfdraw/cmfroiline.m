function [xypoint, xyline, xylineCell, pixelmask, xypointNC] = cmfroiline(hfig,img,xy,xyNC,todo,lineIndex)
%[xypoint, xyline, xylineCell, pixelmask, xypointNC] = cmfroiline(hfig,img,xy,xyNC,todo,lineIndex)
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
xypointNC = xyNC;
xypoint=[];
xyline=[];
pixelmask=[];
xylineCell = {};

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
    %himg=image(img);
    himg=findobj(hfig,'type','image');
    if(nargin >= 5)
        [hplines, lineName] = cmfshowLines(todo,hfig,lineIndex);
        for i = 1:length(lineName)
            if lineName(i) == '_'
                lineName(i) = ' ';
            end
        end
    end
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
roipointstyleNC={'markerfacecolor','b'};

%Divde points between confident and not confident
points=xy;
pointsC = points;
if(~isempty(xyNC))
    pointsC(xyNC,:) = [];
    pointsNC = points(xyNC,:);
else
    pointsNC = [nan nan];
end
flagNC = 0;

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

%Set up text
hText = text(1000,1050,'Drawing mode: Confident','HorizontalAlignment','center');
text(1000,1100,['Drawing line: ' lineName],'HorizontalAlignment','center');

if(size(points,1)==1)
    hp1=plot(ax,points(1,1),points(1,2),roipointstyle{:},roipointstyle1{:});
    hpN=plot(ax,nan,nan,roipointstyle{:},roipointstyleN{:});
    hp=plot(ax,nan,nan,roipointstyle{:});
    hpNC=plot(ax,nan,nan,roipointstyle{:},roipointstyleNC{:});
elseif(size(points,1)==2)
    hp1=plot(ax,points(1,1),points(1,2),roipointstyle{:},roipointstyle1{:});
    hpN=plot(ax,points(end,1),points(end,2),roipointstyle{:},roipointstyleN{:});
    hp=plot(ax,nan,nan,roipointstyle{:});
    hpNC=plot(ax,nan,nan,roipointstyle{:},roipointstyleNC{:});
else
    hp1=plot(ax,points(1,1),points(1,2),roipointstyle{:},roipointstyle1{:});
    hpN=plot(ax,points(end,1),points(end,2),roipointstyle{:},roipointstyleN{:});
    if(~isempty(xyNC) && xyNC(end) == size(points,1))
        hp=plot(ax,pointsC(2:end,1),pointsC(2:end,2),roipointstyle{:});
        hpNC=plot(ax,pointsNC(1:end-1,1),pointsNC(1:end-1,2),roipointstyle{:},roipointstyleNC{:});
    else
        hp=plot(ax,pointsC(2:end-1,1),pointsC(2:end-1,2),roipointstyle{:});
        hpNC=plot(ax,pointsNC(1:end,1),pointsNC(1:end,2),roipointstyle{:},roipointstyleNC{:});
    end
end

hmp=plot(ax,midpoints(:,1),midpoints(:,2),roimidpointstyle{:});

htag=plot(ax,nan,nan,'tag','roiline_is_drawing');

set([hp1 hpN hp hmp hpNC ],'hittest','on','buttondownfcn',@roiline_callback);
for i = 1:length(hplines)
    set(hplines{i},'hittest','on','buttondownfcn',@roiline_callback);
end
mousedown=false;
mousedown_pointidx=0;
mousedown_initxy=[];
mousedown_points=[];
cursormode='draw';
M=fillstruct(hfig,ax,himg,points,pointsC,pointsNC,xyNC,midpoints,hp,hp1,hpN,hpNC,hl,hmp,htag,...
    roilinestyle,roipointstyle,roimidpointstyle,roipointstyle1,roipointstyleN,...
    cursormode,mousedown,mousedown_pointidx,mousedown_initxy,mousedown_points,flagNC,hText);
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
waitfor(htag);
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
xypointNC = M.xyNC;
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

%Split points by type
pointType = zeros(size(xypoint,1),1);
pointType(xypointNC) = 1;
types = [];
pointsTodo = {};
%j is line segment number, start at 1
j = 1;
for i = 1:size(xypoint,1)
    switch i
        case 1
        %if first point, then load in first row
        pointsTemp(1,1:2) = xypoint(1,:);
        types(j) = pointType(i);
        j = j+1;
        otherwise
            if (pointType(i) == pointType(i-1))
                %continue line segment
                pointsTemp(end+1,1:2) = xypoint(i,:);
            else
                %check type of segment
                if (pointType(i) == 1)
                    %Not confident, load in last confident point to first row
                    %new segment
                    pointsTodo{end+1} = pointsTemp;
                    pointsTemp = [];
                    pointsTemp(1,1:2) = xypoint(i-1,:);
                    pointsTemp(2,1:2) = xypoint(i,:);
                    types(j) = 1;
                    j = j+1;
                end
                if (pointType(i) == 0)
                    %Confident, load point in last row and new first row
                    pointsTemp(end+1,1:2) = xypoint(i,:);
                    pointsTodo{end+1} = pointsTemp;
                    pointsTemp = [];
                    pointsTemp(1,1:2) = xypoint(i,:);
                    types(j) = 0;
                    j = j+1;
                end
            end
            if (i == size(xypoint,1))
                pointsTodo{end+1} = pointsTemp;
                types(j) = pointType(j);
            end
    end
end
segmentsNum = size(pointsTodo,2);
xylineCell = {[types]};
for i = 1:segmentsNum
    pointCur = pointsTodo{i};
    if(size(pointCur,1) <= 1)
        types(i)= [];
        xylineCell{1} = types;
        continue
    end
    
    % rasterize line segments by interp1 with extra points (2*max), then prune
    xyd=[0; sqrt(sum((pointCur(2:end,:)-pointCur(1:end-1,:)).^2,2))];
    d=sum(xyd);
    xyi=interp1(linspace(0,1,size(pointCur,1)),pointCur,linspace(0,1,2*d));
    xyi=round(xyi);
    xyi=xyi(any(xyi(2:end,:)~=xyi(1:end-1,:),2),:);
    
    % prune again to remove "corners"
    xyi2=xyi;
    n=1;
    for i = 2:size(xyi,1)-1
        if(all(xyi2(n,:)==xyi(i,:) | xyi(i+1,:)==xyi(i,:)))
        else
            n=n+1;
            xyi2(n,:)=xyi(i,:);
        end
    end
    xylineCell{end+1}=[xyi2(1:n,:); xyi(end,:)];
end
%pixelmask(sub2ind(size(pixelmask),xyline(:,2),xyline(:,1)))=1;

xyd=[0; sqrt(sum((xypoint(2:end,:)-xypoint(1:end-1,:)).^2,2))];
d=sum(xyd);
xyi=interp1(linspace(0,1,size(xypoint,1)),xypoint,linspace(0,1,2*d));
xyi=round(xyi);
xyi=xyi(any(xyi(2:end,:)~=xyi(1:end-1,:),2),:);

% prune again to remove "corners"
xyi2=xyi;
n=1;
for i = 2:size(xyi,1)-1
    if(all(xyi2(n,:)==xyi(i,:) | xyi(i+1,:)==xyi(i,:)))
    else
        n=n+1;
        xyi2(n,:)=xyi(i,:);
    end
end
xyline=[xyi2(1:n,:); xyi(end,:)];



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
    set(M.hpNC,'xdata',nan,'ydata',nan);
else
    set(M.hl,'xdata',M.points(:,1),'ydata',M.points(:,2));

    if(size(M.points,1)==1)
        set(M.hp1,'xdata',M.points(1,1),'ydata',M.points(1,2));
        set(M.hpN,'xdata',nan,'ydata',nan);
        set(M.hpNC,'xdata',nan,'ydata',nan);
        set(M.hp,'xdata',nan,'ydata',nan);
    elseif(size(M.points,1)==2)
        set(M.hp1,'xdata',M.points(1,1),'ydata',M.points(1,2));
        set(M.hpN,'xdata',M.points(end,1),'ydata',M.points(end,2));
        set(M.hpNC,'xdata',nan,'ydata',nan);
        set(M.hp,'xdata',nan,'ydata',nan);
    else
        set(M.hp1,'xdata',M.points(1,1),'ydata',M.points(1,2));
        set(M.hpN,'xdata',M.points(end,1),'ydata',M.points(end,2));
        if(~isempty(M.xyNC) && M.xyNC(end) == size(M.points,1))
            set(M.hp,'xdata',M.pointsC(2:end,1),'ydata',M.pointsC(2:end,2));
            set(M.hpNC,'xdata',M.pointsNC(1:end-1,1),'ydata',M.pointsNC(1:end-1,2));
        else
            set(M.hp,'xdata',M.pointsC(2:end-1,1),'ydata',M.pointsC(2:end-1,2));
            set(M.hpNC,'xdata',M.pointsNC(:,1),'ydata',M.pointsNC(:,2));
        end
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

function roiline_callback(gcbo,eventdata)
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
            pointsNC = M.xyNC(M.xyNC<=idx);
            if(~isempty(pointsNC) && pointsNC(end) == idx)
            pointsNC(end) = [];
            end
            temp = M.xyNC(M.xyNC>idx)-1;
            pointsNC = horzcat(pointsNC,temp);
            M.xyNC = pointsNC;
            M.pointsNC = M.points(M.xyNC,:);
            M.pointsC = M.points;
            M.pointsC(M.xyNC,:) = [];
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
            pointsNC = M.xyNC(M.xyNC<=idx);
            if(M.flagNC)
            pointsNC(end+1) = idx+1;
            end
            temp = M.xyNC(M.xyNC>=idx)+1;
            pointsNC = horzcat(pointsNC,temp);
            M.xyNC = pointsNC;
            M.pointsNC = M.points(M.xyNC,:);
            M.pointsC = M.points;
            M.pointsC(M.xyNC,:) = [];
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
            if(M.flagNC)
                M.pointsNC = p;
                M.xyNC = 1;
            else M.pointsC = p;
            end
        else
            M.points=[M.points; p];
            if(M.flagNC)
                M.xyNC(end+1) = size(M.points,1);
            end
                M.pointsC = M.points;
                M.pointsC(M.xyNC,:) = [];
                M.pointsNC = M.points(M.xyNC,:);
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
    M.pointsC = M.points;
    M.pointsC(M.xyNC,:) = [];
    M.pointsNC = M.points(M.xyNC,:);
    if(size(M.points,1)>1)
        M.midpoints=(M.points(1:end-1,:)+M.points(2:end,:))/2;
    else
        M.midpoints=[nan nan];
    end
else
    if(M.mousedown_pointidx > 0)
        M.points(M.mousedown_pointidx,:)=p;
        M.pointsC = M.points;
        M.pointsC(M.xyNC,:) = [];
        M.pointsNC = M.points(M.xyNC,:);
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
    case 'c'
        M.flagNC = ~M.flagNC;
        switch M.flagNC
            case 0
                set(M.hText,'String','Drawing mode: Confident')
            case 1
                set(M.hText,'String','Drawing mode: Unsure')
        end
        setappdata(hfig,'data',M);
        
end
