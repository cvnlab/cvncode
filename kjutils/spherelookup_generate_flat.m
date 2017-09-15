function [lookup] = spherelookup_generate_flat(vertsph,facesph,azimuth,elevation,tilt,xyextent,imgN,varargin)
%function [lookup] = spherelookup_generate_flat(vertsph,facesph,azimuth,elevation,tilt,xyextent,imgN,options...)
%
% Generates a set of lookups for FLAT PATCH surfaces
%
% Input:
%   vertsph:    Vx3 xyz coordinates for ENTIRE surface
%   azimuth:    **** Interpreted for flat patches as vertical viewpoint offset in mm ***
%   elevation:  **** Interpreted for flat patches as horizontal viewpoint offset in mm ***
%   tilt:       Nx1 camera tilt in degrees. Range=[0,360]
%   xyextent:   [w 0] pair of values between [0 1] 
%   imgN:       Image size (in pixels)
%
% Output: lookup = struct containing: 
%   .imglookup      <imgN> x <imgN> x <#views> lookup for creating image
%                   stack from vertex values
%   .vertmasks      V x <#views> binary masks of which vertices are
%                   included within each view window
%   .lookupmasks    V x <#views> similar to vertmasks but excludes vertices
%                   that do NOT appear in actual lookups (vertices too
%                   close together for nearest-neighbor mapping)
%   .reverselookup  V x <#views> image->vertex lookup (ie: for drawing
%                   ROIs)
%
%   .azimuth
%   .elevation
%   .tilt
%   .xyextent
%   .TXview         4x4x<#views> transformation matrix to rotate the
%                   original sphere to the appropriate view
%   
% Options:
%   reverselookup:  Return image->sphere lookup (default=true)
%   reversevert:    Vx3 vertices to use for reverse lookup 
%                    (default=[] = use vertsph)
%                   NOTE: If not [], MUST match size of vertsph argument
%   verbose:        Print extra ouput
%   silent:         No output printing at all
%

% Update 2017-08-03 KJ: First version of flat surface lookup 

%default options
options=struct(...
    'reverselookup',true,...
    'reversevert',[],...
    'verbose',false,...
    'silent',false);

%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%parse options
input_opts=mergestruct(varargin{:});
fn=fieldnames(input_opts);
for f = 1:numel(fn)
    options.(fn{f})=input_opts.(fn{f});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
xoffset_mm=azimuth;
yoffset_mm=elevation;

%view_az=azimuth(:)*pi/180 -pi/2;
%view_el=elevation(:)*pi/180;
%view_tilt=tilt(:)*pi/180 + pi;
view_az=0;
view_el=pi/2;
view_tilt=tilt(:)*pi/180 -pi/2; %-90deg seems necessary

vertsN=size(vertsph,1);

if(isempty(xyextent))
    xyextent=[.6 .6];
elseif(numel(xyextent)==1)
    xyextent=abs(xyextent)*[1 1];
end


vertmasks=false(vertsN,1);
lookupmasks=false(vertsN,1);
vertidx=(1:vertsN)';

if(options.reverselookup)
    reverselookup=zeros(vertsN,1);
else
    reverselookup=[];
end

TXview=zeros(4,4);

ticstart=tic;


az_tilt=0;

Mtilt=eye(4);
Mtilt(1:2,1:2)=[cos(view_tilt+az_tilt) sin(view_tilt+az_tilt); 
    -sin(view_tilt+az_tilt) cos(view_tilt+az_tilt)];

TXview=Mtilt;
viewvert=affine_transform(TXview,vertsph);

%%%%%%%%%%%%%

%remove vertices outside the patch edge polygon
facesph=cleanflatpatch(facesph,viewvert);
flatmask=false(vertsN,1);
flatmask(unique(facesph(:)))=1;
flatedgeloop=patchedgeloop(facesph,true); %only return longest loop (if multiple exist)


flatverts=viewvert(flatmask,:);
flatvertmid=mean(flatverts,1);
flatvertlim=[min(flatverts); max(flatverts)];
flatvertsize=abs(diff(flatvertlim,[],1));

%%%%%%%%%%%%%%%%%%
%imgsize=[imgN(1) imgN(end)];
imgN0=imgN;
if(numel(imgN)==1)
    imgN=[imgN round(imgN*flatvertsize(2)/flatvertsize(1))];
end
imglookup=zeros(imgN(1),imgN(end));
extrapmask=false(imgN(1),imgN(end));

if(isequal(xyextent,[1 1]))
    xyextent=[round(flatvertsize(1)*100)/100 0];
end

xyextent_mm=xyextent;

xyextent_frac=xyextent;

xyextent_frac=xyextent_mm(1)/flatvertsize(1);
%xyextent_frac(2)=xyextent_frac(1);
% adjust xyextent_frac(2) if (imgN(end)/imgN(1)) != aspect ratio
xyextent_frac(2)=xyextent_frac(1)*(imgN(end)/imgN(1))/(flatvertsize(2)/flatvertsize(1));

pixels_per_mm=imgN(1)/xyextent_mm(1);

%xyextent(1) = mm y
%imgN(1) = pixels y

zview=[-inf inf];
xview=(flatvertlim(:,1)-flatvertmid(1))*xyextent_frac(1) + flatvertmid(1) - xoffset_mm;
yview=(flatvertlim(:,2)-flatvertmid(2))*xyextent_frac(2) + flatvertmid(2) - yoffset_mm;

xview_padded=(flatvertlim(:,1)-flatvertmid(1))*xyextent_frac(1)*1.1 + flatvertmid(1) - xoffset_mm;
yview_padded=(flatvertlim(:,2)-flatvertmid(2))*xyextent_frac(2)*1.1 + flatvertmid(2) - yoffset_mm;

[imgy, imgx] = meshgrid(linspace(yview(1),yview(2),imgN(end)),...
    linspace(xview(1),xview(2),imgN(1)));

pixidx=(1:numel(imgx))';

%%%%%%% create TXpix transform to transform straight from verts -> pixel space
tx=-xview(1);
ty=-yview(1);
sx=(imgN(1)-1)/(xview(2)-xview(1));
sy=(imgN(end)-1)/(yview(2)-yview(1));
sz=mean([sx sy]);
Mpix=[sx 0 0 sx*tx+1; 0 sy 0 sy*ty+1; 0 0 sz 0; 0 0 0 1];
TXpix=Mpix*TXview;

%%%%%%%%%%%%%
    
    viewmask=           viewvert(:,1)>=xview(1) & viewvert(:,1)<=xview(2);
    viewmask=viewmask & viewvert(:,2)>=yview(1) & viewvert(:,2)<=yview(2);
    viewmask=viewmask & viewvert(:,3)>=zview(1) & viewvert(:,3)<=zview(2);
    viewmask=viewmask & flatmask;
    vertmasks=viewmask;
    
    viewmask_padded= viewvert(:,1)>=xview_padded(1) & viewvert(:,1)<=xview_padded(2);
    viewmask_padded=viewmask_padded & viewvert(:,2)>=yview_padded(1) & viewvert(:,2)<=yview_padded(2);
    viewmask_padded=viewmask_padded & viewvert(:,3)>=zview(1) & viewvert(:,3)<=zview(2);
    viewmask_padded=viewmask_padded & flatmask;
    ticimg=tic;
    
    %imglookup(:,:,i)=griddata(viewvert(viewmask,1), viewvert(viewmask,2), ...
    %    vertidx(viewmask),imgx,imgy,'nearest');
    S=scatteredInterpolant(viewvert(viewmask_padded,1), viewvert(viewmask_padded,2), ...
        vertidx(viewmask_padded),'nearest','none');
    tmplookup=S(imgx,imgy);
    extrapmask=isnan(tmplookup);
    inp=inpoly([imgx(:) imgy(:)],viewvert(flatedgeloop,1:2));
    extrapmask=extrapmask | reshape(inp,size(imgx))==0;
    tmplookup(extrapmask)=1;
    imglookup=tmplookup;
    
    if(options.verbose)
        fprintf('Forward lookup table took %.2f seconds\n',toc(ticimg)); 
    end
     
    lookupmasks(imglookup)=1;
    
    %%%%%%%%%%%
    
    if(options.reverselookup)
        vertrev=options.reversevert;
        if(~isempty(vertrev) && size(vertrev,1)~=size(vertsph,1))
            error('options.reversevert MUST match size of vertsph!');
            vertrev=[];
        end

        %if requested, generate image->vertex lookup as well
        %for vertices that don't contribute to a pixel, find the nearest
        %vertex that DOES contribute and use that vertex's pixel lookup
        
        ticrev=tic;

        reverselookup(imglookup)=pixidx;

        %make sure we exclude extrapolated pixels from lookup
        tmpextrap=false(vertsN,1);
        tmpextrap(reverselookup>0)=~extrapmask(reverselookup(reverselookup>0));
        missingverts=viewmask_padded & (~lookupmasks | ~tmpextrap);
        
        if(isempty(vertrev))
            %if using viewverts for reverse lookup, just use X-Y
            %coordinates since those are rotated correctly and planar
            S=scatteredInterpolant(viewvert(viewmask & ~missingverts,1:2), ...
               vertidx(viewmask & ~missingverts),'nearest');
            missinglookup=S(viewvert(missingverts,1:2));
        else
            %if using other verts (eg: inflated) for reverse lookup, 
            % need to use full just use XYZ for lookup.  This takes longer
            S=scatteredInterpolant(vertrev(viewmask & ~missingverts,1:3), ...
                vertidx(viewmask & ~missingverts),'nearest');
            missinglookup=S(vertrev(missingverts,1:3));
        end
        reverselookup(missingverts)=reverselookup(missinglookup);
        
        if(options.verbose)
            fprintf('Reverse lookup table took %.2f seconds\n',toc(ticrev)); 
        end
    end
    %%%%%%%%%%%
    %if(options.verbose)
    %    fprintf('finished %d of %d lookup tables\n',1,1);
    %end


is_extrapolated=squeeze(any(any(extrapmask,1),2));


if(~options.silent)
    view_missing=sum(sum(vertmasks,2)==0);
    lookup_missing=sum(sum(vertmasks,2)>0 & sum(lookupmasks,2)==0);

    view_included=sum(sum(vertmasks,2)>0);
    lookup_included=sum(sum(lookupmasks,2)>0);

    fprintf('\n\n');
    fprintf('Generated %dx%d lookup table in %.2f seconds\n',imgN(1),imgN(end),toc(ticstart)); 
    fprintf('View masks include %d/%d vertices (%d NOT included in any masks = %.2f%%)\n',view_included,vertsN,view_missing,100*view_missing/vertsN);
    fprintf('Lookups include %d/%d masked vertices (%d masked but not found in any lookups = %.2f%%)\n',lookup_included,view_included,lookup_missing,100*lookup_missing/view_included);
end

input2surf=[]; %mapping between surfsuffixes. If needed, handled in cvnlookup
lookup=fillstruct(imglookup,vertmasks,lookupmasks,reverselookup,extrapmask,is_extrapolated,azimuth,elevation,tilt,imgN,vertsN,TXview,xyextent,input2surf, ...
    pixels_per_mm, xyextent_mm, xview, yview, zview, TXpix);
