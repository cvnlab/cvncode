function [lookup] = generate_sphere_lookup(vertsph,azimuth,elevation,tilt,xyextent,imgN,varargin)
%function [lookup] = generate_sphere_lookup(vertsph,viewpts,xyextent,imgN,tilt,options...)
%
%Generates a set of lookups
%
%Input:
%   vertsph:    Vx3 xyz coordinates for ENTIRE sphere
%   azimuth:    Nx1 azimuth in degrees. Range=[0,360], 0 = -y
%   elevation:  Nx1 elevation in degrees. Range=[-90,90], 90 = +z 
%   tilt:       Nx1 camera tilt in degrees. Range=[0,360]
%   xyextent:   [w h] pair of values between [0 1] 
%   imgN:       Image size (in pixels)
%
%Output: lookup = struct containing: 
%   .imglookup      <imgN> x <imgN> x <#views> lookup for creating image
%                   stack from vertex values
%   .vertmasks      V x <#views> binary masks of which vertices are
%                   included within each view window
%   .lookupmasks    V x <#views> similar to vertmasks but excludes vertices
%                   that do NOT appear in actual lookups (vertices too
%                   close together for nearest-neighbor mapping)
%
%   .azimuth
%   .elevation
%   .tilt
%   .xyextent
%
%Options:
%   verbose:        Print extra ouput
%   silent:         No output printing at all

%default options
options=struct(...
    'verbose',false,...
    'silent',false);

%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%parse options
input_opts=struct(varargin{:});
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

xview_buffer=xview.*1.1;
yview_buffer=yview.*1.1;

vertmasks=false(vertsN,viewN);
lookupmasks=false(vertsN,viewN);

%[imgx, imgy] = meshgrid(linspace(xview(1),xview(2),imgN),...
%    linspace(yview(1),yview(2),imgN));
    
[imgy, imgx] = meshgrid(linspace(yview(1),yview(2),imgN(end)),...
    linspace(xview(1),xview(2),imgN(1)));

vertidx=(1:vertsN)';
imglookup=zeros(imgN(1),imgN(end),viewN);
extrapmask=false(imgN(1),imgN(end),viewN);
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
    
    viewvert=affine_transform(Mtilt*M,vertsph);

    viewmask=           viewvert(:,1)>=xview(1) & viewvert(:,1)<=xview(2);
    viewmask=viewmask & viewvert(:,2)>=yview(1) & viewvert(:,2)<=yview(2);
    viewmask=viewmask & viewvert(:,3)>=zview(1) & viewvert(:,3)<=zview(2);
    vertmasks(:,i)=viewmask;
    
    viewmask_buffered= viewvert(:,1)>=xview_buffer(1) & viewvert(:,1)<=xview_buffer(2);
    viewmask_buffered=viewmask_buffered & viewvert(:,2)>=yview_buffer(1) & viewvert(:,2)<=yview_buffer(2);
    viewmask_buffered=viewmask_buffered & viewvert(:,3)>=zview(1) & viewvert(:,3)<=zview(2);

    tic
    
    %imglookup(:,:,i)=griddata(viewvert(viewmask,1), viewvert(viewmask,2), ...
    %    vertidx(viewmask),imgx,imgy,'nearest');
    S=scatteredInterpolant(viewvert(viewmask_buffered,1), viewvert(viewmask_buffered,2), ...
        vertidx(viewmask_buffered),'nearest','none');
    tmplookup=S(imgx,imgy);
    extrapmask(:,:,i)=isnan(tmplookup);
    tmplookup(extrapmask(:,:,i))=1;
    imglookup(:,:,i)=tmplookup;
    
    if(options.verbose)
        toc
    end
    
    lookupmasks(imglookup(:,:,i),i)=1;
    
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

lookup=fillstruct(imglookup,vertmasks,lookupmasks,extrapmask,is_extrapolated,azimuth,elevation,tilt,imgN,vertsN);
