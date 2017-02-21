function [mappedvals,Lookup,rgbimg,options] = cvnlookupimages(subject, vals, hemi, view_az_el_tilt, Lookup, varargin)
% [mappedvals,Lookup,rgbimg] = cvnlookupimages(subject, vals, hemi, view_az_el_tilt, Lookup, 'param1','value1',...)
%
% Inputs:
%   subject:    Name of freesurfer subject containing <hemi>.sphere, etc...
%   vals:       Vx1 values for each vertex on the surface
%           OR  struct('data',<L+R x 1>,'numlh',L,'numrh',R) to create
%               images for both hemispheres side by side.  
%               In this case, hemi, view_az_el_tilt, and Lookup must be 
%               cell arrays
%
%   hemi:       lh or rh 
%           OR  cell array for both hemis if vals=struct(...) 
%               eg: {'lh','rh'} or {'rh','lh'} 
%
%   view_az_el_tilt: Triplet containing viewpoint azimuth, elevation, and tilt 
%               Azimuth in degrees, range=[0,360], 0 = -y
%               Elevation in degrees, range=[-90,90], 90 = +z 
%               Camera tilt in degrees, range=[0,360]
%           OR  cell array for both hemis eg: {[10 -40 0],[-10 -40 0]}
%
%   Lookup:     Lookup structure returned from previous call to
%                   cvnlookupimages (or [] for first call).  Can speed up
%                   multiple lookups with the same viewpoint.
%               Reusable only if same subject,hemi,view,source, and target
%                   spaces
%           OR  cell array for both hemis: eg: {LookupL,LookupR} 
%               If vals=struct(...) and hemis={'lh','rh'}, output Lookup 
%               will already be a cell array {LookupL, LookupR}, which can 
%               be passed to subsequent cvnlookupimages calls
%
%   
% Outputs:
%   mappedvals: <res>x<res> mapped image matrix (NOT RGB!)
%   Lookup:     Structure containing lookup information.  Can speed up
%                   multiple lookups with the same viewpoint.
%            OR cell array if two hemis provided in input
%   rgbimg:     Optional output containing RGB image: <res>x<res>x3
%
% View options: 'paramname','value',...
%   xyextent:   [w h] ranging between [0,1].  Fraction of spherical view
%               to include in output.  Large values means pixels around
%               edge of image may be ill-defined.
%
%                   [  1  1 ] = entire circle (corners of image will be
%                       outside sphere)
%                   [ .7 .7 ] = largest box fully within circle
%                   [ .6 .6 ] = DEFAULT box with minimal loss of vertices
%               
%   imageres:   Output image size (default=1000)
%
%   inputsuffix: Input is a subset of sphere vertices.  This controls
%                which data preparation we are using.
%                   DENSE|DENSETRUNCpt|orig ("orig"=<hemi>.sphere)
%                If empty (default), use size(vals) to determine which
%                input surface is the right size.
%
%   surfsuffix: Use <hemi>.<surftype><surfsuffix> for lookup/display. 
%                   DENSE(default)|DENSETRUNCpt|orig|fsaverage|fsaverageDENSE|fsaverageDENSETRUNCpt 
%                   ("orig"=<hemi>.sphere)
%
%   reset:      false (default): Load lookup from disk if available. 
%               true: Regenerate lookup.
%   savelookup: true (default): Save lookup to disk for future use. 
%               false: Do not save lookup.
%   surfdir:    Alternate location to find <hemi>.sphere, etc... (Otherwise
%               look in <freesurferdir>/<subject>/surf
%
% Image saving options: 'paramname','value',...
%   filename:       Filename to save final image. default = [] ([] = just
%                   return non-RGB value matrix)
%   cmap:           Colormap for output image (default = jet)
%   clim:           Colormap limits
%   circulartype:   0,1 specifying circular colormap type
%   overlayalpha:   Vx1 mask where 1=mapped image, 0=background underlay
%                   values between 0-1 = partial transparency
%                OR 1x1 value between 0-1 for entire overlay
%   threshold:      overlayalpha = val>threshold (ignores 'overlayalpha')
%   absthreshold:   overlayalpha = abs(vals)>threshold
%   overlayrange:   overlayalpha = vals>range(1) & vals<range(2)
%   inclusive:      true or false.  Include thresholds? (default=false)
%                   ie: >=threshold instead of >threshold
%
%   background:     'curv' (default), Vx1, 1x3 RGB
%   bg_cmap:        Colormap for background underlay (default = gray)
%   bg_clim:        Colormap limits for underlay (default = [-1 2])
%   hemiborder:     Width of border between hemi images (default=2 pixels)
%   text:           string to display in top left corner of RGB image 
%               OR  cell array of strings if multiple hemis 
%                   eg: 'LAYER1' or {'LEFT','RIGHT'}
%   textsize:       font size in pixels (default=50) 
%                   If textsize<1, fontsize will be textsize*imageres
%   textcolor:      text color (default='w', ie white)
%
% Non-sphere surface options: 'paramname','value',....
%   surftype:       sphere (default), inflated, white, etc...
%   surfshading:    true|false to add lighting.  Only affects non-sphere
%                   surftypes. Default = true
%   padalign:       'top' (default), or 'bottom'.  If hemi images don't
%                   have the same height, do we align the top or bottom?
%
%   *NOTE: if surftype is not 'sphere', some defaults change:
%    imageres:      default=500
%    surfsuffix:    default='DENSETRUNCpt'; 
%
% ROI visualization options: 'paramname','value',...
%   roiname:        label name (or cell array) for ROI(s) to draw on final RGB image
%                   Looks for label file in <subjectsdir>/<subject>/label:
%                   <hemi>[surfsuffix].<roiname>.label
%   roimask:        Vx1 binary mask (or cell array for multiple ROIs) for an ROI to draw on 
%                   final RGB image.  If input data contains both
%                   hemispheres, roimask should be (numlh+numrh)x1, or a
%                   cell array of (numlh+numrh)x1 masks for multiple ROIs.
%   roicolor:       ColorSpec or RGB color for ROI outline(s) 
%                   'y','m','c','r','g','b','w','k' OR
%                   [r g b] from 0-1
%                   default = [0 0 0] (black)
%                   Can also be either Nx3 or a cell array of N [1x3] to 
%                   specify different colors for each ROI
%   roiwidth:       Line width of ROI outline(s). default=.5
%   drawroinames:   true|false(default) or cell array of ROI names to draw
%
% Mosaic/multiple map options: If input contains more than one map
%       (e.g., Vx6 with all 6 layers), output maps can be combined in a 
%       'mosaic' format using the following options.  If 'mosaic'=[],
%       return maps will be <res>x<res>xC, and rgbmaps will be
%       <res>x<res>xCx3
%   mosaic:             [rows,columns] (default=[])
%   mosaicborder:       With of border between mosaic images (default=2px)
%   mosaicbordercolor:  Color of mosaic border (default='w')
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Examples:
%
% M=load('C0041_lh_run01040710_layer1_results_PRF.mat')
% M=M.lh_results_l1;
% 
% % Eccentricity map around occipital pole
% [img,L,rgbimg]=cvnlookupimages('C0041',M.ecc,'lh',[10 -40 0]);
% 
% % Eccentricity map around occipital pole, thresholded for R2>.15
% [img,L,rgbimg]=cvnlookupimages('C0041',M.ecc,'lh',[10 -40 0],L,'overlayalpha',M.R2>.15);
% 
% % Polar angle map around occipital pole, explicit colormap limits [0 360]
% [img,L,rgbimg]=cvnlookupimages('C0041',M.ang,'lh',[10 -40 0],L,'clim',[0 360]);
% 
% % R2 map around occipital pole, explicit colormap limits [0 1], save RGB image to png
% cvnlookupimages('C0041',M.R2,'lh',[10 -40 0],L,'clim',[0 1],'filename','test_l1_r2.png',);
% 
% % show outputs side by side:
% figure;
% subplot(1,2,1);
% imagesc(img); colorbar; % display lookup results (imagesc + colorbar)
% subplot(1,2,2);
% imshow(rgbimg); % display resulting RGB image
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Examples with ROIs: 
%
% % read file lhDENSETRUNCpt.V1.label and draw outline
% [img,L,rgbimg]=cvnlookupimages('C0041',M.ang,'lh',[10 -40 0],L,'roiname','V1');
%
% % draw 2 roi borders.  first one is black, second is white
% [img,L,rgbimg]=cvnlookupimages('C0041',M.ang,'lh',[10 -40 0],L,'roimask',{roiV1,roiV2},...
%   'roicolor',{[0 0 0],[1 1 1]});
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Quick lookup of mapped values only (No RGB, etc...):
%
% [~,L,~]=cvnlookupimages('C0041',M.ecc,'lh',[10 -40 0]);
% img1=spherelookup_vert2image(M.ang,L);
% img2=spherelookup_vert2image(M.ecc,L);
% figure;
% imagesc([img1 img2])
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Display both hemispheres:
% V=load('/home/stone-ext1/fmridata/20151214-ST001-D003/preprocessSURF/mean.mat');
% %layer1
% valstruct=struct('data',squeeze(V.data(:,1,:)),'numlh',V.numlh,'numrh',V.numrh);
% L=[];
% [img1,L,rgbimg1]=cvnlookupimages('C0045',valstruct,{'lh','rh'},{[10 -40 0],[-10 -40 0]},[]);
% %layer2
% valstruct.data=squeeze(V.data(:,2,:));
% [img2,L,rgbimg2]=cvnlookupimages('C0045',valstruct,{'lh','rh'},[],L);
%
% % Quick lookup for both hemispheres (No RGB):
% valstruct.data=squeeze(V.data(:,3,:));
% img3=spherelookup_vert2image(valstruct,L);
%
% % Display stack of all 3 layers
% figure;
% imagesc([img1; img2; img3]);
%
% % Or Display all 6 layers in a 3x2 mosaic
% figure;
% valstruct.data=V.data(:,1:6);
% [img1,L,rgbimg1]=cvnlookupimages('C0045',valstruct,{'lh','rh'},{[10 -40 0],[-10 -40 0]},[],'mosaic',[3 2]);

% Update KJ 2016-01-17: 
%   1. Automatic input type detection (based on size(vals))
%   2. Add 'savelookup' option (default=true, but can say false
%       to skip caching the lookup) 
%   3. Add optional third 'rgbimg' output containing the XxYx3 RGB image.
%
% Update KJ 2016-01-27:
%   1. Add optional 'threshold' param to make overlayalpha from vals
%   2. Add ROI visualization options (draw outlines)
%
% Update KJ 2016-02-10:
%   1. Accept vals=struct(...) to display both hemispheres
%   2. Add text options for labeling output RGB
% 
% update KJ 2016-02-11:
%   1. Use inflated surface for reverselookup
%   2. Accept ColorSpec or [r,g,b] for roicolor (eg: 'w' for white)
%   3. Use knk 'detectedges' for roi borders
%
% update KJ 2016-04-25 (v1.1):
%   1. Non-sphere surfaces + shading (inflated, etc)
%   2. Add "version" to files to ensure consistency
%
% update KJ 2016-06-16 (v1.2):
%   1. Fix for non-sphere surfaces 
%
% update KJ 2016-11-07
%   1. Add fsaverage output options
%   2. Speed up ROI display when showing lots of parcels
%
% update KJ 2016-11-14
%   1. Add drawroinames flag
%   2. Fix mosaic mode for nonsphere surfaces
%   3. Allow hemi text to be a cell array with a string for each rgb map 
%%
lookup_version='1.2';

%default options
options=struct(...
    'reset',false,...
    'savelookup',true,...
    'filename',[],...
    'clim',[-inf inf],...
    'threshold',[],...
    'absthreshold',[],...
    'overlayrange',[],...
    'overlayalpha',[],...
    'background','curv',...
    'bg_clim',[-1 2],...
    'xyextent',[.6 .6],...
    'imageres',1000,...
    'surfsuffix','DENSE',...
    'inputsuffix',[],...
    'circulartype',0,...
    'cmap',jet(256),...
    'bg_cmap',gray(64),...
    'rgbnan',0,...
    'hemiborder',2,...
    'surfdir',[],...
    'roiname',[],...
    'roimask',[],...
    'roiwidth',{.5},...
    'roicolor',{[0 0 0]},...
    'drawroinames',false,...
    'text',[],...
    'textsize',50,...
    'textcolor','w',...
    'surftype','sphere',...
    'mosaic',[],...
    'mosaicborder',2,...
    'mosaicbordercolor','w',...
    'surfshading',true,...
    'padalign','top');


if(~exist('Lookup','var') || isempty(Lookup))
    Lookup = [];
elseif(~isempty(Lookup) && ischar(Lookup) && ~isempty(varargin))
    %If Lookup input is a character, assume user forgot to put Lookup=[],
    %so set Lookup=[] and treat input as the first param name instead
    varargin=[Lookup varargin];
    Lookup=[];
end

if(isstruct(Lookup))
    if(isfield(Lookup,'inputsuffix'))
        options.inputsuffix=Lookup.inputsuffix;
    end
    if(isfield(Lookup,'surfsuffix'))
        options.surfsuffix=Lookup.surfsuffix;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%parse options
input_opts=mergestruct(varargin{:});

%change defaults for non-sphere surfaces
if(isfield(input_opts,'surftype') && ~isequal(input_opts.surftype,'sphere'))
    options.surfsuffix='DENSETRUNCpt';
    options.imageres=500;
end

fn=fieldnames(input_opts);
for f = 1:numel(fn)
    opt=input_opts.(fn{f});
    if(~(isnumeric(opt) && isempty(opt)))
        options.(fn{f})=input_opts.(fn{f});
    end
end

%%% replace some alternate param names
if(isfield(options,'alpha'))
    options.overlayalpha=options.alpha;
    options=rmfield(options,'alpha');
end

if(isfield(options,'colormap'))
    options.cmap=options.colormap;
    options=rmfield(options,'colormap');
end

if(isfield(options,'bg_colormap'))
    options.bg_cmap=options.bg_colormap;
    options=rmfield(options,'bg_colormap');
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~isempty(options.surfdir) && exist(options.surfdir,'dir'))
    surfdir=options.surfdir;
    labeldir=surfdir;
else
    freesurfdir=cvnpath('freesurfer');
    subjdir=sprintf('%s/%s',freesurfdir,subject);
    surfdir=sprintf('%s/surf',subjdir);
    labeldir=sprintf('%s/label',subjdir);
end

%% Cast inputs to double to avoid issues with booleans and nans
if(~isempty(vals))
    if(isstruct(vals))
        if(~isnumeric(vals.data))
            vals.data=double(vals.data);
        end
    elseif(~isnumeric(vals))
        vals=double(vals);
    end
end

if(~isempty(options.background))
    if(isstruct(options.background))
        if(~isnumeric(options.background.data))
            options.background.data=double(options.background.data);
        end
    elseif(~ischar(options.background))
        options.background=double(options.background);
    end
end

%% If displaying on fsaverage surface
if(regexpmatch(options.surfsuffix,'^fsaverage'))
    %First do vertex lookup/transfer from subject to fsaverage
    %Then do cvnlookupimages with subject=fsaverage
    
    vals_fsavg=cvnlookupvertex(subject,hemi,options.inputsuffix,options.surfsuffix,vals);
    if(ischar(options.background))
        %load background and transform into same space as input (since
        %later calls will have 'fsaverage' as subject and won't be able to
        %load curv, sulc, etc...)
        options.background = load_surface_background(subject,hemi,options.background,options.inputsuffix,options.surfsuffix,surfdir);
    elseif(~isempty(options.background))
        options.background = cvnlookupvertex(subject,hemi,options.inputsuffix,options.surfsuffix,options.background);
    end
    
    %cast background vals to double to avoid issues with booleans and nans
    if(isstruct(options.background))
        options.background=double(options.background.data);
    else
        options.background=double(options.background);
    end
    inputsuffix_fsavg=strrep(options.surfsuffix,'fsaverage','');
    if(isempty(inputsuffix_fsavg))
        inputsuffix_fsavg='orig';
    end
    if(isequal(options.surftype,'sphere'))
        surfsuffix_fsavg=regexprep(inputsuffix_fsavg,'^DENSE.+','DENSE');
    else
        surfsuffix_fsavg=inputsuffix_fsavg;
    end
    
    options.inputsuffix=inputsuffix_fsavg;
    options.surfsuffix=surfsuffix_fsavg;
    
    optargs=struct2args(options);
    [mappedvals,Lookup,rgbimg,options] = cvnlookupimages('fsaverage', vals_fsavg, hemi, view_az_el_tilt, Lookup, optargs{:});
    return;
end

%% handle multiple hemispheres if vals=struct
if(isstruct(vals) && isfield(vals,'numlh'))
    view_az_el_tilt=cellify(view_az_el_tilt);
    hemi=cellify(hemi);
    hemitext=cellify(options.text);
    Lookup=cellify(Lookup);

    options.roimask=cellify(options.roimask);
    
    imghemi={};
    rgbimghemi={};
    lookuphemi={};
    for i=1:numel(hemi)
        h=hemi{i};
        hemi_options=options;
        if(isempty(view_az_el_tilt))
            v=[];
        else
            %dont loop through...just stop at last one in list
            %v=view_az_el_tilt{mod(i-1,numel(view_az_el_tilt))+1};
            v=view_az_el_tilt{min(i,numel(view_az_el_tilt))};
        end
        if(isempty(Lookup))
            L=[];
        else
            %L=Lookup{mod(i-1,numel(Lookup))+1};
            L=Lookup{min(i,numel(Lookup))};
        end
        switch(h)
            case 'lh'
                idx=1:vals.numlh;
            case 'rh'
                idx=(1:vals.numrh)+vals.numlh;
        end
        hemivals=vals.data(idx,:,:);
        if(~isempty(options.overlayalpha) && numel(options.overlayalpha)==size(vals.data,1))
            hemi_options.overlayalpha=options.overlayalpha(idx);
        end
        if(~isempty(options.background) && numel(options.background)==size(vals.data,1))
            hemi_options.background=options.background(idx);
        end
        
        hemi_options.roimask={};
        for r = 1:numel(options.roimask)
            if(numel(options.roimask{r})==size(vals.data,1))
                hemi_options.roimask{r}=options.roimask{r}(idx);
            end
        end
        hemi_options.text=[];
        hemi_options.filename=[];
        optargs=struct2args(hemi_options);
        [imghemi{i},lookuphemi{i},rgbimghemi{i},return_options]=cvnlookupimages(subject, hemivals, h, v, L, optargs{:});
        
        % copy clim from first hemi so both hemis have same colormap
        options.clim=return_options.clim;
        options.bg_clim=return_options.bg_clim;
    end
    
     %[mappedvals,Lookup,rgbimg,options]
     
    %We may need to pad to make hemispheres match (if using inflated, e.g.)
    hheight=cellfun(@(x)(size(x,1)),imghemi);
    maxheight=max(hheight);
    if(any(hheight~=maxheight))
        for i=1:numel(imghemi)
            if(hheight(i)~=maxheight)
                dheight=maxheight-hheight(i);

                %pad all relevant 2D images/lookups
                if(strcmpi(options.padalign,'bottom'))
                    pimg=@(img,v)(cat(1,cast(v*ones(dheight,size(img,2),size(img,3),size(img,4)),'like',img), img));
                else
                    pimg=@(img,v)(cat(1,img,cast(v*ones(dheight,size(img,2),size(img,3),size(img,4)),'like',img)));
                end
                
                imghemi{i}=pimg(imghemi{i},nan);
                rgbimghemi{i}=pimg(rgbimghemi{i},options.rgbnan);
                lookuphemi{i}.imglookup=pimg(lookuphemi{i}.imglookup,1);
                lookuphemi{i}.extrapmask=pimg(lookuphemi{i}.extrapmask,true);
                lookuphemi{i}.shading=pimg(lookuphemi{i}.shading,0);
                %lookuphemi{i}.imgsize=size(lookuphemi{i}.imglookup);
                %lookuphemi{i}.imgN=size(lookuphemi{i}.imglookup,2); %questionable
                
                %need to adjust reverselookup to account for any extra rows
                %we added to image
                rev=double(lookuphemi{i}.reverselookup);
                revcol=floor(max(rev-1,0)/hheight(i))+1;
                revrow=mod(max(rev-1,0),hheight(i))+1;
                if(strcmpi(options.padalign,'bottom'))
                    rev=(revcol-1)*maxheight+revrow+dheight;
                else
                    rev=(revcol-1)*maxheight+revrow;
                end
                rev(lookuphemi{i}.reverselookup==0)=0;
                lookuphemi{i}.reverselookup=cast(rev,'like',lookuphemi{i}.reverselookup);
            end
        end
    end
    for i=1:numel(imghemi)
        lookuphemi{i}.imgsize=size(lookuphemi{i}.imglookup);
        lookuphemi{i}.imgN=size(lookuphemi{i}.imglookup,2); %questionable
    end
    
    mappedvals=cat(2,imghemi{:});
    if(~isempty(options.text))
        for i = 1:numel(hemi)
            if(numel(hemitext)==numel(hemi))
                hemi_options.text=hemitext{min(i,numel(hemitext))};
            elseif(numel(hemitext)==1 && i==1)
                hemi_options.text=hemitext;
            else
                hemi_options.text=[];
            end
            rgbimghemi{i}=add_hemi_text(rgbimghemi{i},hemi_options.text,options.textsize,options.textcolor);
        end
    end
    for i = 2:numel(rgbimghemi)
        rgbimghemi{i}(:,1:options.hemiborder,:)=options.rgbnan;
    end
   
    rgbimg=cat(2,rgbimghemi{:});
    if(numel(lookuphemi)==1)
        Lookup=lookuphemi{1};
    else
        Lookup=lookuphemi;
    end
    
    if(size(mappedvals,3)>1 && ~isempty(options.mosaic))
        imgsz=size(rgbimg);
        mappedvals=makeimagestack(mappedvals,0,0,options.mosaic,0);
        %rgbimg=makeimagestack(rgbimg,0,0,options.mosaic,0);
        
        %seems to work better if we do r+g+b channels separately
        tmprgb=rgbimg;
        rgbimg={};
        for i = 1:3
            rgbimg{i}=makeimagestack(tmprgb(:,:,:,i),0,0,options.mosaic,0);
        end
        rgbimg=cat(3,rgbimg{:});
        clear tmprgb;
        
        if(options.mosaicborder > 0)
            mbc=options.mosaicbordercolor;
            if(ischar(mbc))
                mbc=colorspec2rgb(mbc);
            elseif(numel(mbc)==1)
                mbc=mbc*[1 1 1];
            end
            if(any(mbc>1))
                mbc=mbc/255;
            end
            
            if(~isfloat(rgbimg))
                mbc=uint8(mbc*255);
            end
            for i = 2:options.mosaic(1)
                rgbimg((i-1)*imgsz(1)+(1:options.mosaicborder),:,1)=mbc(1);
                rgbimg((i-1)*imgsz(1)+(1:options.mosaicborder),:,2)=mbc(2);
                rgbimg((i-1)*imgsz(1)+(1:options.mosaicborder),:,3)=mbc(3);
            end
            for i = 2:options.mosaic(2)
                rgbimg(:,(i-1)*imgsz(2)+(1:options.mosaicborder),1)=mbc(1);
                rgbimg(:,(i-1)*imgsz(2)+(1:options.mosaicborder),2)=mbc(2);
                rgbimg(:,(i-1)*imgsz(2)+(1:options.mosaicborder),3)=mbc(3);
            end
        end

    end
    
    %don't save image if maps are still 3D
    if(~isempty(options.filename) && size(mappedvals,3)==1)
        mkdirquiet(stripfile(options.filename));  % make dir if necessary
        imwrite(rgbimg,options.filename);
    end
    return;
end
%%

if(numel(vals)>1 && size(vals,1)==1)
    vals=vals.';
end

if(isequal(options.surftype,'sphere'))
    %for sphere lookups, always lookup full DENSE to avoid annoying TRUNC
    %extrapolation artifacts around edges
    options.surfsuffix=regexprep(options.surfsuffix,'^DENSE.+','DENSE');
end

if(isequal(options.surfsuffix,'orig'))
    options.surfsuffix_file='';
else
    options.surfsuffix_file=options.surfsuffix;
end

options.roiname=cellify(options.roiname);
options.roimask=cellify(options.roimask);
options.roicolor=cellify(options.roicolor);
options.roiwidth=cellify(options.roiwidth);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


imgN=options.imageres;

if(isempty(hemi) && ~isempty(Lookup) && isfield(Lookup,'hemi'))
    hemi=Lookup.hemi;
end
hemi=lower(hemi);

if(isempty(view_az_el_tilt) && ~isempty(Lookup))
    view_az_el_tilt=[Lookup.azimuth Lookup.elevation Lookup.tilt];
end

%az=mod(round(azel(1)),360);
%el=mod(round(azel(2))+90,180)-90;
az=round(view_az_el_tilt(1));
el=round(view_az_el_tilt(2));
tilt=mod(round(view_az_el_tilt(3)),360);
xyextent=options.xyextent;



%% load or generate lookup file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



if(~isempty(Lookup) && ~options.reset)
    %just use the input
else
    lookupdir=fullfile(surfdir, 'imglookup');
    if(~exist(lookupdir,'dir'))
        mkdirquiet(lookupdir);
        system(['chmod -R g+rwx ' lookupdir]);
    end
    cachename=sprintf('%s/%s.mat',lookupdir,makefilename(hemi,az,el,tilt,xyextent(1),xyextent(2),imgN,options.surfsuffix,options.surftype));
    
    cacheversion='0';
    if(exist(cachename,'file') && ~options.reset)
        %load from file
        Lookup=load(cachename);
        if(~isfield(Lookup,'version'))
            Lookup.version='0';
        end
        cacheversion=Lookup.version;
    end
    
    if(~exist(cachename,'file') || options.reset || ~isequal(cacheversion,lookup_version))

        %generate a new one and save it
        if(isequal(options.surftype,'sphere'))
            sphfile=sprintf('%s/%s.sphere%s',surfdir,hemi,options.surfsuffix_file);

            [vertsph,~,~] = freesurfer_read_surf_kj(sphfile);


            %recenter and scale to unit sphere
            [c,r]=spherefit(vertsph);
            vertsph=bsxfun(@minus,vertsph,c.')/r;
        else
            sphfile=sprintf('%s/%s.%s%s',surfdir,hemi,options.surftype,options.surfsuffix_file);

            [vertsph,facesph,~] = freesurfer_read_surf_kj(sphfile);
            %vertsph=bsxfun(@minus,vertsph,c.')/r;
        end
        

        %use inflated surface for reverse lookup (less topological
        %   distortion for nearest neighbour lookup of holes pixel holes
        inffile=sprintf('%s/%s.inflated%s',surfdir,hemi,options.surfsuffix_file);
        [vertinf,~,~] = freesurfer_read_surf_kj(inffile);
        
        if(options.reset)
            fprintf('''reset'' flag is set\n');
        elseif(~isequal(cacheversion,lookup_version))
            fprintf('Lookup file is outdated.\n');
        else
            fprintf('No cached spherelookup found: %s\n',cachename);
        end
        fprintf('Building new lookup structure...\n');
        if(isequal(options.surftype,'sphere'))
            Lookup=spherelookup_generate(vertsph,az,el,tilt,options.xyextent,imgN,...
                'reversevert',vertinf,'verbose',true);
        else
            tic
            Lookup=spherelookup_generate_notsphere(vertsph,facesph,az,el,tilt,imgN);
            toc
        end
        
        Lookup.surftype=options.surftype;
        Lookup.imglookup=uint32(Lookup.imglookup);
        Lookup.reverselookup=uint32(Lookup.reverselookup);
        Lookup.surfsuffix=options.surfsuffix;
        Lookup.surffile=sphfile;
        Lookup.hemi=hemi;
        Lookup.version=lookup_version;
        if(options.savelookup)
            fprintf('Saving lookup structure: %s\n',cachename);
            save(cachename,'-struct','Lookup');
            system(['chmod g+rw ' cachename]);
        end
    end
end

%% Shuffle lookup indices around when input and output are not the same surface
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(isfield(Lookup,'inputsuffix') && isequal(Lookup.inputsuffix,options.inputsuffix))
    %already generated surface-surface mapping
elseif(isequal(options.surfsuffix,options.inputsuffix))
    Lookup.input2surf=[];
else
    [~,input2surf,validmask,inputsuffix]=cvnlookupvertex(surfdir,hemi,options.inputsuffix,options.surfsuffix,vals);
    Lookup.input2surf=uint32(input2surf);
    Lookup.inputsuffix=inputsuffix;
    Lookup.extrapmask=Lookup.extrapmask | ~validmask(Lookup.imglookup);
    Lookup.is_extrapolated=squeeze(any(any(Lookup.extrapmask,1),2));
    Lookup.inputN=size(vals,1);
    options.inputsuffix=inputsuffix;
end

if(isequal(options.inputsuffix,'orig'))
    options.inputsuffix_file='';
else
    options.inputsuffix_file=options.inputsuffix;
end

%% Map input values to image matrix!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mappedvals=spherelookup_vert2image(vals,Lookup,nan);

if(isempty(options.filename) && nargout < 3)
    return;
end


%% convert matrix to RGB
rgboptions=options;


%Map background underlay and alpha map from vert2image if necessary
if(~isempty(options.overlayalpha) || ~isempty(options.threshold) || ...
    ~isempty(options.absthreshold) || ~isempty(options.overlayrange))
    if(isnumeric(options.background) && size(options.background,1)==size(vals,1))
        %background is same size as "vals" so use spherelookup_vert2image
        mappedcurv=spherelookup_vert2image(options.background,Lookup,nan);

    elseif(isnumeric(options.background) && size(options.background,1)==Lookup.vertsN)
        %background is same size as original surface (ie: lookup), so
        %just a straight lookup
        mappedcurv=options.background(Lookup.imglookup);

    elseif(ischar(options.background))
        %background was a string directing us to a freesurfer overlay
        curv = load_surface_background(subject,hemi,options.background,options.inputsuffix,options.surfsuffix,surfdir);
        if(isstruct(curv))
            curv=curv.data;
        end
        if(~isempty(curv))
            mappedcurv=curv(Lookup.imglookup);
        else
            %mappedcurv=rgboptions.background;
            mappedcurv=zeros(size(Lookup.imglookup));
        end
       
    else
        mappedcurv=rgboptions.background;
    end
    rgboptions.background=double(mappedcurv);
end

if(~isempty(options.overlayalpha))
    options.overlayalpha(isnan(options.overlayalpha))=0;
    if(size(options.overlayalpha,1)==size(vals,1))
        %alpha mask is same size as "vals" so use spherelookup_vert2image
        mappedalpha=spherelookup_vert2image(options.overlayalpha,Lookup,nan);
    elseif(size(options.overlayalpha,1)==Lookup.vertsN)
        %alpha mask is same size as original surface (ie: lookup), so
        %just a straight lookup
        mappedalpha=options.overlayalpha(Lookup.lookup);
    else
        mappedalpha=options.overlayalpha(1);
    end
    rgboptions.overlayalpha=mappedalpha;
end


rgbimg=mat2rgb(mappedvals,struct2args(rgboptions));

%% If roimask is given, draw the ROI

roirgb={};
roilist_idx=[];
if(~isempty(options.roiname))
    roimask={};
    roiname={};
    roilist_idx=[];
    for i = 1:numel(options.roiname)
        [roimasktmp, roinametmp, roirgbtmp]=cvnroimask(subject,hemi,options.roiname{i},[],options.inputsuffix,'collapsevals');
        if(isempty(roinametmp))
        elseif(numel(roinametmp)==1)
            roinametmp=regexprep(roinametmp,'@.+$','');
        else
            roisuff=common_suffix(roinametmp);
            if(~isempty(roisuff) && roisuff(1)=='@')
                roinametmp=strrep(roinametmp,roisuff,'');
            end
        end
        roimask=[roimask roimasktmp];
        roiname = [roiname {roinametmp}];
        roirgb=[roirgb roirgbtmp];
        %roilist_idx=[roilist_idx i*ones(1,numel(roimasktmp))];
        roilist_idx=[roilist_idx i];
        
    end
    options.roimask=roimask;
    options.roiname=roiname;
    if(isequal(options.roicolor,{'ctab'}))
        roilist_idx=[];
    else
        roirgb={};
    end
end

do_drawroinames=false;
if(isequal(options.drawroinames,true))
    do_drawroinames=true;
elseif(ischar(options.drawroinames))
    options.roiname={options.drawroinames};
    do_drawroinames=true;
elseif(iscell(options.drawroinames))
    options.roiname=options.drawroinames;
    do_drawroinames=true;
end

if(~isempty(options.roimask))
    if(~isempty(roirgb))
        roicolor_cell=roirgb;
    else
        roicolor_cell=options.roicolor;
        if(numel(roicolor_cell) == 1 && size(roicolor_cell{1},1)>1 && size(roicolor_cell{1},2)==3)
            roicolor_cell=num2cell(roicolor_cell{1},2);
        end
    end
    for i = 1:numel(options.roimask)
        if(isempty(options.roimask{i}))
            continue;
        end
        roimask=options.roimask{i};
        %roiwidth=options.roiwidth{mod(i-1,numel(options.roiwidth))+1};
        %roicolor=roicolor_cell{mod(i-1,numel(roicolor_cell))+1};
        
        
        if(~isempty(roilist_idx))
            iroi=roilist_idx(i);
        else
            iroi=i;
        end

        roiwidth=options.roiwidth{min(iroi,numel(options.roiwidth))};
        roicolor=roicolor_cell{min(iroi,numel(roicolor_cell))};
        if(isempty(options.roiname))
            roiname={};
        elseif(iscell(options.roiname) && numel(options.roiname)==numel(options.roimask))
            roiname=options.roiname{min(iroi,numel(options.roiname))};
        else
            roiname=options.roiname;
        end
        
        roicolor=colorspec2rgb(roicolor);
        if(any(roicolor>1))
            roicolor=roicolor/255;
        end
        roicolor=min(max(roicolor(:),0),1);
        
        if(size(roimask,1)==size(vals,1))
            %alpha mask is same size as "vals" so use spherelookup_vert2image
            %mappedroi=spherelookup_vert2image(roimask~=0,Lookup,nan);
            mappedroi=spherelookup_vert2image(roimask,Lookup,nan);
        elseif(size(roimask,1)==Lookup.vertsN)
            %alpha mask is same size as original surface (ie: lookup), so
            %just a straight lookup
            mappedroi=roimask(Lookup.imglookup);
        else
            error('invalid size for roimask');
        end
        
        %edgekernel=ones(round(roiwidth*2+1));
        %edgekernel=edgekernel/sum(edgekernel(:));
        %mappedroi2=conv2(+mappedroi,edgekernel,'same');
        %mappedroi=(mappedroi-mappedroi2)>.01;
        
        %%%%%%
        % old style: return multi-roi parcellation as a cell array of binary masks
        %   that we have to loop through... very slow for large parcellations
        %mappedroi=detectedges(mappedroi,roiwidth);
        %mappedroi(isnan(mappedroi))=0;
        
        %%%%%%
        % new style: return multi-roi parcellation as a vector of parcel
        %   labels (one val per pixel), then loop through each value to find
        %   each parcel's edge.  This is much faster
        rval=unique(mappedroi(:));
        rval=rval(rval~=0 & isfinite(rval));
        mroinan=~isfinite(mappedroi);

        mappedroi_orig=mappedroi;
            
        if(roiwidth>0)
            mappedroi2=zeros(size(mappedroi));
            for rv = 1:numel(rval)
                mroi=single(mappedroi==rval(rv));
                mroi(mroinan)=nan;
                mappedroi2=max(mappedroi2,detectedges(mroi,roiwidth));
                mappedroi2(isnan(mappedroi2))=0;
            end

            mappedroi=mappedroi2;

            %if an roi is not visible, make sure we don't divide by 0
            roimax=max(mappedroi(:));
            if(roimax==0)
                roimax=1;
            end
            mappedroi=mappedroi./roimax;

            if(size(rgbimg,4)>1)
                mappedroi=repmat(mappedroi,[1 1 1 3]);
                roiimg=repmat(reshape(roicolor,[1 1 1 3]),size(rgbimg,1),size(rgbimg,2),size(rgbimg,3));
            else
                mappedroi=repmat(mappedroi,1,1,3);
                roiimg=repmat(reshape(roicolor,[1 1 3]),size(rgbimg,1),size(rgbimg,2));

            end
            rgbimg=bsxfun(@plus,bsxfun(@times,rgbimg,(1-mappedroi)),bsxfun(@times,roiimg,mappedroi));
        end
        if(do_drawroinames && ~isempty(rval))
            if(iscell(roiname) && numel(roiname) >= numel(rval))
                tmplookup=Lookup;
                tmplookup.imgsize=size(tmplookup.imglookup);
                rgbimg=drawroinames(mappedroi_orig,rgbimg,tmplookup,rval,cleantext(roiname(rval)));
            elseif(ischar(roiname) && numel(rval)==1)
                tmplookup=Lookup;
                tmplookup.imgsize=size(tmplookup.imglookup);
                rgbimg=drawroinames(mappedroi_orig,rgbimg,tmplookup,rval,cleantext(roiname));
            end
        end

    end
end

%% 
if(isfield(Lookup,'shading') && options.surfshading==true)
    if(size(rgbimg,4)>1)
        rgbimg=bsxfun(@times,rgbimg,repmat(Lookup.shading,[1 1 1 3]));
    else
        rgbimg=bsxfun(@times,rgbimg,Lookup.shading);
    end
end

%% If 'text' argument provided, add text to output image(s)
if(~isempty(options.text))
    rgbimg=add_hemi_text(rgbimg,options.text,options.textsize,options.textcolor);
end

%% If given filename, save RGB image to file 
if(~isempty(options.filename))
    mkdirquiet(stripfile(options.filename));  % make dir if necessary
    imwrite(rgbimg,options.filename);  % save
end

%% Compute colormap limits for 'options' output
% so we know what clims were actually used if input contained inf or -inf 
options.clim=compute_clim(mappedvals,options.clim);
if(~isempty(rgboptions.background) && isnumeric(rgboptions.background))
    options.bg_clim=compute_clim(rgboptions.background,options.bg_clim);
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% HELPER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% compute clim 
function clim = compute_clim(v,clim)
cmin=clim(1);
cmax=clim(2);
if(isempty(cmin) || ~isfinite(cmin))
    cmin=nanmin(v(:));
end
if(isempty(cmax) || ~isfinite(cmax))
    cmax=nanmax(v(:));
end
if(cmax==cmin)
    cmax=inf;
end
clim=[cmin cmax];

%% cellify inputs
function c = cellify(c)
if(isempty(c))
    c={};
elseif(~iscell(c))
    c={c};
end

%%
function rgbimg=add_hemi_text(rgbimg,text,textsize,textcolor)
%% If 'text' argument provided, add text to output image(s)
if(isempty(text))
    return;
end

imgN=size(rgbimg,1);
if(textsize<1 && textsize>0)
    textsize=textsize*imgN;
end

txtargs={0,0,text,'VerticalAlignment','top','fontsize',textsize,'color',textcolor};
if(size(rgbimg,4)>1)
    for i=1:size(rgbimg,3)
        %if text for this hemi is a cell array with a string for each rgb map, 
        % add different text to each map
        if(iscell(text))
            if(i<=numel(text))
                txtargs{3}=text{i};
            else
                continue;
            end
        end
        if(isempty(txtargs{3}))
            continue;
        end
        rgbimg(:,:,i,:)=addtext2img(permute(rgbimg(:,:,i,:),[1 2 4 3]),txtargs,1);
    end
else
    rgbimg=addtext2img(rgbimg,txtargs,1);
end


%% create a filename for lookup containing all relevant parameters
function fname = makefilename(hemi,az,el,tilt,vx,vy,imgN,surfsuffix,surftype)

if(~exist('surftype','var') || isempty(surftype))
    surftype='sphere';
end

az=mod(round(az),360);
el=round(el);
if(el~=90)
    el=mod(el+90,180)-90;
end
tilt=mod(round(tilt),360);

azstr=strrep(sprintf('%d',az),'-','n');
elstr=strrep(sprintf('%d',el),'-','n');
tiltstr=strrep(sprintf('%d',tilt),'-','n');
vxstr=strrep(sprintf('%.2f',abs(vx)),'.','p');
vystr=strrep(sprintf('%.2f',abs(vy)),'.','p');
if(numel(imgN) == 1)
    resstr=sprintf('%d',imgN);
elseif(numel(imgN)==2)
    resstr=sprintf('%dx%d',imgN(1),imgN(2));
end
fname=sprintf('%slookup_%s_az%s_el%s_tilt%s_vx%s_vy%s_res%s_%s',surftype,hemi,azstr,elstr,tiltstr,vxstr,vystr,resstr,surfsuffix);

%% load a freesurfer overlay file and transform it to the desired output space (eg: curv orig->DENSETRUNCpt or curv DENSETRUNCpt->fsaverage)
function background = load_surface_background(subject,hemi,backgroundtype,inputsuffix,outputsuffix,surfdir)

background=cvnreadsurfacemetric(subject,hemi,backgroundtype,'',inputsuffix,'surfdir',surfdir);
if(isempty(background))
    return;
end

if(~isempty(outputsuffix) && ~ isequal(inputsuffix,outputsuffix))
    background=cvnlookupvertex(subject,hemi,inputsuffix,outputsuffix,background);
end

if(isstruct(background))
    bgdata=background.data;
else
    bgdata=background;
end

if(isequal(backgroundtype,'curv'))
    bgdata=bgdata<0;
elseif(isequal(backgroundtype,'sulc'))
    if(nanmean(abs(bgdata(:)))>1)
        %newer freesurfer versions scale sulc from [-10,10], so
        %for display purposes just divide so we can still use
        %[-1,1] range
        bgdata=bgdata/10;
    end
    bgdata=-bgdata;
end

if(isstruct(background))
    background.data=double(bgdata);
else
    background=double(bgdata);
end
    