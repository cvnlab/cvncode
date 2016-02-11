function [lookup] = spherelookup_generate(vertsph,azimuth,elevation,tilt,xyextent,imgN,varargin)
%function [lookup] = spherelookup_generate(vertsph,viewpts,xyextent,imgN,tilt,options...)
%
% Generates a set of lookups
%
% Input:
%   vertsph:    Vx3 xyz coordinates for ENTIRE sphere
%   azimuth:    Nx1 azimuth in degrees. Range=[0,360], 0 = -y
%   elevation:  Nx1 elevation in degrees. Range=[-90,90], 90 = +z 
%   tilt:       Nx1 camera tilt in degrees. Range=[0,360]
%   xyextent:   [w h] pair of values between [0 1] 
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

% Update 2016-01-26 KJ: Add reverselookup for ROI drawing
% Update 2016-02-11 KJ: Add option to use different verts for reverselookup
%                           (eg: inflated)

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
 
view_az=azimuth(:)*pi/180 -pi/2;
view_el=elevation(:)*pi/180;
view_tilt=tilt(:)*pi/180 + pi;


[x,y,z]=sph2cart(view_az,view_el,1);
viewpts=[x y z];


viewN=size(viewpts,1);
vertsN=size(vertsph,1);

if(isempty(xyextent))
    xyextent=[.6 .6];
elseif(numel(xyextent)==1)
    xyextent=abs(xyextent)*[1 1];
end

zview=[0 inf];
xview=[-xyextent(1) xyextent(1)];
yview=[-xyextent(2) xyextent(2)];

xview_padded=xview.*1.1;
yview_padded=yview.*1.1;

vertmasks=false(vertsN,viewN);
lookupmasks=false(vertsN,viewN);

%[imgx, imgy] = meshgrid(linspace(xview(1),xview(2),imgN),...
%    linspace(yview(1),yview(2),imgN));
    
[imgy, imgx] = meshgrid(linspace(yview(1),yview(2),imgN(end)),...
    linspace(xview(1),xview(2),imgN(1)));

vertidx=(1:vertsN)';
pixidx=(1:numel(imgx))';
imglookup=zeros(imgN(1),imgN(end),viewN);
extrapmask=false(imgN(1),imgN(end),viewN);

if(options.reverselookup)
    reverselookup=zeros(vertsN,viewN);
else
    reverselookup=[];
end

TXview=zeros(4,4,viewN);

ticstart=tic;
for i = 1:viewN

    az_tilt=0;
    
    v3=viewpts(i,:);
    v3=v3/norm(v3);
    if(sqrt(v3(1:2)*v3(1:2)') < 1e-3)
        v2=cross(v3,[0 1 0]);
        v2=v2/norm(v2);
        v1=-cross(v3,v2);
        v1=v1/norm(v1);
        
        if(v3(3)<0)
            az_tilt=-azimuth(i)*pi/180; %%%%!!!! ugly...
            if(abs(az_tilt)<1e-3)
                az_tilt=az_tilt+pi;
            end
        else
            az_tilt=azimuth(i)*pi/180;
        end
        
        

    else
        v2=cross(v3,[0 0 1]);
        v2=v2/norm(v2);
        v1=cross(v2,v3);
        v1=v1/norm(v1);
    end
    
    Mtilt=eye(4);
    Mtilt(1:2,1:2)=[cos(view_tilt(i)+az_tilt) sin(view_tilt(i)+az_tilt); 
        -sin(view_tilt(i)+az_tilt) cos(view_tilt(i)+az_tilt)];

    M=eye(4);
    M(1:3,1:3)=inv([v1(:) v2(:) v3(:)]);
    
    TXview(:,:,i)=Mtilt*M;
    viewvert=affine_transform(TXview(:,:,i),vertsph);

    viewmask=           viewvert(:,1)>=xview(1) & viewvert(:,1)<=xview(2);
    viewmask=viewmask & viewvert(:,2)>=yview(1) & viewvert(:,2)<=yview(2);
    viewmask=viewmask & viewvert(:,3)>=zview(1) & viewvert(:,3)<=zview(2);
    vertmasks(:,i)=viewmask;
    
    viewmask_padded= viewvert(:,1)>=xview_padded(1) & viewvert(:,1)<=xview_padded(2);
    viewmask_padded=viewmask_padded & viewvert(:,2)>=yview_padded(1) & viewvert(:,2)<=yview_padded(2);
    viewmask_padded=viewmask_padded & viewvert(:,3)>=zview(1) & viewvert(:,3)<=zview(2);

    ticimg=tic;
    
    %imglookup(:,:,i)=griddata(viewvert(viewmask,1), viewvert(viewmask,2), ...
    %    vertidx(viewmask),imgx,imgy,'nearest');
    S=scatteredInterpolant(viewvert(viewmask_padded,1), viewvert(viewmask_padded,2), ...
        vertidx(viewmask_padded),'nearest','none');
    tmplookup=S(imgx,imgy);
    extrapmask(:,:,i)=isnan(tmplookup);
    tmplookup(extrapmask(:,:,i))=1;
    imglookup(:,:,i)=tmplookup;
    
    if(options.verbose)
        fprintf('Forward lookup table took %.2f seconds\n',toc(ticimg)); 
    end
     
    lookupmasks(imglookup(:,:,i),i)=1;
    
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

        reverselookup(imglookup(:,:,i),i)=pixidx;

        %make sure we exclude extrapolated pixels from lookup
        tmpextrap=false(vertsN,1);
        tmpextrap(reverselookup>0)=~extrapmask(reverselookup(reverselookup>0));
        missingverts=viewmask_padded & (~lookupmasks(:,i) | ~tmpextrap);
        
        if(isempty(vertrev))
            %if using viewverts for reverse lookup, just use X-Y
            %coordinates since those are rotated correctly and planar
            S=scatteredInterpolant(viewvert(viewmask & ~missingverts,1), viewvert(viewmask & ~missingverts,2), ...
               vertidx(viewmask & ~missingverts),'nearest');
            missinglookup=S(viewvert(missingverts,1), viewvert(missingverts,2));
        else
            %if using other verts (eg: inflated) for reverse lookup, 
            % need to use full just use XYZ for lookup.  This takes longer
            S=scatteredInterpolant(vertrev(viewmask & ~missingverts,1), vertrev(viewmask & ~missingverts,2), ...
                vertrev(viewmask & ~missingverts,3),vertidx(viewmask & ~missingverts),'nearest');
            missinglookup=S(vertrev(missingverts,1), vertrev(missingverts,2), vertrev(missingverts,3));
        end
        reverselookup(missingverts,i)=reverselookup(missinglookup);
        
        if(options.verbose)
            fprintf('Reverse lookup table took %.2f seconds\n',toc(ticrev)); 
        end
    end
    %%%%%%%%%%%
    if(options.verbose)
        fprintf('finished %d of %d lookup tables\n',i,viewN);
    end
end

is_extrapolated=squeeze(any(any(extrapmask,1),2));


if(~options.silent)
    view_missing=sum(sum(vertmasks,2)==0);
    lookup_missing=sum(sum(vertmasks,2)>0 & sum(lookupmasks,2)==0);

    view_included=sum(sum(vertmasks,2)>0);
    lookup_included=sum(sum(lookupmasks,2)>0);

    fprintf('\n\n');
    if(viewN==1)
        fprintf('Generated %dx%d lookup table in %.2f seconds\n',imgN,imgN,toc(ticstart)); 
    else
        fprintf('Generated %d %dx%d lookup tables in %.2f seconds\n',viewN,imgN,imgN,toc(ticstart)); 
    end
    fprintf('View masks include %d/%d vertices (%d NOT included in any masks = %.2f%%)\n',view_included,vertsN,view_missing,100*view_missing/vertsN);
    fprintf('Lookups include %d/%d masked vertices (%d masked but not found in any lookups = %.2f%%)\n',lookup_included,view_included,lookup_missing,100*lookup_missing/view_included);
end

lookup=fillstruct(imglookup,vertmasks,lookupmasks,reverselookup,extrapmask,is_extrapolated,azimuth,elevation,tilt,imgN,vertsN,TXview,xyextent);
