function fullscreen(fig,horzvert,makesquare)
%makes figure fullscreen

if(nargin < 2 || isempty(horzvert))
    horzvert = '';
end
if(nargin < 3 || isempty(makesquare))
    makesquare = false;
end
if(ischar(makesquare) && lower(makesquare(1))=='s')
    makesquare = true;
else
    makesquare = false;
end

if(nargin == 1 && ischar(fig))
    horzvert = fig;
    fig = [];
end

if(nargin < 1 || isempty(fig))
    fig = gcf;
end

if(~isempty(horzvert))
    horzvert = lower(horzvert(1));
end
   
u = get(0,'units');
%set(0,'units','pixels');
sz = get(0,'screensize');
if(horzvert == 'v')
    p = get(fig,'position');
    sz(1) = p(1);
    if(makesquare)
        sz(3)=sz(4);
    else
        sz(3) = p(3);
    end
elseif(horzvert == 'h')
    p = get(fig,'position');
    sz(2) = p(2);
 
    if(makesquare)
        sz(4)=sz(3);
    else
        sz(4) = p(4);
    end
end
set(fig,'units',u,'position',sz);