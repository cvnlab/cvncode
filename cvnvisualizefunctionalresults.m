function cvnvisualizefunctionalresults(subjectid,numlayers,layerprefix,fstruncate,ppdir,outputdir)

% function cvnvisualizefunctionalresults(subjectid,numlayers,layerprefix,fstruncate,ppdir,outputdir)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate> is like 'pt'
% <ppdir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocessSURF'
% <outputdir> is like '/home/stone/generic/Dropbox/cvnlab/ppresults/C0041/funcviz/session/'
%
% For a number of different views, write out figures showing a variety of quantities related
% to the functional dataset in <ppdir>. These figures pertain to raw and bias-corrected
% signal intensities, the 'valid' vertices, the 'dark' (<.5) vertices, mad, and tSNR.

%%%%%%%%% setup

% constants
polydeg = 4;   % we just use this poly deg when inspecting the bias-correction results

% make output directory
mkdirquiet(outputdir);

% define
hemis = {'lh' 'rh'};
hemitexts = {'L' 'R'};

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
[numlh,numrh] = cvnreadsurface(subjectid,hemis,'sphere',sprintf('DENSETRUNC%s',fstruncate),'justcount',true);

% init some stuff
VIEW = struct('data',zeros(numlh+numrh,1),'numlh',numlh,'numrh',numrh);

%%%%%%%%% load data

% load in valid mask
V = load(sprintf('%s/valid.mat',ppdir));

% load in homogenized
H = load(sprintf('%s/meanbiascorrected%02d.mat',ppdir,polydeg));

% load in poly
P = load(sprintf('%s/polyfit%02d.mat',ppdir,polydeg));

% load in mean intensities
M = load(sprintf('%s/mean.mat',ppdir));

% load in mad and tSNR
madfile  = sprintf('%s/mad.mat',ppdir);
tsnrfile = sprintf('%s/tsnr.mat',ppdir);
if exist(madfile,'file') && exist(tsnrfile,'file')  % some sessions don't have this...  so we omit that figure in these cases...
  D = load(madfile);
  T = load(tsnrfile);
end

%%%%%%%%% proceed

% define
allviews = { ...
  {'ventral'        'sphere'     0 1000    0} ...
  {'occip'          'sphere'     0 1000    0} ...
  {'occip'          'inflated'   0  500    0} ...
  {'ventral'        'inflated'   1  500    0} ...
  {'parietal'       'inflated'   0  500    0} ...
  {'medial'         'inflated'   0  500    0} ...
  {'lateral'        'inflated'   0  500    0} ...
  {'medial-ventral' 'inflated'   0  500    0} ...
  {'occip'          'sphere'     0 1000    1} ...
  {'ventral'        'inflated'   1  500    1} ...
};

% loop over views
for zz=1:length(allviews)
  viewname0 = allviews{zz}{1};
  surftype0 = allviews{zz}{2};
  hemiflip0 = allviews{zz}{3};
  imageres0 = allviews{zz}{4};
  fsaverage0 = allviews{zz}{5};

  % calc
  outputviewdir = sprintf('%s/%s%s-%s',outputdir,choose(fsaverage0,'fsaverage-',''),surftype0,viewname0);
  if hemiflip0
    hemistouse = fliplr(hemis);
    hemitextstouse = fliplr(hemitexts);
  else
    hemistouse = hemis;
    hemitextstouse = hemitexts;
  end

  % make directories
  mkdirquiet(outputviewdir);
  
  % calc some lookup stuff
  viewpt = cvnlookupviewpoint(subjectid,hemistouse,viewname0,surftype0);
  L = [];
  [mappedvals,L,rgbimg] = cvnlookupimages(subjectid,VIEW,hemistouse,viewpt,L, ...
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverageDENSETRUNC%s',fstruncate),[]));

  % make helper functions
  writefun = @(vals,filename,cmap,rng,thresh,alpha) ...
    cvnlookupimages(subjectid,setfield(VIEW,'data',double(vals)),hemistouse,viewpt,L, ...  % NOTE: double
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverageDENSETRUNC%s',fstruncate),[]), ...
    'colormap',cmap,'clim',rng,'filename',sprintf('%s/%s',outputviewdir,filename), ...
    'threshold',thresh,'overlayalpha',alpha);  % circulartype

  % %% EXPERIMENTAL. I DON'T THINK WE WANT THESE BORDERS.
  % % ,'roimask',roimask,'roicolor',roicolor);   
  % roivals = cvnloadmgz(sprintf('%s/surf/*.Kastner2015Labels*DENSETRUNC%s.mgz',fsdir,fstruncate));
  % roimask = {};
  % roicolor = {};
  % %cmap0 = jet(6);
  % valstodo = num2cell(1:25);  %{[1 2] 3 4 5 6};
  % for zz=1:length(valstodo)
  %   roimask{zz} = ismember(roivals,valstodo{zz});
  %   roicolor{zz} = [1 1 0];  %cmap0(zz,:);
  % end

  %%%%% CALC
  
  epimx = prctile(double(M.data(:)),99);
  
  %%%%% WRITE MAPS

  % mean signal intensity for each layer
  for pp=1:numlayers
    writefun(double(vflatten(M.data(1,pp,:))), ...
      sprintf('mean_layer%d.png',pp),'gray',[0 epimx],[],[]);
  end
  
  % polynomial fit for each layer
  for pp=1:numlayers
    writefun(double(vflatten(P.data(1,pp,:))), ...
      sprintf('polyfit_layer%d.png',pp),'gray',[0 epimx],[],[]);
  end

  % bias-corrected intensity for each layer
  for pp=1:numlayers
    writefun(double(vflatten(H.data(1,pp,:))), ...
      sprintf('biascorrected_layer%d.png',pp),'gray',[0 2],[],[]);
  end

  % dark (<0.5) for each layer
  for pp=1:numlayers
    writefun(double(vflatten(H.data(1,pp,:))) < 0.5, ...
      sprintf('dark_layer%d.png',pp),'gray',[0 1],[],[]);
  end

  % valid mask for each layer
  for pp=1:numlayers
    writefun(double(vflatten(V.data(1,pp,:))), ...
      sprintf('valid_layer%d.png',pp),'gray',[0 1],[],[]);
  end

  % mad and tsnr for each layer
  if exist(madfile,'file') && exist(tsnrfile,'file')
    for pp=1:numlayers
      writefun(double(vflatten(D.data(1,pp,:))), ...
        sprintf('mad_layer%d.png',pp), 'hot',[0 epimx*(1/20)],[],[]);
      writefun(double(vflatten(T.data(1,pp,:))), ...
        sprintf('tsnr_layer%d.png',pp),'jet',[0 10],[],[]);
    end
  end
  
%   %%%%% surfacevoxels stuff  
%   
%   % load mean volume
%   meanvol = double(getfield(load_untouch_nii(sprintf('%s/mean.nii',ppdir)),'img'));
% 
%   % load alignment
%   alignfile = load(sprintf('%s/freesurferalignment/alignment.mat',stripfile(ppdir)));
% 
%   % loop over layers
%   for s=1:numlayers
% 
%     % calc
%     surfname = sprintf('layer%s%d',layerprefix,s);
% 
%     % load in the surface
%     [surfL,surfR] = cvnreadsurface(subjectid,hemis,surfname,sprintf('DENSETRUNC%s',fstruncate));
%     
%     % transform to EPI space
%     [surfLR,epiverts] = surface_verts_to_volume(surfL,surfR,alignfile.tr);
% 
% 
% 
%     % save surface image of mean volume with every Nth slice = 0 along this dimension
%     surfdata = sample_vol_to_surf(samplevol, epiverts);
%     VIEW.data=surfdata;
%     [img,lookup,rgbimg]=cvnlookupimages(subjectid,VIEW,hemis,...
%         ####view_az_el_tilt,[],'xyextent',[1 1],'surfsuffix',sprintf('DENSETRUNC%s',fstruncate),...
%         'roiname','*_kj2','roicolor','k','cmap','gray','text',upper(hemis));
%     imwrite(rgbimg,sprintf('surface_voxels_meanepi_%s_ax%d.png',surfname,ax));
% 
%     % with respect to the raw measured dimensions, 0.8-mm
% 
%     % show 1 through 84 slices (rainbow and black). good for slice planning.
% 
%     % and repeat for each individual dimension
% 
%     % show with underlay the mean, every 5 slices or so using white or something
% 
%     % unique modulations using simple jet
% 
%     % and volume view too?
% 
%     

end






% %%%%%%%%%%%%%%%%%%%%%%
% 
% function [surfLR, epiverts] = surface_verts_to_volume(surfL,surfR,tr)
% 
% % <surfLR> is a struct
% % <epiverts> is V x 3 where V refers to the concatenation of left and right hemisphere vertices.
% %   the three columns are coordinates in EPI space (e.g. 1 is the middle of the first voxel).
% 
% % construct concatenated LR surface
% surfLR=struct('vertices',[surfL.vertices; surfR.vertices],...
%               'faces',[surfL.faces; surfR.faces+size(surfL.vertices,1)]);
% 
% % adjust for FS convention
% surfLR.vertices=bsxfun(@plus,surfLR.vertices,[128 129 128]);  % NOTICE THIS!!!
% 
% % add some fields
% surfLR.numvertsL=size(surfL.vertices,1);
% surfLR.numvertsR=size(surfR.vertices,1);
% surfLR.numverts=surfLR.numvertsL+surfLR.numvertsR;
% surfLR.vertidxL=reshape(1:surfLR.numvertsL,[],1);
% surfLR.vertidxR=reshape((1:surfLR.numvertsR)+surfLR.numvertsL,[],1);
% 
% % transform from volume space to EPI space
% epiverts4d = volumetoslices([surfLR.vertices ones(surfLR.numverts,1)].',tr);
% epiverts=epiverts4d(1:3,:).';
% 
% %%%%%%%%%%%%%%%%%%%%%%
% 
% 
% 
% 
% 
% function surfdata = sample_vol_to_surf(voldata, epiverts,interptype)
% if(nargin < 3)
%     interptype='cubic';
% end
% 
% epiverts(:,4)=1;
% surfdata = reshape(ba_interp3_wrapper(voldata,epiverts.',interptype),[],1);
% surfdata(isnan(surfdata))=0;
% 
% 
% 
% 
% 
% 
% 
%     
%         %% save surface image for voxels alternating along this dimension
%     
%         samplevol=voxvol;
%     
%         surfdata = sample_vol_to_surf(samplevol, epiverts,'nearest');
%     
%     
%         VIEW.data=surfdata;
%         [img,lookup,rgbimg]=cvnlookupimages(subjectid,VIEW,hemis,...
%             ####view_az_el_tilt,[],'xyextent',[1 1],'surfsuffix',sprintf('DENSETRUNC%s',fstruncate),...
%             'roiname','*_kj2','roicolor','k','cmap','jet','clim',[-.5 2],'text',upper(hemis));
%     
%         imwrite(rgbimg,sprintf('surface_voxels_nearest_%s_ax%d.png',surfname,ax));
%     
%     end
% 
% 
%     % save surface image for voxels alternating along all dimensions
%     
%     
%     vox1=zeros(size(samplevol));
%     vox2=zeros(size(samplevol));
%     vox3=zeros(size(samplevol));
% 
%     vox1(2:2:end,:,:) = 1;
%     vox2(:,2:2:end,:) = 1;
%     vox3(:,:,2:2:end) = 1;
%     samplevol=vox1 + 2*vox2 + 4*vox3;
% 
%     surfdata = sample_vol_to_surf(samplevol, epiverts,'nearest');
% 
%     VIEW.data=surfdata;
%     [img,lookup,rgbimg]=cvnlookupimages(subjectid,VIEW,hemis,...
%         #####view_az_el_tilt,[],'xyextent',[1 1],'surfsuffix',sprintf('DENSETRUNC%s',fstruncate),...
%         'roiname','*_kj2','roicolor','k','cmap','jet','clim',[-.5 7.5],'text',upper(hemis));
% 
%     imwrite(rgbimg,sprintf('surface_voxels_nearest_%s.png',surfname));
%   end
% 
% 
% 
%     valstruct=struct('data',[],'numlh',surfLR.numvertsL,'numrh',surfLR.numvertsR);
% 
% 
% 
% 
% 
% 
% 
%     for ax = 1:3
%         samplevol=meanvol;
%         voxvol=zeros(size(samplevol));
%     
%         linespacing=4;
%     
%         if(ax==1)
%             samplevol(1:linespacing:end,:,:)=0;
%             voxvol(1:2:end,:,:)=1;
%         elseif(ax==2)
%             samplevol(:,1:linespacing:end,:)=0;
%             voxvol(:,1:2:end,:)=1;
%         elseif(ax==3)
%             samplevol(:,:,1:linespacing:end)=0;
%             voxvol(:,:,1:2:end)=1;
%         end
%     
%         % save mean volume stack with every Nth slice = 0 along this dimension
%         volimg=makeimagestack(samplevol,prctile(samplevol(:),[0 99]));
%         imwrite(volimg,sprintf('surface_voxels_meanepi_vol_ax%d.png',ax));
%     
%     