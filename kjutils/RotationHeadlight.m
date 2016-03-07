function RotationHeadlight(fig, do_mousemove)

if(nargin < 1)
    fig = gcf;
end

if(nargin < 2)
    do_mousemove = false;
end

hrot = rotate3d(fig);

if(do_mousemove)
    set(hrot,'ActionPreCallback',@RotateStart);
end

RefreshHeadlight;
set(hrot,'ActionPostCallback',@RotateEnd);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% functions to handle lighting/rotation %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MouseMove(gcbo,eventdata,handles)
RefreshHeadlight;

function RotateStart(gcbo,eventdata,handles)
set(gcbo,'WindowButtonMotionFcn',@MouseMove);

function RotateEnd(gcbo,eventdata,handles)
set(gcbo,'WindowButtonMotionFcn','');
RefreshHeadlight;

function RefreshHeadlight
ch = get(gca,'children');
lite = ch(strcmpi(get(ch,'type'),'light'));
if(~isempty(lite))
    camlight(lite(1),'headlight');
end