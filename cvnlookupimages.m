function [mappedvals,Lookup,rgbimg,options] = cvnlookupimages(subject, vals, hemi, view_az_el_tilt, Lookup, varargin)
% [mappedvals,Lookup,rgbimg] = cvnlookupimages(subject, vals, hemi, view_az_el_tilt, Lookup, 'param1','value1',...)
%
% Inputs:
%   subject:    Name of freesurfer subject containing <hemi>.sphere, etc...
%   vals:       Vx1 values for each vertex on the surface
%   hemi:       lh or rh
%   view_az_el_tilt: Triplet containing viewpoint azimuth, elevation, and tilt 
%               Azimuth in degrees, range=[0,360], 0 = -y
%               Elevation in degrees, range=[-90,90], 90 = +z 
%               Camera tilt in degrees, range=[0,360]
%   Lookup:     Lookup structure returned from previous call to
%                   cvnlookupimages (or [] for first call).  Can speed up
%                   multiple lookups with the same viewpoint.
%               Reusable only if same subject,hemi,view,source, and target
%                   spaces
%   
% Outputs:
%   mappedvals: <res>x<res> mapped image matrix (NOT RGB!)
%   Lookup:     Structure containing lookup information.  Can speed up
%                   multiple lookups with the same viewpoint.
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
%                   [ .6 .6 ] = default box with minimal loss of vertices
%               
%   imageres:   Output image size (default=1000)
%
%   inputsuffix: Input is a subset of sphere vertices.  This controls
%                which data preparation we are using.
%                   DENSE|DENSETRUNCpt|orig ("orig"=<hemi>.sphere)
%                If empty (default), use size(vals) to determine which
%                input surface is the right size.
%
%   surfsuffix: Use <hemi>.sphere<surfsuffix>.  
%                   DENSE(default)|DENSETRUNCpt|orig ("orig"=<hemi>.sphere)
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
%   threshold:      sets overlayalpha = vals>=threshold (ignores 'overlayalpha')
%   background:     'curv' (default), Vx1, 1x3 RGB
%   bg_cmap:        Colormap for background underlay (default = gray)
%   bg_clim:        Colormap limits for underlay (default = [-1 2])
%
% ROI visualization options: 'paramname','value',...
%   roiname:        label name (or cell array) for ROI(s) to draw on final RGB image
%                   Looks for label file in <subjectsdir>/<subject>/label:
%                   <hemi>[surfsuffix].<roiname>.label
%   roimask:        Vx1 binary mask (or cell array) for an ROI to draw on 
%                   final RGB image
%   roicolor:       RGB color for ROI outline(s) [r g b] from 0-1
%                   default = [0 0 0] (black)
%   roiwidth:       Line with of ROI outline(s). default=2
%   
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



% Update KJ 2016-01-17: 
%   1. Automatic input type detection (based on size(vals))
%   2. Add 'savelookup' option (default=true, but can say false
%       to skip caching the lookup) 
%   3. Add optional third 'rgbimg' output containing the XxYx3 RGB image.

% Update KJ 2016-01-27:
%   1. Add optional 'threshold' param to make overlayalpha from vals
%   2. Add ROI visualization options (draw outlines)

%default options
options=struct(...
    'reset',false,...
    'savelookup',true,...
    'filename',[],...
    'clim',[-inf inf],...
    'threshold',[],...
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
    'roiwidth',{2},...
    'roicolor',{[0 0 0]});


if(~exist('Lookup','var') || isempty(Lookup))
    Lookup = [];
elseif(~isempty(Lookup) && ischar(Lookup) && ~isempty(varargin))
    %If Lookup input is a character, assume user forgot to put Lookup=[],
    %so set Lookup=[] and treat input as the first param name instead
    varargin=[Lookup varargin];
    Lookup=[];
end

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

if(isfield(options,'alpha'))
    options.overlayalpha=options.alpha;
    options=rmfield(options,'alpha');
end
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

if(isstruct(vals) && isfield(vals,'numlh'))
    view_az_el_tilt=cellify(view_az_el_tilt);
    hemi=cellify(hemi);
    Lookup=cellify(Lookup);

    imghemi={};
    rgbimghemi={};
    lookuphemi={};
    for i=1:numel(hemi)
        h=hemi{i};
        hemi_options=options;
        if(isempty(view_az_el_tilt))
            v=[];
        else
            v=view_az_el_tilt{mod(i-1,numel(view_az_el_tilt))+1};
        end
        if(isempty(Lookup))
            L=[];
        else
            L=Lookup{mod(i-1,numel(Lookup))+1};
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
        hemi_options.filename=[];
        optargs=struct2args(hemi_options);
        [imghemi{i},lookuphemi{i},rgbimghemi{i}]=cvnlookupimages(subject, hemivals, h, v, L, optargs{:});
    end
     %[mappedvals,Lookup,rgbimg,options]
    mappedvals=cat(2,imghemi{:});
    for i = 2:numel(rgbimghemi)
        rgbimghemi{i}(:,1:options.hemiborder,:)=options.rgbnan;
    end
    rgbimg=cat(2,rgbimghemi{:});
    Lookup=lookuphemi;
    
    if(~isempty(options.filename))
        imwrite(rgbimg,options.filename);
    end
    return;
end

if(numel(vals)>1 && size(vals,1)==1)
    vals=vals.';
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
%%
% if(~isempty(options.roimask))
%     if(strcmpi(options.surfsuffix,'orig'))
%         sphfile=sprintf('%s/%s.sphere%s',surfdir,hemi,'');
%     else
%         sphfile=sprintf('%s/%s.sphere%s',surfdir,hemi,options.surfsuffix);
%     end
% 
%     [vertsph,~,~] = freesurfer_read_surf_kj(sphfile);
% 
%     roimask=cvnlookupvertex(surfdir,hemi,[],options.surfsuffix,options.roimask);
%     
%     [az_el_tilt xy]=generate_sphere_viewpoints(vertsph,roimask);
% elseif(~isempty(options.roiname))
%     roifile=options.roiname;
%     if(~any(options.roiname=='/' | options.roiname==filesep))
%         roifile=sprintf('%s/%s',surfdir,hemi,options.roiname);
%     end
%     
% end

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
        system(['chmod g+rwx ' lookupdir]);
    end
    cachename=sprintf('%s/%s.mat',lookupdir,makefilename(hemi,az,el,tilt,xyextent(1),xyextent(2),imgN,options.surfsuffix));

    if(exist(cachename,'file') && ~options.reset)
        %load from file
        Lookup=load(cachename);
    else
        %generate a new one and save it
        sphfile=sprintf('%s/%s.sphere%s',surfdir,hemi,options.surfsuffix_file);
        
        [vertsph,~,~] = freesurfer_read_surf_kj(sphfile);

        %recenter and scale to unit sphere
        [c,r]=spherefit(vertsph);
        vertsph=bsxfun(@minus,vertsph,c.')/r;

        Lookup=spherelookup_generate(vertsph,az,el,tilt,options.xyextent,imgN,'verbose',true);

        Lookup.imglookup=uint32(Lookup.imglookup);
        Lookup.reverselookup=uint32(Lookup.reverselookup);
        Lookup.surfsuffix=options.surfsuffix;
        Lookup.surffile=sphfile;
        Lookup.hemi=hemi;
        if(options.savelookup)
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
    Lookup.inputN=sum(validmask);
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
if(~isempty(options.overlayalpha) || ~isempty(options.threshold))
    if(isnumeric(options.background) && size(options.background,1)==size(vals,1))
        %background is same size as "vals" so use spherelookup_vert2image
        mappedcurv=spherelookup_vert2image(options.background,Lookup,nan);

    elseif(isnumeric(options.background) && size(options.background,1)==Lookup.vertsN)
        %background is same size as original surface (ie: lookup), so
        %just a straight lookup
        mappedcurv=options.background(Lookup.imglookup);

    elseif(ischar(options.background))
        %background was a string directing us to a freesurfer overlay
        curvfile=sprintf('%s/%s%s.%s',surfdir,hemi,options.surfsuffix_file,options.background);
        [curv,~]=read_curv(curvfile);
        if(isequal(options.background,'curv'))
            curv=curv<0;
        elseif(isequal(options.background,'sulc'))
            curv=-curv;
        end
        mappedcurv=curv(Lookup.imglookup);
        
    else
        mappedcurv=rgboptions.background;
    end
    rgboptions.background=mappedcurv;
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
    
if(~isempty(options.roiname))
    roimask={};

    for i = 1:numel(options.roiname)
        [roimasktmp roiname roirgbtmp]=cvnroimask(subject,hemi,options.roiname{i},[],options.inputsuffix);
        roimask=[roimask roimasktmp];
        roirgb=[roirgb roirgbtmp];
        
        
    end
    options.roimask=roimask;
    if(~isequal(options.roicolor,{'ctab'}))
        roirgb={};
    end
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
        roiwidth=options.roiwidth{min(i,numel(options.roiwidth))};
        roicolor=roicolor_cell{min(i,numel(roicolor_cell))};
        
        roiwidth=round(roiwidth*2+1);
        
        if(any(roicolor>1))
            roicolor=roicolor/255;
        end
        roicolor=min(max(roicolor(:),0),1);
        
        if(size(roimask,1)==size(vals,1))
            %alpha mask is same size as "vals" so use spherelookup_vert2image
            mappedroi=spherelookup_vert2image(roimask~=0,Lookup,nan);
        elseif(size(roimask,1)==Lookup.vertsN)
            %alpha mask is same size as original surface (ie: lookup), so
            %just a straight lookup
            mappedroi=roimask(Lookup.imglookup);
        else
            error('invalid size for roimask');
        end
        edgekernel=ones(roiwidth);
        edgekernel=edgekernel/sum(edgekernel(:));
        
        mappedroi2=conv2(+mappedroi,edgekernel,'same');
        
        %mappedroi=abs(mappedroi-mappedroi2)>.01;
        mappedroi=(mappedroi-mappedroi2)>.01;
        mappedroi(isnan(mappedroi))=0;
        mappedroi=repmat(mappedroi,1,1,3);
        
        roiimg=repmat(reshape(roicolor,[1 1 3]),size(rgbimg,1),size(rgbimg,2));
        rgbimg=rgbimg.*(1-mappedroi)+roiimg.*(mappedroi);
    end
end

%% If given filename, save RGB image to file 
if(~isempty(options.filename))
    %save
    imwrite(rgbimg,options.filename);
end

%% cellify inputs
function c = cellify(c)
if(isempty(c))
    c={};
elseif(~iscell(c))
    c={c};
end

%% create a filename for lookup containing all relevant parameters
function fname = makefilename(hemi,az,el,tilt,vx,vy,imgN,surfsuffix)

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
fname=sprintf('spherelookup_%s_az%s_el%s_tilt%s_vx%s_vy%s_res%s_%s',hemi,azstr,elstr,tiltstr,vxstr,vystr,resstr,surfsuffix);