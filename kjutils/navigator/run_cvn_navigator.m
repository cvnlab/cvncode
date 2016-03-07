function test_cvn_navigator
clear all;
close all;
clc;

% calc
subjectid='C0041';

datadir=sprintf('%s/20160212-ST001-E002',cvnpath('fmridata'));


epirange=[-10 10];

%%

alignfile=sprintf('%s/freesurferalignment/alignment.mat',datadir);
load(alignfile);


t1nifti = sprintf('%s/freesurferalignment/T1alignedtoEPI.nii.gz',datadir);
t2nifti = sprintf('%s/freesurferalignment/T2alignedtoEPI.nii.gz',datadir);
meanfunctional=sprintf('%s/preprocess/mean.nii',datadir);

t1vol=loadvol(t1nifti);
t2vol=loadvol(t2nifti);
epivol=loadvol(meanfunctional);


meanvol=epivol;
anatvol=t2vol;

addpath(cleanpath(genpath('~/Source/alignvolumedata')));

%% what I want: surface vertex location... convert to EPI coordinate

%%%%%%%%%%%%%%%%%%%%%%%%%%%
glmdir=sprintf('%s/glmdenoise_results',datadir);
%R2=double(getfield(load_nii(sprintf('%s/%s_R2.nii',glmdir,subjectid)),'img'));
%SNR=double(getfield(load_nii(sprintf('%s/%s_SNR.nii',glmdir,subjectid)),'img'));
tfaces=loadvol(sprintf('%s/%s_tstat_faces.nii',glmdir,subjectid));
tfaces_layers=load(sprintf('%s/%s_tstat_faces.mat',glmdir,subjectid));

funcvol=tfaces;

%% load anatomical surfaces

samplevol=funcvol;
samplesurf='layerA1';
displaysurf='inflated';
surfsuffix='DENSETRUNCpt';


%%%%%%%%%%%%%%%%%%%%%%%%%%%
[surfL,surfR]=cvnreadsurface(subjectid,{'lh','rh'},samplesurf,surfsuffix);
[surfLR, epiverts] = surface_verts_to_volume(surfL,surfR,tr);

[surfslices, surfidx]=load_surface_slices(subjectid,datadir,{'white','pial'},surfsuffix);

[surfdisplayL,surfdisplayR]=cvnreadsurface(subjectid,{'lh','rh'},displaysurf,surfsuffix);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%surfdata = sample_vol_to_surf(samplevol, epiverts);

%surfdata=reshape(mean(tfaces_layers.data(:,1:6,:),2),[],1);
%surfdata=reshape(mean(tfaces_layers.data(:,4,:),2),[],1);
surfdata=reshape(tfaces_layers.data(:,1,:),[],1);


%curvL=-read_curv(sprintf('%s/%s/surf/lhDENSETRUNCpt.sulc',cvnpath('freesurfer'),subjectid));
%curvL=surfdata(1:surfL.vertsN);

view_az_el_tilt={[-10 -40 180],[10 -40 180]}; %occip
%view_az_el_tilt={[-10 -70 0],[10 -70 0]}; %FFA
%view_az_el_tilt={[10 -40 0],[-10 -40 0]}; %hemis = lh,rh

valstruct=struct('data',surfdata,'numlh',surfLR.numvertsL,'numrh',surfLR.numvertsR);
[img,lookup,rgbimg]=cvnlookupimages(subjectid,valstruct,{'rh','lh'},...
    view_az_el_tilt,[],'xyextent',[1 1],'surfsuffix',surfsuffix,...
    'roiname','*_kj','roicolor','w','colormap','colormap_roybigbl','clim',epirange,...
    'background','curv','alpha',[],'absthreshold',[2],...
    'text',{'RH','LH'});


%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% create 3d surface view
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figsurf=figure('units','normalized','position',[0 0 .5 .45]);

surfdisplay_hemi='rh';

if(isequal(surfdisplay_hemi,'lh'))
    hsurf=patch(surfdisplayL,'facevertexcdata',surfdata(surfLR.vertidxL),...
        'facecolor','interp','linestyle','none','linewidth',.001);
    h=1;
else
    hsurf=patch(surfdisplayR,'facevertexcdata',surfdata(surfLR.vertidxR),...
        'facecolor','interp','linestyle','none','linewidth',.001);
    h=2;
end
colormap gray;
axis vis3d equal;
hold on;
psurf=plot3(nan,nan,nan,'ro');
material dull;

set(gca,'clim',epirange);

if(iscell(view_az_el_tilt))
    view(view_az_el_tilt{h}(1:2));
else
    view(view_az_el_tilt(1:2));
end


camlight headlight;
RotationHeadlight(figsurf,false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% create 3d volume view(s)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%epirange=prctile(reshape(epivol(isfinite(epivol)),[],1),[50 99]);
anatrange=prctile(reshape(anatvol(isfinite(anatvol)),[],1),[1 99]);

%epirange(1)=-1;
anatrange(1)=-1;

%alphavol=[];
alphavol=+abs(tfaces)>2;
%fig3d=orthogui(anatmatch3,'colormap','gray','clim',[0 inf],'dim',[-2 -3 1]);

fig_epi=orthogui(funcvol,'colormap',colormap_roybigbl(256),'clim',epirange,'background',meanvol,...
    'dim',[-2 -3 -1],'link',1,'cursorgap',1,'maxalpha',1,'alpha',alphavol,'surfslices',surfslices,...
    'callback',@(xyz)(cvnnavigator_callback('orthogui',xyz)));

fig_anat=orthogui(meanvol,'colormap','gray','clim',[0 inf],'background',anatvol,...
    'dim',[-2 -3 -1],'link',1,'cursorgap',1,'surfslices',surfslices,...
    'callback',@(xyz)(cvnnavigator_callback('orthogui',xyz)));
%fig_anat(2)=orthogui(anatmatch1,'colormap','gray','clim',[0 inf],'dim',[-2 -3 -1],'link',1,'cursorgap',10);

orthogui('help'); %print keyboard commands

set(fig_epi,'units','normalized','position',[.5 0 .5 .5]);
set(fig_anat,'units','normalized','position',[.5 .5 .5 .5]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% create flat view
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fig_flat=figure('units','normalized','position',[0 .5 .5 .5],'tag','figflat');
himg=image(rgbimg);
set(gca,'xtick',[],'ytick',[]);
axis tight image;
colormap gray;
hold on;

pflat=   plot(nan,nan,'ko','markersize',5);
pflat(2)=plot(nan,nan,'wo','markersize',7);
pflat(3)=plot(nan,nan,'ko','markersize',9);

set(gca,'buttondownfcn',@cvnnavigator_callback);
set(hsurf,'buttondownfcn',{@patchclick_callback,@cvnnavigator_callback});

set([pflat himg psurf],'hittest','off');
setappdata(fig_flat,'appdata',fillstruct(fig_epi,fig_flat,fig_anat,hsurf,psurf,pflat,lookup,surfLR,epiverts,surfdisplay_hemi));

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function voldata = loadvol(niifile)
% load the T2 anatomy
vol = load_untouch_nii(gunziptemp(niifile));
voldata = double(vol.img);
voldata(isnan(voldata)) = 0;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [surfLR, epiverts] = surface_verts_to_volume(surfL,surfR,tr)


surfLR=struct('vertices',[surfL.vertices; surfR.vertices],...
    'faces',[surfL.faces; surfR.faces+size(surfL.vertices,1)]);
surfLR.vertices=bsxfun(@plus,surfLR.vertices,[128 129 128]);  % NOTICE THIS!!!
surfLR.numvertsL=size(surfL.vertices,1);
surfLR.numvertsR=size(surfR.vertices,1);
surfLR.numverts=surfLR.numvertsL+surfLR.numvertsR;
surfLR.vertidxL=reshape(1:surfLR.numvertsL,[],1);
surfLR.vertidxR=reshape((1:surfLR.numvertsR)+surfLR.numvertsL,[],1);
surfLR.neighbors=vertex_neighbours(surfLR);


epiverts4d = volumetoslices([surfLR.vertices ones(surfLR.numverts,1)].',tr);
epiverts=epiverts4d(1:3,:)';

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function surfdata = sample_vol_to_surf(voldata, epiverts)
epiverts(:,4)=1;
surfdata = reshape(ba_interp3_wrapper(voldata,epiverts.'),[],1);
surfdata(isnan(surfdata))=0;
