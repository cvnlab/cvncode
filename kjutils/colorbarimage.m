function img = colorbarimage(range,ticks,cmap,imgsize,varargin)
%img = colorbarimage(range,ticks,cmap,imgsize,'param',value,...)
%
%Returns a rasterized colorbar image suitable for saving to file
%
%Inputs:
%   range
%   ticks
%   cmap
%   imgsize
%
%Options: 'paramname','value',...
%   tickformat
%   tickcolor
%   bgcolor
%   showbounds
%   fontsize
%   padding
%   antialias

p = inputParser;
p.KeepUnmatched = true;
p.addParamValue('tickformat',[]);
p.addParamValue('tickcolor',[0 0 0]);
p.addParamValue('bgcolor',[1 1 1]);
p.addParamValue('padding',5);
p.addParamValue('showbounds',false);
p.addParamValue('fontsize',[]);
p.addParamValue('fontcolor',[]);
p.addParamValue('xlabel',[]);
p.addParamValue('ylabel',[]);
p.addParamValue('antialias',1);
p.parse(varargin{:});
r = p.Results;

axargs=struct2args(p.Unmatched);

cmin=min(range);
cmax=max(range);

bgcolor=colorspec2rgb(r.bgcolor);
antialias=round(r.antialias);

if(isempty(r.fontcolor))
    tickcolor=colorspec2rgb(r.tickcolor);
else
    tickcolor=colorspec2rgb(r.fontcolor);
end

if(r.padding > 0)
    %imgsize=imgsize-2*r.padding;
    imgsize(2)=imgsize(2)-2*r.padding;
end

if(antialias>1)
    imgsize=imgsize*antialias;
    r.fontsize=r.fontsize*antialias;
end

if(isempty(ticks))
    fig = figure('IntegerHandle','off','visible','off');
    hc=colorbar;
    set(gca,'clim',[cmin cmax]);
    set(hc,'units','pixels');
    p = get(hc,'position');
    p(4) = imgsize(1);
    set(hc,'position',p);
    ticks = get(hc,'ytick');
    close(fig);
end

if(r.showbounds)
    ticks = [ticks(:); cmin; cmax];
end
ticks = sort(unique(ticks));

fig = figure('IntegerHandle','off','menubar','none','toolbar','none',...
    'color',bgcolor,'visible','off','position',[0 0 max(imgsize) 1.25*max(imgsize)]);

if(ischar(cmap))
    cmap=evalin('caller',[cmap '(256)']);
end
cmap_sz = size(cmap,1);
cimg = interp1(1:cmap_sz,cmap,linspace(1,cmap_sz,imgsize(1)));
cimg = reshape(cimg,[imgsize(1) 1 3]);
cimg = repmat(cimg, [1 imgsize(2) 1]);

tickpos = imgsize(1)*(ticks-cmin)/(cmax-cmin)+.5;
tickpos = min(max(tickpos,.5),imgsize(1)-.5);
if(~isempty(r.tickformat))
    ticks = cellfun(@(a)sprintf(r.tickformat,a),num2cell(ticks),'uniformoutput',false);
end


image(cimg);
axis image;

ax = gca;
axis on;
axis xy;
set(ax,'ytick',tickpos,'yticklabel',ticks,'xtick',[],...
    'yaxislocation','right','tickdir','in','ycolor',tickcolor,'xcolor',tickcolor,axargs{:});

fontax=ax;

if(~isempty(r.xlabel))
    set(get(ax,'xlabel'),'string',r.xlabel);
    fontax=[fontax get(ax,'xlabel')];
end
if(~isempty(r.ylabel))
    set(get(ax,'ylabel'),'string',r.ylabel);
    fontax=[fontax get(ax,'ylabel')];
end

if(~isempty(r.fontsize))
    set(fontax,'fontsize',r.fontsize);
else
    r.fontsize=get(ax,'fontsize');
end

sc=.78; % best for >= 200
%sc=.85;

set(fig,'units','normalized');
p=get(ax,'position');
set(ax,'position',[p(1) .1 p(3) sc]);

img = export_fig(ax,'-a1');

rsz=size(img,1)/imgsize(1);


%fprintf('rsz=%.4f, sc=%.4f imgh=%d\n',rsz,sc,size(img,1))
%close(fig);
%return;
tol=.01;
dscalar=0.01;


if(rsz>=(1-tol) && rsz<=1)
else
    %optimize axis size to match image size
    s1=tic;
    i1=0;
    i2=0;
    if(rsz>1)
        [img,sc,i1]=findsize(ax,img,imgsize,20,(1-dscalar),tol);
        [img,sc,i2]=findsize(ax,img,imgsize,20,(1+dscalar/2),tol/2);
    elseif(rsz<1)
        [img,sc,i1]=findsize(ax,img,imgsize,20,(1+dscalar),tol);
        [img,sc,i2]=findsize(ax,img,imgsize,20,(1-dscalar/2),tol/2);

    end
    %fprintf('took %d+%d=%d iter, %.3f sec to reach %.3f, imgh=%d/%d = %.2f\n',i1,i2,i1+i2,toc(s1),sc,size(img,1),imgsize(1),size(img,1)/imgsize(1));
end

if(size(img,3)==1)
    img=repmat(img,1,1,3);
end
if(isequal(class(img),'uint8'))
    img=double(img)/255;
end

if(antialias>1)
    %fprintf('resizing %d\n',antialias);
    %%
    [x,y] = meshgrid(linspace(0,1,size(img,2)),linspace(0,1,size(img,1)));
    [x2,y2] = meshgrid(linspace(0,1,size(img,2)/antialias),linspace(0,1,size(img,1)/antialias));

    img2=zeros([size(x2) 3]);

    kern=gaussian(linspace(-1,1,5),0,1);
    kern=kern'*kern;
    kern=kern/sum(kern(:));
    kernpad=2*size(kern,1);
    imgpad=padimage(img,kernpad,bgcolor);
    for i = 1:3
        imgf=conv2(double(imgpad(:,:,i)),kern,'same');
        imgf=imgf(kernpad+(1:size(img,1)),kernpad+(1:size(img,2)));
        img2(:,:,i)=interp2(x,y,imgf,x2,y2,'cubic');
    end
    
    %img2=min(255,max(0,uint8(round(img2))));
    img2=min(1,max(0,img2));
    img=img2;
    imgsize=imgsize/antialias;
    %%
    %img=imresize(img,1/antialias);
end
%if(~isempty(r.antialias) && round(r.antialias)>1)
%    img = export_fig(ax,sprintf('-a%d',round(r.antialias)));
%end
%img = padimageto(CropBGColor(img,255*bgcolor),sz,5,255*bgcolor);
if(size(img,1)>imgsize(1))
    img=imresize(img,imgsize(1)/size(img,1));
end

if(r.padding>0)
    %imgsize=imgsize+2*r.padding;
    imgsize(2)=imgsize(2)+2*r.padding;
end
img = padimageto(img,imgsize,5,bgcolor);


close(fig);

%%
function [img,p4,i]=findsize(ax,img,imgsize,maxiter,scalar,tol)

i=0;
p=get(ax,'position');
p4=p(4);

rsz=size(img,1)/imgsize(1);

%fprintf('starting scalar=%.3f p4=%.3f imgh=%d/%d = %.2f\n',scalar,p(4),size(img,1),imgsize(1),size(img,1)/imgsize(1));

%if(rsz==1)
if(rsz>=(1-tol) && rsz<=1)
    %fprintf('skipping! perfect match!\n');
    return;
elseif(sign(rsz-1) == sign(scalar-1))
    %fprintf('skipping! wrong way\n');
    %going the wrong direction
    return;
end


sz_all=zeros(maxiter+1,1);
sz_all(1)=size(img,1);

p(4)=p(4)/(rsz*scalar);
for i = 1:maxiter
    %p=get(ax,'position');
    p(4)=p(4)*scalar;
    
    %p=[p(1) .1 p(3) p(4)*scalar];
    set(ax,'position',p);
    img1 = export_fig(ax,'-a1');
    
    %if(size(img1,1)==size(img,1))
    if(any(sz_all(1:i)==size(img1,1)))
        %fprintf('breaking iter=%d! not changing!\n',i);
        %size is not changing!
        break;
    end
    sz_all(i+1)=size(img1,1);
    rsz=size(img1,1)/imgsize(1);
    %if(rsz==1)
    if(rsz>=(1-tol) && rsz<=1)
        %just right

        img=img1;
        p4=p(4);
        %fprintf('breaking scalar=%.3f, iter=%d p4=%.3f, imgh=%d/%d = %.2f\n',scalar, i, p(4),size(img,1),imgsize(1),size(img,1)/imgsize(1));
            
        break;
    elseif(sign(rsz-1) == sign(scalar-1))
        if(scalar < 1)
            img=img1;
            p4=p(4);
        end
        %img=img1;
        %p4=p(4);
        %fprintf('breaking scalar=%.3f, iter=%d, too far! imgh=%d/%d\n',scalar,i,size(img,1),imgsize(1));
        %we've gone too far
        break;
    else
        %fprintf('iter=%d, imgh=%d/%d\n',i,size(img1,1),size(img,1));
        %keep going
        %p4=p(4);
        img=img1;
    end
    
end
p=get(ax,'position');
set(ax,'position',[p(1) .1 p(3) p4]);

%if(i==maxiter)
%fprintf('iter limit! scalar=%.3f p4=%.4f p(4)=%.4f imgh=%d/%d\n',scalar,p4,p(4),size(img,1),imgsize(1));
%end