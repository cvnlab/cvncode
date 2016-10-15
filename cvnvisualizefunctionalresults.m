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
  {'ventral'        'sphere'     0 1000} ...
  {'occip'          'sphere'     0 1000} ...
  {'occip'          'inflated'   0  500} ...
  {'ventral'        'inflated'   1  500} ...
  {'parietal'       'inflated'   0  500} ...
  {'medial'         'inflated'   0  500} ...
  {'lateral'        'inflated'   0  500} ...
  {'medial-ventral' 'inflated'   0  500} ...
};

% loop over views
for zz=1:length(allviews)
  viewname0 = allviews{zz}{1};
  surftype0 = allviews{zz}{2};
  hemiflip0 = allviews{zz}{3};
  imageres0 = allviews{zz}{4};

  % calc
  outputviewdir = sprintf('%s/%s-%s',outputdir,surftype0,viewname0);
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
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0);

  % make helper functions
  writefun = @(vals,filename,cmap,rng,thresh,alpha) ...
    cvnlookupimages(subjectid,setfield(VIEW,'data',vals),hemistouse,viewpt,L, ...
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
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

end
