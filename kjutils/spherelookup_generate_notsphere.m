function lookup = spherelookup_generate_notsphere(vertices,faces,azimuth,elevation,tilt,imgheight)
%function [lookup] = spherelookup_generate_notsphere(vertices,faces,viewpt,imgheight)
%
% Generates a set of lookups for NON-spherical surfaces
%
% Input:
%   vertices:   Vx3 xyz coordinates
%   faces:      Fx3 vertex indices for each triangular face
%   azimuth:    Nx1 azimuth in degrees. Range=[0,360], 0 = -y
%   elevation:  Nx1 elevation in degrees. Range=[-90,90], 90 = +z 
%   tilt:       Nx1 camera tilt in degrees. Range=[0,360]
%   imgheight:  Image height (in pixels)
%
% Output: lookup = same as spherelookup_generate, but also:
%   .shading    MxN image overlay to apply shading on subsequent images

if(~exist('imgheight','var') || isempty(imgheight))
    imgheight=[];
end

exportheight=1000;

scalefactor=1;

surf=struct('faces',faces,'vertices',vertices);

val=(1:size(surf.faces,1)).';
%val=(1:size(surf.vertices,1)),';

valrgb=floor(val/(256*256));
valrgb=[valrgb floor(mod(val,256*256)/256)];
valrgb=[valrgb mod(val,256)];
valrgb=valrgb/255;

%%
%        azimuth=viewpt(1);
%        elevation=viewpt(2);
%        tilt=viewpt(3);
        
        view_az=azimuth(:)*pi/180 -pi/2;
        view_el=elevation(:)*pi/180;
        view_tilt=tilt(:)*pi/180 + pi;


        [x,y,z]=sph2cart(view_az,view_el,1);
        %viewpts=[x y z];
        v3=[x y z];
        
    i=1;
    az_tilt=pi/2;
    
    %v3=viewpts(i,:);
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

    verts=surf.vertices;
    %verts(:,1)=-verts(:,1);
    viewvert=affine_transform(TXview,verts);
        
%%
fig=figure('visible','off','color','r');
%p=patch(surf,'facevertexcdata',valrgb,'facecolor','flat','linestyle','none');
p=patch('faces',surf.faces,'vertices',viewvert,'facevertexcdata',valrgb,'facecolor','flat','linestyle','none');

axis vis3d equal;

fullscreen(gcf);
fpos=get(gcf,'position');
%fpos([3 4])=max(fpos([3 4]));
fpos([3 4])=exportheight;
set(gcf,'position',fpos);
%axis off tight;
axis off;

vmin=min(viewvert,[],1);
vmax=max(viewvert,[],1);

vmid=(vmin+vmax)/2;
vsize=vmax-vmin;


set(gca,'units','normalized','position',[0 0 1 1]);
%set(gca,'xlim',[vmin(1) vmax(1)],'ylim',[vmin(2) vmax(2)]);
set(gca,'xlim',vmid(1)+max(vsize)*[-.5 .5]*1.1,'ylim',vmid(2)+max(vsize)*[-.5 .5]*1.1);

scalestr=sprintf('-m%d',scalefactor);

img=export_fig(gca,'-a1',scalestr,'-nocrop');



img=double(img);
imgval=img(:,:,1)*256*256 + img(:,:,2)*256 + img(:,:,3);
lookup_faces=imgval;

%close(fig);

%% show solid green surface with lighting
%fig=figure('visible','off','color','r');
%patch(surf,'facecolor','g','linestyle','none');

%material dull;
%axis vis3d equal;

%view(viewpt);
%fullscreen(gcf);
%axis off tight;
set(p,'facecolor','g');
material dull;
camlight headlight
%pixpos=getpixelposition(gca);
img=export_fig(gca,'-a1',scalestr,'-nocrop');

hsvmask=rgb2hsv(img);

imgmask=hsvmask(:,:,1)>0;
imgshading=hsvmask(:,:,3);

close(fig);


%% crop images

xcrop=any(imgmask>0,2);
ycrop=any(imgmask>0,1);


xcrop=[find(xcrop,1,'first') find(xcrop,1,'last')];
ycrop=[find(ycrop,1,'first') find(ycrop,1,'last')];
% 
% if(~isempty(imgheight) && (ycrop(2)-ycrop(1)+1)<imgheight)
%     y0=floor((ycrop(1)+ycrop(2))/2 - imgheight/2);
%     y0=max(y0,1);
%     ycrop=[y0 y0+imgheight-1];
% end
%     
lookup_faces=lookup_faces(xcrop(1):xcrop(2),ycrop(1):ycrop(2));
imgmask=imgmask(xcrop(1):xcrop(2),ycrop(1):ycrop(2));
imgshading=imgshading(xcrop(1):xcrop(2),ycrop(1):ycrop(2));

lookup_faces=lookup_faces.*imgmask;
lookup_faces(lookup_faces==0)=1;


%%
facemask=false(size(surf.faces,1),1);
facemask(unique(lookup_faces(imgmask)))=true;

vertmask=false(size(surf.vertices,1),1);
vertmask(surf.faces(facemask))=true;

viewmask_padded=vertmask;
vertidx=(1:size(surf.vertices,1)).';

vmin=min(viewvert(viewmask_padded,:),[],1);
vmax=max(viewvert(viewmask_padded,:),[],1);

yview=[vmin(2) vmax(2)];
xview=[vmin(1) vmax(1)];
imgsz=size(lookup_faces);

S=scatteredInterpolant(viewvert(viewmask_padded,1), viewvert(viewmask_padded,2), ...
    vertidx(viewmask_padded),'nearest','none');

[imgx, imgy] = meshgrid(linspace(xview(1),xview(2),imgsz(2)),...
    linspace(yview(1),yview(2),imgsz(1)));
imgy=flipud(imgy);
lookup=S(imgx,imgy);
% 
% figure;
% imagesc(lookup);
% axis image;
%%
imgmask=imgmask & isfinite(lookup);
lookup(~isfinite(lookup))=0;
lookup=lookup.*imgmask;
lookup(lookup==0)=1;

%%
imglookup=lookup;
vertmasks=vertmask;
lookupmasks=vertmask;
extrapmask=~imgmask | ~vertmask(lookup);
is_extrapolated=true;
imgN=imgsz;
vertsN=size(surf.vertices,1);
xyextent=[1 1];
reverselookup=zeros(vertsN,1);
%%
pixidx=(1:numel(imgx))';
reverselookup(imglookup)=pixidx;

%%
lookup=fillstruct(imglookup,vertmasks,lookupmasks,reverselookup,extrapmask,is_extrapolated,azimuth,elevation,tilt,imgN,vertsN,TXview,xyextent);

lookup.shading=imgshading;
%lookup.imgsize=imgsz;

