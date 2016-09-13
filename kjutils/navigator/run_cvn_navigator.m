function run_cvn_navigator

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
swinifti = '/home/range1-raid1/kjamison/stonedata/kk_swi/kk_swi_mag_swap_reg2.nii.gz';
%swinifti = '/home/range1-raid1/kjamison/stonedata/kk_swi/kk_swi_20160212_mag_swap_reg2.nii.gz';
meanfunctional=sprintf('%s/preprocess/mean.nii',datadir);

t1vol=loadvol(t1nifti);
t2vol=loadvol(t2nifti);
swivol=loadvol(swinifti);
epivol=loadvol(meanfunctional);

% can cycle through these backgrounds in orthogui by pressing 'b'
%background_vols={t1vol,t2vol,swivol,epivol};
background_vols={swivol,epivol};
bgidx_swi=1;
bgidx_epi=2;
%bgidx_t1=1;
%bgidx_t2=2;
%bgidx_swi=3;
%bgidx_epi=4;

for i = 1:numel(background_vols)
    bgmax=prctile(background_vols{i}(~isnan(background_vols{i}(:))),99.5);
    if(~isnan(bgmax) && bgmax ~= 0)
        background_vols{i}=min(background_vols{i},bgmax);
        background_vols{i}=background_vols{i}/bgmax;
    end
end

meanvol=epivol;
%anatvol=t2vol;
anatvol=background_vols{bgidx_swi};
addpath(cleanpath(genpath('~/Source/alignvolumedata')));

%% what I want: surface vertex location... convert to EPI coordinate

%%%%%%%%%%%%%%%%%%%%%%%%%%%
glmdir=sprintf('%s/glmdenoise_results',datadir);
%R2=double(getfield(load_nii(sprintf('%s/%s_R2.nii',glmdir,subjectid)),'img'));
%SNR=double(getfield(load_nii(sprintf('%s/%s_SNR.nii',glmdir,subjectid)),'img'));

resultfile=sprintf('%s/glmdenoiseVOL_results.mat',glmdir);
fprintf('loading %s\n',resultfile);
M=matfile(resultfile);
Mmd=M.modelmd;
Mse=M.modelse;

Mmd=Mmd{2};
Mse=Mse{2};
con1=[5 6];
con2=setdiff(1:10,con1);
tfaces=compute_glm_metric(Mmd,Mse,con1,con2,'tstat',4);
meanvol=M.meanvol;

tfaces_layers={};
meanvol_layers={};

for i = 1:6
    resultfile=sprintf('%s/glmdenoise_results_layer%d.mat',glmdir,i);
    fprintf('loading %s\n',resultfile);
    M=matfile(resultfile);
    Mmd=M.modelmd;
    Mse=M.modelse;
    Mmd=Mmd{2};
    Mse=Mse{2};
    tfaces_layers{i}=compute_glm_metric(Mmd,Mse,con1,con2,'tstat',2);
    meanvol_layers{i}=M.meanvol;
end
fprintf('Finished loading data\n');

tfaces_layers.data=catcell(2,tfaces_layers);
tfaces_layers.data=permute(tfaces_layers.data,[3 2 1]);

meanvol_layers=catcell(2,meanvol_layers);

%tfaces=loadvol(sprintf('%s/%s_tstat_faces.nii',glmdir,subjectid));
%tfaces_layers=load(sprintf('%s/%s_tstat_faces.mat',glmdir,subjectid));

funcvol=tfaces;

%% load anatomical surfaces

samplevol=funcvol;
samplesurf='layerA1';
displaysurf='inflated';
surfsuffix='DENSETRUNCpt';
hemis={'lh','rh'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%
[surfL,surfR]=cvnreadsurface(subjectid,{'lh','rh'},samplesurf,surfsuffix);
numlh=size(surfL.vertices,1);
numrh=size(surfR.vertices,1);

[surfLR, epiverts] = surface_verts_to_volume(surfL,surfR,tr);

%%%%%%%%%%%%% generate surface slices for orthogui
surfslices=[];
surfidx=[];
fprintf('Generating surface slices...');
stic=tic;
[surfslices, surfidx]=load_surface_slices(subjectid,datadir,{'white','pial'},surfsuffix);
fprintf('Done!  Computation took %.3f seconds.\n',toc(stic));
%%%%%%%%%%%%

[surfdisplayL,surfdisplayR]=cvnreadsurface(subjectid,{'lh','rh'},displaysurf,surfsuffix);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%surfdata = sample_vol_to_surf(samplevol, epiverts);

%surfdata=reshape(mean(tfaces_layers.data(:,1:6,:),2),[],1);
%surfdata=reshape(mean(tfaces_layers.data(:,4,:),2),[],1);
%surfdata=reshape(tfaces_layers.data(:,1,:),[],1);
surfdata=meanvol_layers(:,3);

%curvL=-read_curv(sprintf('%s/%s/surf/lhDENSETRUNCpt.sulc',cvnpath('freesurfer'),subjectid));
%curvL=surfdata(1:surfL.vertsN);

viewpt=cvnlookupviewpoint(subjectid,hemis,'occip','sphere');

%view_az_el_tilt={[-10 -40 180],[10 -40 180]}; %occip
%view_az_el_tilt={[-10 -70 0],[10 -70 0]}; %FFA
%view_az_el_tilt={[10 -40 0],[-10 -40 0]}; %hemis = lh,rh

valstruct=struct('data',surfdata,'numlh',surfLR.numvertsL,'numrh',surfLR.numvertsR);
valrange=epirange;
flatcmap='colormap_roybigbl';

valrange=prctile(valstruct.data,[1 99]);
flatcmap='gray';
[img,Lookup,rgbimg]=cvnlookupimages(subjectid,valstruct,hemis,viewpt,[],...
    'xyextent',[1 1],'surfsuffix',surfsuffix,...
    'roiname','*_kj2','roicolor','w','colormap',flatcmap,'clim',valrange,...
    'background','curv','alpha',[],'absthreshold',[2],...
    'text',upper(hemis));


%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% create 3d surface view
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fig_surf=figure('units','normalized','position',[0 0 .5 .45]);

surfdisplay_hemi='lh';

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

if(~isempty(valrange))
    set(gca,'clim',valrange);
end

if(iscell(viewpt))
    view(viewpt{h}(1:2));
else
    view(viewpt(1:2));
end


camlight headlight;
RotationHeadlight(fig_surf,false);

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

fig_epi=orthogui(funcvol,'colormap',colormap_roybigbl(256),'clim',epirange,...
    'background',background_vols,'backgroundidx',bgidx_epi,...
    'dim',[-2 -3 -1],'link',1,'cursorgap',1,'maxalpha',1,'alpha',alphavol,'surfslices',surfslices,...
    'callback',@(xyz)(cvnnavigator_callback('orthogui',xyz)));
% 
% fig_anat=orthogui(meanvol,'colormap','gray','clim',[0 inf],...
%     'background',background_vols,'backgroundidx',bgidx_t2,...
%     'dim',[-2 -3 -1],'link',1,'cursorgap',1,'surfslices',surfslices,...
%     'callback',@(xyz)(cvnnavigator_callback('orthogui',xyz)));
%fig_anat(2)=orthogui(anatmatch1,'colormap','gray','clim',[0 inf],'dim',[-2 -3 -1],'link',1,'cursorgap',10);

orthogui('help'); %print keyboard commands

set(fig_epi,'units','normalized','position',[.5 0 .5 .5]);
%set(fig_anat,'units','normalized','position',[.5 .5 .5 .5]);

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

set(fig_flat,'keypressfcn',@cvnnavigator_callback);
set(fig_surf,'keypressfcn',@cvnnavigator_callback);
set(gca,'buttondownfcn',@cvnnavigator_callback);
set(hsurf,'buttondownfcn',{@patchclick_callback,@cvnnavigator_callback});

set([pflat himg psurf],'hittest','off');
setappdata(fig_flat,'appdata',fillstruct(fig_epi,fig_flat,fig_surf,hsurf,psurf,pflat,...
    Lookup,surfLR,epiverts,surfdisplay_hemi,numlh,numrh));

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
