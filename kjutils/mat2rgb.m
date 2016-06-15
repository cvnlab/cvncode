function rgbimg = mat2rgb(imgvals,varargin)
% rgbimg = mat2rgb(imgvals,'param1',value1,...)
% 
% Convert MxN image matrix into MxNx3 RGB image
%
% Options: 'paramname','value',...
%   cmap:           Colormap for output image (default = jet)
%   clim:           Colormap limits
%   circulartype:   0,1 specifying circular colormap type (see knkutils)
%   overlayalpha:   MxN mask where 1=main image, 0=background underlay
%                     values between 0-1 = partial transparency
%                   1x1 scalar = uniform partial transparency
%   threshold:      1x1 scalar: alpha = imgvals>threshold
%   absthreshold:   1x1 scalar: alpha = abs(imgvals)>threshold (overrides
%                       'threshold')
%   overlayrange:   1x2 scalar: alpha = imgvals>range(1) & imgvals<range(2)
%                   (overrides thresholds)
%   inclusive:      true or false.  Include thresholds? (default=false)
%                   ie: >=threshold instead of >threshold
%   background:     MxN image matrix, 1x3 RGB, 1x1 RGB, 
%                     or ColorSpec (eg: 'k'). (default=0)
%   bg_cmap:        Colormap for background underlay (default = gray)
%   bg_clim:        Colormap limits for underlay (default = [0 1])
%   rgbnan:         replace any NaN in the final RGB  image with this value
%                   (default = 0)

% requires knkutils cmaplookup
% KJ Update 2016-02-04: 1. cast everything to single to avoid dumb type bug
%						2. Colormap fixes: accept strings eg 'jet' and 
%							set cmax=inf if cmax==cmin to avoid lookup problem
% Update 2016-02-11 KJ: Accept ColorSpec for background (eg: 'k' for black)
% Update 2016-03-07 KJ: Add absthreshold option
% Update 2016-05-09 KJ: 1. Bugfix for nan support.  
%                       2. Add overlayrange option
%                       3. make thresholds exclusive (unless 'inclusive' param)
%                       

options=struct(...
    'clim',[-inf inf],...
    'overlayalpha',[],...
    'overlayrange',[],...
    'threshold',[],...
    'absthreshold',[],...
    'background',0,...
    'bg_clim',[0 1],...
    'circulartype',0,...
    'cmap',jet(256),...
    'bg_cmap',gray(64),...
    'rgbnan',0,...
    'inclusive',false);

%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%parse options

input_opts=mergestruct(varargin{:});
fn=fieldnames(input_opts);
for f = 1:numel(fn)
    opt=input_opts.(fn{f});
    if(~(isnumeric(opt) && isempty(opt)))
        options.(fn{f})=input_opts.(fn{f});
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(isfield(options,'alpha'))
    options.overlayalpha=options.alpha;
    options=rmfield(options,'alpha');
end

%%%% Map values->rgb
%%%%
if(~isempty(options.cmap) && ischar(options.cmap))
    if(~any(options.cmap=='('))
        options.cmap=[options.cmap '(256)'];
    end
    options.cmap=evalin('caller',options.cmap);
end
if(~isempty(options.bg_cmap) && ischar(options.bg_cmap))
    if(~any(options.bg_cmap=='('))
        options.bg_cmap=[options.bg_cmap '(256)'];
    end
    options.bg_cmap=evalin('caller',options.bg_cmap);
end

cmin=options.clim(1);
cmax=options.clim(2);
if(isempty(cmin) || ~isfinite(cmin))
    cmin=nanmin(imgvals(:));
end
if(isempty(cmax) || ~isfinite(cmax))
    cmax=nanmax(imgvals(:));
end
if(cmax==cmin)
    cmax=inf;
end
cmax=single(cmax);
cmin=single(cmin);
imgvals=single(imgvals);
rgbimg = cmaplookup(imgvals,cmin,cmax,options.circulartype,options.cmap);

if(isempty(options.overlayalpha))
    options.overlayalpha=ones(size(imgvals));
elseif(numel(options.overlayalpha)==1)
    options.overlayalpha=options.overlayalpha*ones(size(imgvals));
end

tmpalpha=[];
if(options.inclusive)
    if(~isempty(options.absthreshold))
        tmpalpha=abs(imgvals)>=options.absthreshold;
    elseif(~isempty(options.threshold))
        tmpalpha=imgvals>=options.threshold;
    elseif(~isempty(options.overlayrange))
        tmpalpha=imgvals>=options.overlayrange(1) & imgvals<=options.overlayrange(2);
    end
else
    if(~isempty(options.absthreshold))
        tmpalpha=abs(imgvals)>options.absthreshold;
    elseif(~isempty(options.threshold))
        tmpalpha=imgvals>options.threshold;
    elseif(~isempty(options.overlayrange))
        tmpalpha=imgvals>options.overlayrange(1) & imgvals<options.overlayrange(2);
    end
end

if(~isempty(tmpalpha))
    options.overlayalpha=options.overlayalpha.*tmpalpha;
end

if(isempty(options.overlayalpha) || all(+options.overlayalpha(:) >= 1))
    rgbimg(repmat(isnan(imgvals),[1 1 3]))=options.rgbnan;
    return;
end

if(ischar(options.background))
    options.background=colorspec2rgb(options.background);
end

bg_cmin=options.bg_clim(1);
bg_cmax=options.bg_clim(2);
if(isempty(bg_cmin) || ~isfinite(bg_cmin))
    bg_cmin=nanmin(options.background(:));
end
if(isempty(bg_cmax) || ~isfinite(bg_cmax))
    bg_cmax=nanmax(options.background(:));
end
if(bg_cmax==bg_cmin)
    bg_cmax=inf;
end

%%%%% Map image background (underlay) to image matrix
%%%%%
bg_cmin=single(bg_cmin);
bg_cmax=single(bg_cmax);
imgbg=single(zeros(size(imgvals)));

if(numel(options.background) == 1)
    imgbg=ones(size(imgvals))*options.background;
    rgbback = cmaplookup(imgbg,bg_cmin,bg_cmax,0,options.bg_cmap);
    %rgbback=ones(size(rgbimg))*options.background;
    
elseif(numel(options.background) == 3)
    %background was a single RGB triplet
    rgbback=repmat(reshape(options.background(:),[1 1 3]),size(rgbimg,1),size(rgbimg,2));
else
    imgbg=options.background;
    %convert background values->RGB
    rgbback = cmaplookup(imgbg,bg_cmin,bg_cmax,0,options.bg_cmap);
end

%%%%%
%%%%% Map alpha/mask values to image matrix
%%%%%
if(isequal(size(options.overlayalpha),size(imgvals)))
    imgalpha=repmat(options.overlayalpha,[1 1 3]);
else
    %alpha is just a single value
    imgalpha=options.overlayalpha(1);
end

imgalpha=single(imgalpha);

%image nan --> image=0, alpha=0
%background nan --> background=0
%alpha nan --> final image = 0

%imgalpha(isnan(imgalpha))=0;
imgalpha=imgalpha .* ~repmat(any(isnan(rgbimg),3),[1 1 3]);
rgbimg(isnan(rgbimg))=0;
rgbback(isnan(rgbback))=0;
    
%blend image and background to form final image
rgbimg=rgbimg.*imgalpha+rgbback.*(1-imgalpha);

rgbimg(isnan(rgbimg)) = options.rgbnan;
rgbimg(repmat(isnan(imgvals),[1 1 3]))=options.rgbnan;
