function hfig = orthogui(varargin)
% hfig = orthogui(voldata,varargin)

% KWJ 2013

if(isempty(varargin) || isequal(varargin{1},'help'))
    printhelp;
    return;
end

%%%%%% can call orthogui(fig,[x y z]) to move cursor externally
if(numel(varargin) >= 1 && ischar(varargin{1}) && strcmp(varargin{1},'all'))
    f=findall(0,'type','figure');
    hfig=f(regexpmatch(get(f,'tag'),'^orthogui\.'));
    if(numel(varargin) > 1)
        orthogui(hfig,varargin{2:end});
    end
    return;
elseif(numel(varargin) > 1 && numel(varargin{1}) > 1 && ndims(varargin{1})<3 && all(ishghandle(varargin{1})) && all(~isempty(regexp(get(varargin{1},'tag'),'^orthogui'))))
    f = varargin{1};
    for i = 1:numel(f)
        orthogui(f(i),varargin{2:end});
    end
    return;
elseif(numel(varargin) > 1 && numel(varargin{1}) == 1 && ishghandle(varargin{1}) && ~isempty(regexp(get(varargin{1},'tag'),'^orthogui')))
    hfig = varargin{1};
    switch lower(varargin{2})
        case {'crosshairs'}
            M = getappdata(hfig,'guidata');
            if(nargin > 2)
                M.showcursor=varargin{3}>0;
            else
                M.showcursor=~M.showcursor;
            end
            setappdata(hfig,'guidata',M);
            updatefig(M);
        case {'clim'}
            M = getappdata(hfig,'guidata');
            cl=varargin{3};
            if(numel(cl) == 1)
                cl = [0 cl];
            end
            M.colormap_clim = cl;
            set([M.ax M.axmip],'clim',cl);
            setappdata(hfig,'guidata',M);
            updatefig(M);
        case {'getlocation','getloc'}
            M = getappdata(hfig,'guidata');
            hfig =  orig2disp([M.cx M.cy M.cz],M.dimpermute,M.origsize);
        case {'setdata'}
            M = getappdata(hfig,'guidata');
            D = getappdata(hfig,'data');
            D.V = varargin{3};
            setappdata(hfig,'data',D);
            updatefig(M,false);
        case {'setalphadata'}
            M = getappdata(hfig,'guidata');
            D = getappdata(hfig,'data');
            D.Valpha = varargin{3};
            setappdata(hfig,'data',D);
            updatefig(M,false);
        case {'location','loc'}
            M = getappdata(hfig,'guidata');
            [x, y, z] = splitvars(orig2disp(varargin{3},M.dimpermute,M.origsize));
            
            M.cx = x;
            M.cy = y;
            M.cz = z;
            setappdata(hfig,'guidata',M);
            updatefig(M);
        case {'location_nocb','loc_nocb'}
            M = getappdata(hfig,'guidata');
            [x, y, z] = splitvars(orig2disp(varargin{3},M.dimpermute,M.origsize));
            M.cx = x;
            M.cy = y;
            M.cz = z;
            setappdata(hfig,'guidata',M);
            updatefig(M,false);
        case {'callback'}
            M = getappdata(hfig,'guidata');
            cb = varargin{3};
            if(~iscell(cb))
                cb = {cb};
            end
            M.cbfunc = cb;
            setappdata(hfig,'guidata',M);
        case {'addcallback'}
            M = getappdata(hfig,'guidata');
            cb = varargin{3};
            if(iscell(cb))
                M.cbfunc = [M.cbfunc cb];
            else
                M.cbfunc = [M.cbfunc {cb}];
            end
            
            setappdata(hfig,'guidata',M);         
        case {'refresh','update'}
            M = getappdata(hfig,'guidata');
            updatefig(M,false);
    end
   
    return;
    
%%%%%% main function: hfig = orthogui(V, parameters)
else
    V = double(varargin{1});
    varargin = varargin(2:end);
    
    %if(~iscell(V))
    %    V = {V};
    %end
end

%hack to avoid annoying mrVista function shadowing
if(regexpimatch(which('annotation'),'mrloadret'))
    d = justdir(which('annotation'));
    rmpath(d);
    addpath(d,'-end');
end

spmdir = justdir(which('spm'));
defaultstruct_colin = [spmdir '/canonical/single_subj_T1.nii'];
defaultstruct= [spmdir '/templates/T1.nii'];
%structimage = [spmdir '/templates/EPI.nii'];

p = inputParser;
p.addParamValue('location',[]);
p.addParamValue('loc',[]);
p.addParamValue('background',[]);
p.addParamValue('bg',[0]);
p.addParamValue('callback',{});
p.addParamValue('title','Orthoviews');
p.addParamValue('colormap','jet');
p.addParamValue('rgbvol',[]);
p.addParamValue('alpha',[]);
p.addParamValue('maxalpha',[1]);
p.addParamValue('mip',true);
p.addParamValue('dim',[]);
p.addParamValue('bgdim',[]);
p.addParamValue('link',[]);
p.addParamValue('clim',[]);
p.addParamValue('interp',[]);
p.addParamValue('cursorgap',2);
p.addParamValue('surfslices',[]);

p.parse(varargin{:});
r = p.Results;
loc = r.location;
cbfunc = r.callback;
titlestr = r.title;
bgfile = r.background;
if(isempty(bgfile))
    bgfile = r.bg;
end
if(isempty(loc))
    loc = r.loc;
end
cmap = r.colormap;
alpha = r.alpha;
maxalpha = r.maxalpha;
showmip = r.mip;
dimpermute = r.dim;
bgpermute = r.bgdim;
figlink = r.link;
rgbvol = r.rgbvol;
colormap_clim = r.clim;
interpstyle = r.interp;
cursorgap=r.cursorgap;
surfslices=r.surfslices;
showsurf=true;

if(~iscell(cbfunc))
    cbfunc = {cbfunc};
end

if(strcmpi(interpstyle,'none'))
    interpstyle = '';
end

Vbg = [];

is_bg_default = false;
if(isempty(bgfile))
    is_bg_default = true;
    bgstruct = spm_vol(defaultstruct);
    [Vbg xyz_bg] = spm_read_vols(bgstruct);
elseif(ischar(bgfile))
    if(strcmpi(bgfile,'default') || strcmpi(bgfile,'def'))
        is_bg_default = true;
        bgfile = defaultstruct;
    elseif(strcmpi(bgfile,'colin'))
        is_bg_default = true;
        bgfile = defaultstruct_colin;
    end
    bgstruct = spm_vol(bgfile);
    [Vbg xyz_bg] = spm_read_vols(bgstruct);
elseif(isstruct(bgfile))
    [Vbg xyz_bg] = spm_read_vols(bgfile);
elseif(isnumeric(bgfile))
    if(numel(bgfile) == 1)
        Vbg = bgfile*ones(size(V));
    else
        Vbg = bgfile;
    end
else
end

if(isempty(bgpermute))
    bgpermute = dimpermute;
end


if(isempty(maxalpha) && numel(alpha) == 1)
    maxalpha = alpha;
end

if(numel(maxalpha) == 0)
    if(isempty(bgfile))
        maxalpha = 1;
    else
        maxalpha = .5;
    end
end

Vrgb = [];
if(~isempty(rgbvol))
    if(numel(alpha) <= 1)
        alpha=V;
    end
    Vrgb = rgbvol;
end

Valpha = [];
if(numel(alpha) > 1)
    Valpha = abs(alpha);
    Valpha = Valpha/max(Valpha(:));    
end

origsize=size(V);

if(~isempty(interpstyle))
    %might need to pad because pcolor displays 1:N-1
    volvars = {'V','Vbg','Valpha','Vrgb'};
    for v = 1:numel(volvars)
        vv = volvars{v};
        if(isempty(eval(vv)))
            continue;
        end
        Vtmp = padarray(eval(vv),[1 1 1 0],'post','replicate');
        eval([vv '=Vtmp;']);
        clear Vtmp;
    end
end

if(~isempty(dimpermute))
    %V = cellfun(@(x)(permute(x,dimpermute)),V,'uniformoutput',false);
    if(any(dimpermute < 0))
        df = find(dimpermute < 0);
        for i = 1:numel(df)
            V = flipdim(V,df(i));
            if(~isempty(Valpha))
                Valpha = flipdim(Valpha,df(i));
            end
            if(~isempty(Vrgb))
                Vrgb = flipdim(Vrgb,df(i));
            end
        end
    end
    V = permute(V,abs(dimpermute));
    if(~isempty(Valpha))
        Valpha = permute(Valpha,abs(dimpermute));
    end
    if(~isempty(Vrgb))
        Vrgb = permute(Vrgb,[abs(dimpermute) 4]);
    end
end
sz = size(V);

if(~isempty(bgpermute))
    if(~isempty(Vbg) && ~is_bg_default)
        
        if(any(bgpermute < 0))
            df = find(bgpermute < 0);
            for i = 1:numel(df)
                Vbg = flipdim(Vbg,df(i));
            end
        end
        Vbg = permute(Vbg,abs(bgpermute));
    end
end

if(~isempty(dimpermute) && ~isempty(surfslices))
        
    %%%%%%%%%%%%%%%% handle dimension swapping for surface slices
    dimperm=abs(dimpermute);
    dimflip=dimpermute<0;

    otherdim0={[2 3],[1 3],[1 2]};

    %%%%%%% swap surfslice dimensions
    surfslices=surfslices(dimperm);
    otherdim=otherdim0(dimperm);

    %%%%%% flip surfslice in-planes 
    for i = 1:3
        od=otherdim{i};
        osz=origsize(od);
        if(dimflip(od(1)))
            surfslices{i}=cellfun(@(x)([osz(1)-x(:,1)+1 x(:,2)]),surfslices{i},'uniformoutput',false);
        end
        if(dimflip(od(2)))
            surfslices{i}=cellfun(@(x)([x(:,1) osz(2)-x(:,2)+1]),surfslices{i},'uniformoutput',false);
        end
    end

    %swap dimensions in planes
    for i = 1:3
        od=dimperm(otherdim0{i});
        if(~isequal(sort(od),od))
            surfslices{i}=cellfun(@(x)(x(:,[2 1])),surfslices{i},'uniformoutput',false);
        end
    end

    %%%%%% flip surfslice slices
    for i = 1:3
        if(dimflip(dimperm(i)))
            surfslices{i}=surfslices{i}(end:-1:1);
        end
    end

end


do_updatelinked = false;

if(isempty(loc))
    loc = round(sz/2);
elseif(ischar(loc) && strcmpi(loc,'max'))
    do_updatelinked = true;
    [~,midx] = nanmax(abs(V(:)));
    [mx my mz] = ind2sub(size(V),midx);
    loc = [mx my mz];
elseif(isnumeric(loc))
    loc=orig2disp(loc,dimpermute,origsize);
end

[cx cy cz] = splitvars(loc);

if(ischar(cmap))
    if(~any(cmap=='('))
        cmap=[cmap '(256)'];
    end
    cmap=evalin('caller',cmap);
    %cmap = eval(sprintf('%s(%d)',cmap,256));
end

if(isempty(figlink))
    figtag = 'orthogui';
else
    figtag = sprintf('orthogui.%d',figlink);
end
hfig = figure('name',titlestr,'NumberTitle','off','WindowButtonMotionFcn',@fig_mousemove,...
    'WindowButtonUpFcn',@ax_mouseup,'tag',figtag,'WindowKeyPressFcn',@fig_keypress);

bgmax = abs(nanmax(Vbg(:)));
if(isnan(bgmax) || bgmax == 0)
    Vbg = zeros(size(Vbg));
else
    Vbg = Vbg./bgmax;
end

if(isempty(bgfile))
    Vbg = 0*Vbg;
end

[mipx mipy mipz] = splitvars(round(sz/2));
[mipbg1 mipbg2 mipbg3] = bgslice(Vbg,[mipx mipy mipz],sz);
%if(~isempty(bgfile))
    [bg1 bg2 bg3] = bgslice(Vbg,[cx cy cz],sz);
%end

showcursor = true;
ax = [];
img = [];
bgimg = [];
hsurfslice = [];
hcurH = {};
hcurV = {};
hcurVmip = {};
hcurHmip = {};
mipsize = [];
mipidx = [];
imgmipbg = [];
imgmip = [];
axmip = [];


if(isempty(interpstyle))
    bgtype='image';
    voltype='imagesc';
    bgparams = {};
    volparams = {};
else
    bgtype='pcolor';
    voltype='pcolor';
    bgparams =  {'facecolor',interpstyle};
    volparams = {'facealpha',interpstyle,'facecolor',interpstyle};
end

ax(1) = axes('position',[0 .5 .5 .5]);
%if(~isempty(bgfile))
    %bgimg(1) = image([1 sz(1)],[1 sz(3)],bg1);
    bgimg(1) = plotimage([1 sz(1)-.5],[1 sz(3)-.5],bg1,bgtype);
    hold on;
%end

%img(1) = imagesc(squeeze(V(:,cy,:)).');
img(1) = plotimage([1 sz(1)-.5],[1 sz(3)-.5],squeeze(V(:,cy,:)).',voltype);
axis equal xy;
colormap(cmap);
hold on;
%[hcurV(1) hcurH(1)] = splitvars(plot([cx cx; 0 sz(3)]',[0 sz(1); cz cz]','w'));
[hcurV{1} hcurH{1}] = plotcursor(ax(1),cx,cz,[0 sz(1)],[0 sz(3)],cursorgap,'w');

ax(2) = axes('position',[.5 .5 .5 .5]);
%if(~isempty(bgfile))
    %bgimg(2) = image([1 sz(2)],[1 sz(3)],bg2);
    bgimg(2) = plotimage([1 sz(2)-.5],[1 sz(3)-.5],bg2,bgtype);
    hold on;
%end
%img(2) = imagesc(squeeze(V(cx,:,:)).');
img(2) = plotimage([1 sz(2)-.5],[1 sz(3)-.5],squeeze(V(cx,:,:)).',voltype);
axis equal xy;
colormap(cmap);
hold on;
%[hcurV(2) hcurH(2)] = splitvars(plot([cy cy; 0 sz(3)]',[0 sz(2); cz cz]','w'));
[hcurV{2} hcurH{2}] = plotcursor(ax(2),cy,cz,[0 sz(3)],[0 sz(2)],cursorgap,'w');

ax(3) = axes('position',[0 0 .5 .5]);
%if(~isempty(bgfile))
    %bgimg(3) = image([1 sz(1)],[1 sz(2)],bg3);
    bgimg(3) = plotimage([1 sz(1)-.5],[1 sz(2)-.5],bg3,bgtype);
    hold on;
%end
%img(3) = imagesc(squeeze(V(:,:,cz)).');
img(3) = plotimage([1 sz(1)-.5],[1 sz(2)-.5],squeeze(V(:,:,cz)).',voltype);
axis equal xy;
colormap(cmap);
hold on;
%[hcurV(3) hcurH(3)] = splitvars(plot([cx cx; 0 sz(2)]',[0 sz(1); cy cy]','w'));
[hcurV{3} hcurH{3}] = plotcursor(ax(3),cx,cy,[0 sz(2)],[0 sz(1)],cursorgap,'w');

if(~isempty(surfslices))
    surfslicestyle={'x','color','r','markersize',1,'hittest','off'};
    hsurfslice(1)=plot(ax(1),nan,nan,surfslicestyle{:});
    hsurfslice(2)=plot(ax(2),nan,nan,surfslicestyle{:});
    hsurfslice(3)=plot(ax(3),nan,nan,surfslicestyle{:});
end
    
hpanel = uipanel('position',[.5 0 .5 .5]);
if(showmip)
    %axhist_pos = [.5 .25 .5 .2];
    %axmip_pos = [.5 0 .5 .25];
    axhist_pos = [0 .5 1 .45];
    axmip_pos = [0 0 1 .5]; 
    axmip = axes('parent',hpanel,'outerposition',axmip_pos);
    mipbgsz = max([size(mipbg1); size(mipbg2); size(mipbg3)],[],1);
    mipbg1 = padimageto(mipbg1,mipbgsz,[],[0 0 0]);
    mipbg2 = padimageto(mipbg2,mipbgsz,[],[0 0 0]);
    mipbg3 = padimageto(mipbg3,mipbgsz,[],[0 0 0]);
    mipbg = [mipbg1 mipbg2 mipbg3];


    %unsigned MIP (mip(abs))
    [umip1 umipidx1] = nanmax(abs(V),[],2);
    [umip2 umipidx2] = nanmax(abs(V),[],1);
    [umip3 umipidx3] = nanmax(abs(V),[],3);
    
    [mip1 mipidx1] = nanmax(V,[],2);
    [mip2 mipidx2] = nanmax(V,[],1);
    [mip3 mipidx3] = nanmax(V,[],3);
    
    %%%%%%
    mip1(mip1 < umip1) = -umip1(mip1 < umip1);
    mip2(mip2 < umip2) = -umip2(mip2 < umip2);
    mip3(mip3 < umip3) = -umip3(mip3 < umip3);
    
    mipidx1(mip1 < umip1) = umipidx1(mip1 < umip1);
    mipidx2(mip2 < umip2) = umipidx2(mip2 < umip2);
    mipidx3(mip3 < umip3) = umipidx3(mip3 < umip3);
    
    mip1 = squeeze(mip1).';
    mip2 = squeeze(mip2).';
    mip3 = squeeze(mip3).';
    mipidx1 = squeeze(mipidx1).';
    mipidx2 = squeeze(mipidx2).';
    mipidx3 = squeeze(mipidx3).';
    mipidx = {mipidx1, mipidx2, mipidx3};
    
    mipsize = [size(mip1); size(mip2); size(mip3)];
    padsz = max(mipsize,[],1);
    mip1 = padimageto(mip1,padsz,[],nan);
    mip2 = padimageto(mip2,padsz,[],nan);
    mip3 = padimageto(mip3,padsz,[],nan);
    mip = [mip1 mip2 mip3];
    
    %imgmipbg = image([1 size(mip,2)],[1 size(mip,1)],mipbg);
    imgmipbg = plotimage([1 size(mip,2)],[1 size(mip,1)],mipbg,bgtype,bgparams{:});
    hold on;
    %imgmip = imagesc(mip);
    imgmip = plotimage([],[],mip,voltype);
    colormap(cmap);
    set(imgmip,'alphadata',maxalpha.*(mip ~= 0 & ~isnan(mip)),volparams{:});
    axis equal xy tight;
    set(axmip,'xtick',[],'ytick',[],'color',[0 0 0]);
    
    [hcurVmip{1} hcurHmip{1}] = plotcursor(axmip,0,0,[0 1],[0 1],0,'w');
    [hcurVmip{2} hcurHmip{2}] = plotcursor(axmip,0,0,[0 1],[0 1],0,'w');
    [hcurVmip{3} hcurHmip{3}] = plotcursor(axmip,0,0,[0 1],[0 1],0,'w');
else
   
    %axhist_pos = [.5 .05 .5 .4];
    axhist_pos = [0 0 1 .9];
end

axhist = axes('parent',hpanel,'outerposition',axhist_pos,'color',[1 1 1]);
[hx xi] = hist(V(V(:) ~= 0 & ~isnan(V(:))),100);
hhistfill = fill(xi([1 end end 1]),[0 0 max(hx) max(hx)],'k','linestyle','none','facealpha',.1);
hold on;
hbar = bar(xi,hx,1,'k');


%set(axhist, 'yscale','log');
yl = get(gca,'ylim');

hcurhist = plot([0 0],yl,'r');
set(hhistfill,'ydata',yl([1 1 2 2]));
title('Intensity hist (click to find voxel)');

if(~isempty(colormap_clim) || all(isnan(V(:))))
    cl = colormap_clim;
else
    cl = [nanmin(V(:)) nanmax(V(:))];
    if(all(cl >= 0))
        cl = [0 max(cl)];
    else
        cl = max(abs(cl))*[-1 1];
    end
end
if(~isfinite(cl(1)))
    cl(1)=nanmin(V(:));
end
if(~isfinite(cl(2)))
    cl(2)=nanmax(V(:));
end
if(cl(1) == cl(2))
    cl(2)=cl(1)+1;
end
colormap_clim = cl;

set(hfig,'color',[0 0 0]);
set(img,'alphadata',maxalpha);
set([hcurH{:} hcurV{:} hcurHmip{:} hcurVmip{:} img bgimg hbar hpanel imgmip imgmipbg hhistfill],'hittest','off');
set([ax axmip],'xtick',[],'ytick',[],'color',[0 0 0],'clim',cl);

%%%% make colorbar and fix its position
set(axhist,'clim',cl);
cb = colorbar('peer',axhist,'location','eastoutside','color',[0 0 0],'xcolor',[0 0 0],'ycolor',[0 0 0]);
pc = get(cb,'position');
ph = get(axhist,'position');
pc(2) = ph(2);
set(cb,'position',pc);
set(axhist,'position',ph);

for i = 1:numel(ax)
    set(ax(i),'ButtonDownFcn',{@ax_mousedown,i});
end

set(axhist,'ButtonDownFcn',@hist_mousedown);
set(axmip,'ButtonDownFcn',@axmip_mousedown);

curax = 1;
mouseax = [];
curax_rect = annotation(hfig,'rectangle',[0 0 1 1],'color',[1 0 0],'hittest','off');



D = fillstruct(V,Vbg,Valpha,Vrgb,surfslices);
M = fillstruct(hfig,ax,img,bgimg,bgfile,maxalpha,cx,cy,cz,...
    hcurV,hcurH,hpanel,axmip,mouseax,curax,curax_rect,hcurVmip,hcurHmip,...
    imgmip,imgmipbg,axhist,hcurhist,hsurfslice,titlestr,cbfunc,figlink,cursorgap,...
    mipsize,mipidx,colormap_clim,interpstyle,showcursor,origsize,dimpermute,showsurf);

setappdata(hfig,'guidata',M);
setappdata(hfig,'data',D);
if(do_updatelinked)
    update_linked_figures(M);
end
updatefig(M);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h = plotimage(x,y,c,type,varargin)
switch(lower(type))
    case 'pcolor'
        if(isempty(x))
            x = [1 size(c,2)];
            y = [1 size(c,1)];
        end

        if(numel(x) < size(c,2))
            x = linspace(min(x),max(x),size(c,2))-.5;
        end
        if(numel(y) < size(c,1))
            y = linspace(min(y),max(y),size(c,1))-.5;
        end

        if(size(c,3) > 1)
            h = pcolor(x,y,c(:,:,1));
            set(h,'cdata',c);
        else
            h = pcolor(x,y,c);
        end
        set(h,'linestyle','none');
    case 'imagesc'
        h = imagesc(x,y,c);
    case 'image'
        h = image(x,y,c);
end
if(numel(varargin) > 1)
    set(h,varargin{:});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function outimg = interpimg(img)
outimg = img;
return;
newimg = {};
for i = 1:size(img,3)
    newimg{i} = interp2(double(img(:,:,i)),2,'cubic');
    
    if(islogical(img))
        newimg{i} = newimg{i} > 0.75;
    end
end
outimg = cat(3,newimg{:});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatefig(M, run_callback)
if(nargin == 1)
    run_callback = true;
end
dumpstruct(M);
D = getappdata(hfig,'data');

sz = size(D.V);
sz = sz(1:3);

cx = min(sz(1),max(1,round(cx)));
cy = min(sz(2),max(1,round(cy)));
cz = min(sz(3),max(1,round(cz)));

%[cx cy cz]
s1 = squeeze(D.V(:,cy,:,1)).';
s2 = squeeze(D.V(cx,:,:,1)).';
s3 = squeeze(D.V(:,:,cz,1)).';

if(size(D.Vrgb,4) == 3)
    rgb1 = permute(squeeze(D.Vrgb(:,cy,:,:)),[2 1 3]);
    rgb2 = permute(squeeze(D.Vrgb(cx,:,:,:)),[2 1 3]);
    rgb3 = permute(squeeze(D.Vrgb(:,:,cz,:)),[2 1 3]);
else
    rgb1 = [];
    rgb2 = [];
    rgb3 = [];
end

set(hfig,'name',sprintf('%s [%d %d %d] %f',titlestr,[cx cy cz],max(D.V(cx,cy,cz,:))));
set(hcurhist,'xdata',max(D.V(cx,cy,cz,:))*[1 1]);

mask1 = any(s1 ~= 0,3) & all(~isnan(s1),3);
mask2 = any(s2 ~= 0,3) & all(~isnan(s2),3);
mask3 = any(s3 ~= 0,3) & all(~isnan(s3),3);

if(~isempty(D.Valpha))
    a1 = squeeze(D.Valpha(:,cy,:)).';
    a2 = squeeze(D.Valpha(cx,:,:)).';
    a3 = squeeze(D.Valpha(:,:,cz)).';    
    mask1 = mask1.*a1;
    mask2 = mask2.*a2;
    mask3 = mask3.*a3;
end

if(isempty(interpstyle))
    bgparams = {};
    volparams = {};
else
    bgparams =  {'facecolor',interpstyle};
    volparams = {'facealpha',interpstyle,'facecolor',interpstyle};
end

if(~isempty(volparams))
    set(img,volparams{:});
end

mask1_orig = mask1;

s1=interpimg(s1);
s2=interpimg(s2);
s3=interpimg(s3);

mask1=interpimg(mask1);
mask2=interpimg(mask2);
mask3=interpimg(mask3);

if(isempty(rgb1))
    set(img(1),'CData',s1,'alphadata',maxalpha.*mask1,'CDataMapping','scaled');
    set(img(2),'CData',s2,'alphadata',maxalpha.*mask2,'CDataMapping','scaled');
    set(img(3),'CData',s3,'alphadata',maxalpha.*mask3,'CDataMapping','scaled');
else
    
    rgb1=interpimg(rgb1);
    rgb2=interpimg(rgb2);
    rgb3=interpimg(rgb3);
    if(strcmpi(get(img(1),'type'),'image'))
        rgb1 = uint8(255*min(1,max(0,rgb1)));
        rgb2 = uint8(255*min(1,max(0,rgb2)));
        rgb3 = uint8(255*min(1,max(0,rgb3)));
    end
    set(img(1),'CData',rgb1,'alphadata',maxalpha.*mask1,'CDataMapping','direct');
    set(img(2),'CData',rgb2,'alphadata',maxalpha.*mask2,'CDataMapping','direct');
    set(img(3),'CData',rgb3,'alphadata',maxalpha.*mask3,'CDataMapping','direct');
end

if(size(mask1_orig,1) ~= size(mask1,1))
    for i = 1:numel(img)
        c=get(img(i),'cdata');
        set(img(i),'xdata',[1 size(c,2)/4],'ydata',[1 size(c,1)/4]);
    end
end

if(~isempty(bgfile))
    [bg1 bg2 bg3] = bgslice(D.Vbg,[cx cy cz],sz);
    if(~isempty(bgparams))
        set(bgimg,bgparams{:});
    end

    set(bgimg(1),'CData',bg1);
    set(bgimg(2),'CData',bg2);
    set(bgimg(3),'CData',bg3);

end

if(~isempty(curax))
    axrect = get(ax(curax),'position');
    axrect(1:2) = axrect(1:2)+.005*axrect(3:4);
    axrect(3:4) = .99*axrect(3:4);
    set(curax_rect,'units','normalized','position',axrect,'visible','on');
else
    set(curax_rect,'visible','off');
end

if(~isempty(axmip))
    [mipx mipy xl yl] = ax2mip(1,cx,cz,mipsize);
    updatecursor(hcurVmip{1},hcurHmip{1},mipx,mipy,xl,yl,0);

    [mipx mipy xl yl] = ax2mip(2,cy,cz,mipsize);
    updatecursor(hcurVmip{2},hcurHmip{2},mipx,mipy,xl,yl,0);

    [mipx mipy xl yl] = ax2mip(3,cx,cy,mipsize);
    updatecursor(hcurVmip{3},hcurHmip{3},mipx,mipy,xl,yl,0);
end

if(~isempty(D.surfslices))

    if(showsurf)
        cslice=[cy cx cz];
        dslice=[2 1 3];
        for i = 1:3
            s=cslice(i);
            d=dslice(i);
            vs=D.surfslices{d}{s};
            if(isempty(vs))
                set(hsurfslice(i),'xdata',nan,'ydata',nan);
                continue;
            end
            set(hsurfslice(i),'xdata',vs(:,1),'ydata',vs(:,2));
        end
        set(hsurfslice,'visible','on','color','g');
    else
        set(hsurfslice,'visible','off');
    end
end

if(showcursor)
    set([hcurV{:} hcurH{:}],'visible','on');
else
    set([hcurV{:} hcurH{:}],'visible','off');
end
%plot(axmip,[1 size(s1,1)],[1 size(s1,2)],'w');



%set(img(1),'xdata',[.5 99]+.5); %1 99.5
%set(img(1),'xdata',[.5 99]+.5); %1 99.5

updatecursor(hcurV{1},hcurH{1},cx,cz,[0 sz(1)]+.5,[.5 sz(3)],cursorgap);

updatecursor(hcurV{2},hcurH{2},cy,cz,[0 sz(2)]+.5,[.5 sz(3)],cursorgap);

updatecursor(hcurV{3},hcurH{3},cx,cy,[0 sz(1)]+.5,[.5 sz(2)],cursorgap);

if(run_callback && ~isempty(cbfunc))
    for i = 1:numel(cbfunc)
        if(isempty(cbfunc{i}))
            continue;
        end
        cbfunc{i}(disp2orig([cx cy cz],dimpermute,origsize));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hist_mousedown(src,event)
p = get(src,'CurrentPoint');
p = p(1);
M = getappdata(gcbf,'guidata');
D = getappdata(gcbf,'data');
idx1 = find(D.V(:) <= p);
if(isempty(idx1))
    [~,idx1] = min(D.V(:));
end
[~, idx2] = max(D.V(idx1));
idx = idx1(idx2);
[x y z] = ind2sub(size(D.V),idx);
M.cx = x;
M.cy = y;
M.cz = z;
update_linked_figures(M);
setappdata(gcbf,'guidata',M);
updatefig(M);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function axmip_mousedown(src,event)
M = getappdata(gcbf,'guidata');
M.mouseax = -1;
setappdata(gcbf,'guidata',M);
fig_mousemove(src,event);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ax_mousedown(src,event, idx)
rightclick = strcmpi(get(gcbf,'SelectionType'),'alt');
M = getappdata(gcbf,'guidata');

if(rightclick)
    D = getappdata(gcbf,'data');
    sz = size(D.V);
    cx = min(sz(1),max(1,round(M.cx)));
    cy = min(sz(2),max(1,round(M.cy)));
    cz = min(sz(3),max(1,round(M.cz)));
    
    
    fprintf('[%d %d %d] %f \n',[cx cy cz],D.V(cx,cy,cz));
    return;
end
M.mouseax = idx;
M.curax = idx;

setappdata(gcbf,'guidata',M);
fig_mousemove(src,event);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ax_mouseup(src,event)
M = getappdata(gcbf,'guidata');
M.mouseax = [];
setappdata(gcbf,'guidata',M);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fig_mousemove(src,event)
M = getappdata(gcbf,'guidata');
if(~isempty(M.mouseax))
    idx = M.mouseax;
    rightclick = strcmpi(get(gcbf,'SelectionType'),'alt');
    
    if(idx == -1)
        p = get(M.axmip,'CurrentPoint');
        p = round(p(1,1:2)+[-.5 .5]);
        [idx px py] = mip2ax(p(1),p(2),M.mipsize);
        
        px = min(M.mipsize(idx,2),max(1,round(px)));
        py = min(M.mipsize(idx,1),max(1,round(py)));
        pz = M.mipidx{idx}(py,px);
        
        %if right click, move to slice where max voxel was found
        if(rightclick)
            p = [px py pz];
        else
            p = [px py];
        end
    else
        p = get(M.ax(idx),'CurrentPoint');
        p = round(p(1,1:2)+[-.5 1.5]);
    end
    
    if(idx == 1)
        M.cx = p(1);
        M.cz = p(2);
        if(numel(p) == 3)
            M.cy = p(3);
        end
    elseif(idx == 2)
        M.cy = p(1);
        M.cz = p(2);
        if(numel(p) == 3)
            M.cx = p(3);
        end        
    elseif(idx == 3)
        M.cx = p(1);
        M.cy = p(2);
        if(numel(p) == 3)
            M.cz = p(3);
        end        
    end
    
    update_linked_figures(M);
    setappdata(gcbf,'guidata',M);
    updatefig(M);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s1 s2 s3] = bgslice(Vbg, xyz, imgsz)
szratio = size(Vbg)./imgsz;
bxyz = round([xyz(:).'-1].*szratio + 1);
bxyz = min(size(Vbg),max(1,bxyz));

s1 = squeeze(Vbg(:,bxyz(2),:)).';
s2 = squeeze(Vbg(bxyz(1),:,:)).';
s3 = squeeze(Vbg(:,:,bxyz(3))).';

cmap = gray(256);
s1 = ind2rgb(ceil(size(cmap,1)*s1),cmap);
s2 = ind2rgb(ceil(size(cmap,1)*s2),cmap);
s3 = ind2rgb(ceil(size(cmap,1)*s3),cmap);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fig_keypress(src,event)
M = getappdata(gcbf,'guidata');
movecursor = [];
showcursor = M.showcursor;
showsurf = M.showsurf;
if(strcmpi(event.Key,'h'))
    if(strcmpi(get(M.img(1),'visible'),'on'))
        set(M.img,'visible','off');
    else
        set(M.img,'visible','on');
    end
elseif(strcmpi(event.Key,'v'))
    snaptosurface(M);
    return;
elseif(strcmpi(event.Key,'s'))
    showsurf=~M.showsurf;
elseif(strcmpi(event.Key,'x'))
    showcursor=~M.showcursor;
elseif(strcmpi(event.Key,'leftarrow'))
    movecursor = [-1 0];
elseif(strcmpi(event.Key,'rightarrow'))
    movecursor = [1 0];
elseif(strcmpi(event.Key,'uparrow'))
    movecursor = [0 1];
elseif(strcmpi(event.Key,'downarrow'))
    movecursor = [0 -1];
elseif(strcmpi(event.Character,'?'))
    printhelp;
    return;
else
    return;
end

if(~isempty(movecursor) && ~isempty(M.curax))
    idx = M.curax;
    if(idx == 1)
        M.cx = M.cx + movecursor(1);
        M.cz = M.cz + movecursor(2);
    elseif(idx == 2)
        M.cy = M.cy + movecursor(1);
        M.cz = M.cz + movecursor(2);
    elseif(idx == 3)
        M.cx = M.cx + movecursor(1);
        M.cy = M.cy + movecursor(2);
    end
    update_linked_figures(M);
    setappdata(gcbf,'guidata',M);
    updatefig(M);
elseif(showcursor ~= M.showcursor)
    M.showcursor=showcursor;
    setappdata(gcbf,'guidata',M);
    updatefig(M);
elseif(showsurf ~= M.showsurf)
    M.showsurf=showsurf;
    setappdata(gcbf,'guidata',M);
    updatefig(M);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function update_linked_figures(M)
if(~isempty(M.figlink))
    allfigs = findobj(0,'type','figure');
    figtags = get(allfigs,'tag');
    linkedfigs = allfigs(regexpmatch(figtags,sprintf('^orthogui\\.%d$',M.figlink)));
    linkedfigs = setdiff(linkedfigs,M.hfig);
    if(~isempty(linkedfigs))
        for i = 1:numel(linkedfigs)
            orthogui(linkedfigs(i),'location',disp2orig([M.cx M.cy M.cz],M.dimpermute,M.origsize));
        end
    end
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [hv hh] = plotcursor(ax,x,y,xl,yl,gap,varargin)
if(gap > 0)
    hv = plot(ax,[x x; x x]',[yl(1) y-gap; y+gap yl(2)]',varargin{:});
    hh = plot(ax,[xl(1) x-gap; x+gap xl(2)]',[y y; y y]',varargin{:});
else
    hv = plot(ax,[x x]',[yl(1) yl(2)]',varargin{:});
    hh = plot(ax,[xl(1) xl(2)]',[y y]',varargin{:});    
end
hv = reshape(hv,1,[]);
hh = reshape(hh,1,[]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updatecursor(hv,hh,x,y,xl,yl,gap,varargin)

if(numel(hv) > 1)
    %some hacks to keep crosshairs from displays off the edges
    if(y-gap<=yl(1))
        yl(1)=nan;
    end
    if(y+gap>=yl(2))
        yl(2)=nan;
    end
    if(x-gap<=xl(1))
        xl(1)=nan;
    end
    if(x+gap>=xl(2))
        xl(2)=nan;
    end
    
    if(isnan(yl(1)))
        set(hv(1),'XData',[x x]*nan,'YData',[yl(1) y-gap]*nan);
    else
        set(hv(1),'XData',[x x],'YData',[yl(1) y-gap]);
    end
    if(isnan(yl(2)))
        set(hv(2),'XData',[x x]*nan,'YData',[y+gap yl(2)]*nan);
    else
        set(hv(2),'XData',[x x],'YData',[y+gap yl(2)]);
    end
    if(isnan(xl(1)))
        set(hh(1),'XData',[xl(1) x-gap]*nan,'YData',[y y]*nan);
    else
        set(hh(1),'XData',[xl(1) x-gap],'YData',[y y]);
    end
    if(isnan(xl(2)))
        set(hh(2),'XData',[x+gap xl(2)]*nan,'YData',[y y]*nan);
    else
        set(hh(2),'XData',[x+gap xl(2)],'YData',[y y]);
    end
else
    set(hv,'XData',[x x],'YData',[yl(1) yl(2)]);
    set(hh,'XData',[xl(1) xl(2)],'YData',[y y]);  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mipx mipy xl yl] = ax2mip(axidx,px,py,mipsize)

padsz = max(mipsize,[],1);
padgap = (repmat(padsz,size(mipsize,1),1)-mipsize)/2;
ox = (axidx-1)*padsz(2)+padgap(axidx,2);
oy = padgap(axidx,1);

mipx = px + ox;
mipy = py + oy;
xl = [ox ox+mipsize(axidx,2)];
yl = [oy oy+mipsize(axidx,1)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [axidx px py] = mip2ax(mipx,mipy,mipsize)


padsz = max(mipsize,[],1);
padgap = (repmat(padsz,size(mipsize,1),1)-mipsize)/2;
axidx = floor(mipx/padsz(2)) + 1;
px = mipx - (axidx-1)*padsz(2) - padgap(axidx,2);
py = mipy -  padgap(axidx,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function xyz2 = orig2disp(xyz,dimpermute,origsize)
xyz2=xyz(abs(dimpermute));
for i = 1:numel(dimpermute)
    dp=abs(dimpermute(i));
    if(dimpermute(dp)<0)
        xyz2(i)=origsize(dp)-xyz(dp)+1;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function xyz2 = disp2orig(xyz,dimpermute,origsize)
xyz2=xyz;
xyz2(abs(dimpermute))=xyz;
for i =1:numel(dimpermute)
    dp=abs(dimpermute(i));
    if(dimpermute(dp)<0)
        xyz2(dp)=origsize(dp)-xyz(i)+1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function snaptosurface(M)
if(isempty(M.curax))
    return;
end

dumpstruct(M);

D=getappdata(hfig,'data');
if(isempty(D.surfslices))
    return;
end
idx = curax;

cslice=[cy cx cz];
dslice=[2 1 3];

s=cslice(idx);
d=dslice(idx);
vs=D.surfslices{d}{s};
if(isempty(vs))
    return;
end

if(idx==1)
    pxy=[cx cz];
elseif(idx==2)
    pxy=[cy cz];
elseif(idx==3)
    pxy=[cx cy];
end

%sd=(vs(:,1)-pxy(1)).^2 + (vs(:,2)-pxy(2)).^2;
[~,midx]=min((vs(:,1)-pxy(1)).^2 + (vs(:,2)-pxy(2)).^2);
sxy=round(vs(midx,:));

if(idx==1)
    cx=sxy(1);
    cz=sxy(2);
elseif(idx==2)
    cy=sxy(1);
    cz=sxy(2);
elseif(idx==3)
    cx=sxy(1);
    cy=sxy(2);
end

M.cx=cx;
M.cy=cy;
M.cz=cz;
update_linked_figures(M);
setappdata(hfig,'guidata',M);
updatefig(M,false);

if(~isempty(cbfunc))
    for i = 1:numel(cbfunc)
        if(isempty(cbfunc{i}))
            continue;
        end
        cbfunc{i}(disp2orig([cx cy cz],dimpermute,origsize));
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function printhelp
fprintf('h          - Hide/Show foreground volume\n');
fprintf('x          - Hide/Show crosshair\n');
fprintf('s          - Hide/Show surface slices\n');
fprintf('v          - Snap to nearest surface vertex\n');
fprintf('[arrows]   - Navigate current ortho panel\n');
