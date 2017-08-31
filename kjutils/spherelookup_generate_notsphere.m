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

% KJ 2017-02-21 Improvement to reverse lookup (for drawing ROIs on
%               nonsphere views).  It significantly increases the time to
%               generate a new lookup though.
% KJ 2017-02-22 Use mesh adjacency for much faster reverse lookup creation
%               (to prune before costly nn interp step)

if(~exist('imgheight','var') || isempty(imgheight))
    imgheight=[];
end

exportheight=1000;

if(~isempty(imgheight) && imgheight~=exportheight)
    scalefactor=round(100*imgheight/exportheight)/100;
else
    scalefactor=1;
end
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
axis manual; %don't allow any more automatic axis resizing

vmin=min(viewvert,[],1);
vmax=max(viewvert,[],1);

vmid=(vmin+vmax)/2;
vsize=vmax-vmin;

vxlim=vmid(1)+max(vsize)*[-.5 .5]*1.1;
vylim=vmid(2)+max(vsize)*[-.5 .5]*1.1;

set(gca,'units','normalized','position',[0 0 1 1]);
%set(gca,'xlim',[vmin(1) vmax(1)],'ylim',[vmin(2) vmax(2)]);
set(gca,'xlim',vxlim,'ylim',vylim);

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

%% create reverse lookup

% first map all vertices that show up in the lookup
reverselookup=zeros(vertsN,1);
pixidx=(1:numel(imgx))';
reverselookup(imglookup(~extrapmask))=pixidx(~extrapmask);

%%%%%%%%%
% now find the missing vertices that are NOT occluded
%%%%%%%%
missingverts=reverselookup==0;
notmissing=~missingverts;

% start by transforming vertices to pixel space
pixvert=bsxfun(@minus,viewvert,min(viewvert(notmissing,:),[],1));

[yp,xp]=ind2sub(size(imglookup),reverselookup(notmissing));
yp=size(imglookup,1)-yp+1;

xt=[pixvert(notmissing,1) ones(size(xp))]\xp;
yt=[pixvert(notmissing,2) ones(size(xp))]\yp;
zt=(xt+yt)/2;

pixvert(:,1)=[pixvert(:,1) ones(vertsN,1)]*xt;
pixvert(:,2)=[pixvert(:,2) ones(vertsN,1)]*yt;
pixvert(:,3)=[pixvert(:,3) ones(vertsN,1)]*zt;

% maximum number of dilations to try
imax=100;

dimdist=3; %use 2D or 3D distance to assign non-occluded missing reverselookup?
reverse_maxdist=2; %in pixels

missingnn=zeros(vertsN,1); % index of nearest "visible" vert
missingiter=zeros(vertsN,1); % # of dilations for "visible" to reach each vert
missingdist=zeros(vertsN,1); % # 2D or 3D (dimdist) pixel space distance to nearest visible vert

missingnn(notmissing)=find(notmissing);
missingiter(missingverts)=inf;
missingdist(missingverts)=inf;

%just using mesh_diffuse_fast to create the sparse adjacency matrix
[~,Adj]=mesh_diffuse_fast(vertsN,surf.faces);

notmissing0=notmissing;


for i = 1:imax
    notmissing=(Adj*double(notmissing0))>0;
    newidx=notmissing0==0 & notmissing>0;

    [a,b]=find(Adj(newidx,:));
    %which neighbors are already in our missingnn list?
    nntmp=missingnn(b);
    a=a(nntmp>0);
    b=b(nntmp>0);
    %copy missingnn from first neighbor
    %NOTE: neigbor order is arbitrary, but all neighbors should be
    %close-ish so this likely won't matter.  final missingnn is done after
    %this loop using euclidian distance
    newnn=zeros(sum(newidx),1);
    newnn(a)=b;
    
    missingiter(newidx)=i;
    missingnn(newidx)=missingnn(newnn);
    missingdist(newidx)=sqrt(sum((pixvert(newidx,1:dimdist)-pixvert(missingnn(newnn),1:dimdist)).^2,2));
    
    if(min(missingdist(newidx))>(2*reverse_maxdist))
        %if all new verts are > 2*maxdist pixels from their closest "pixel visible"
        %neighbour, we are done finding the "lookup visible" missing, and 
        %the rest are occluded
        imax=i;
        break;
    end
    notmissing0=notmissing>0;
end

notmissing=missingiter==0;
visiblemissing=find(missingdist>0 & missingdist<=(2*reverse_maxdist));
%reverselookup(visiblemissing)=reverselookup(missingnn(visiblemissing));

%Now do euclidian distance to find nearest lookup-visible vertex to each
%putative not-occluded vertex.  Prune list to only those with 
%euclidian distance <= 2 pixels)
S=scatteredInterpolant(pixvert(notmissing,1:dimdist),find(notmissing),'nearest');
newnn=S(pixvert(visiblemissing,1:dimdist));
distnn=sqrt(sum((pixvert(visiblemissing,1:dimdist)-pixvert(newnn,1:dimdist)).^2,2));

visiblemissing=visiblemissing(distnn<=reverse_maxdist);
newnn=newnn(distnn<=reverse_maxdist);
reverselookup(visiblemissing)=reverselookup(newnn);
%%

lookup=fillstruct(imglookup,vertmasks,lookupmasks,reverselookup,extrapmask,is_extrapolated,azimuth,elevation,tilt,imgN,vertsN,TXview,xyextent,xview,yview,zview);

lookup.shading=imgshading;
%lookup.imgsize=imgsz;

