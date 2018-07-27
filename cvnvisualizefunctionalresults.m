function cvnvisualizefunctionalresults(subjectid,numlayers,layerprefix,fstruncate,ppdir,ppdirvol,outputdir)

% function cvnvisualizefunctionalresults(subjectid,numlayers,layerprefix,fstruncate,ppdir,ppdirvol,outputdir)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate> is like 'pt'
% <ppdir> is like     '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocessVER1SURFC1051'
% <ppdirvol> is like  '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocessVER1'
%   this is for the low-res-related stuff; if that doesn't exist, this input can be [].
%   if input is provided and the folder doesn't actually exist, we just silently skip.
% <outputdir> is like '/home/stone/generic/Dropbox/cvnlab/ppresults/C0041/funcviz/session/'
%
% For a number of different views, write out figures showing a variety of quantities related
% to the functional dataset in <ppdir>. These figures pertain to raw and bias-corrected
% signal intensities, the 'valid' vertices, the 'dark' (<.5) vertices, mad, tSNR,
% and volume slicing.
%
% If <ppdirvol> is provided, also write out figures pertaining to low-res versions
% of bias-corrected signal intensities and the 'dark' (<.5) vertices.
%
% history:
% - 2018/01/16 - whittle down the list of viewpoints to generate
% - 2017/12/17 - set hemibordercolor to 'w'
% - 2017/11/28 - silent skip for <ppdirvol> not existing
% - 2017/08/25 - change dark to 0.75 threshold and make them look black on white
% - 2017/08/25 - change to white background, black text, black scale bar
% - 2017/08/14 - add support for flat.patch
% - 2016/12/29 - add support for low-res-related stuff
% - 2016/11/30 - add support for STRIPE1-3

% TODO: should we use fsaverage flat? (can we even do that, given that it's not dense processed??)

%%%%%%%%% setup

% constants
polydeg = 4;   % we just use this poly deg when inspecting the bias-corrected results

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

% load in low-res-related stuff
if ~isempty(ppdirvol) && exist(ppdirvol,'dir')
  files0 = matchfiles(sprintf('%s/mean_*_biascorrected.mat',ppdirvol));
  prefixes = cellfun(@(x) subscript(regexp(x,'.*?mean_(\S+)_biascorrected.mat','tokens'),1,1),files0);
  clear S;
  for p=1:length(files0)
    S(p) = load(files0{p});
  end
end

%%%%%%%%% proceed

% define
  % OLD:   [on Jan 16, 2018, I whittled down the viewpoint list]
  % allviews = { ...
  %   {'ventral'        'sphere'                   0 1000    0         [1 1]} ...
  %   {'occip'          'sphere'                   0 1000    0         [1 1]} ...
  %   {'occip'          'inflated'                 0  500    0         [1 1]} ...
  %   {'ventral'        'inflated'                 1  500    0         [1 1]} ...
  %   {'parietal'       'inflated'                 0  500    0         [1 1]} ...
  %   {'medial'         'inflated'                 0  500    0         [1 1]} ...
  %   {'lateral'        'inflated'                 0  500    0         [1 1]} ...
  %   {'medial-ventral' 'inflated'                 0  500    0         [1 1]} ...
  %   {'occip'          'sphere'                   0 1000    1         [1 1]} ...
  %   {'ventral'        'inflated'                 1  500    1         [1 1]} ...
  %   {'ventral'        'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
  %   {''               'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
  % };
allviews = { ...
  {'occip'          'sphere'                   0 1000    0         [1 1]} ...
  {'ventral'        'inflated'                 1  500    0         [1 1]} ...
  {'occip'          'sphere'                   0 1000    1         [1 1]} ...
  {'ventral'        'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
  {''               'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
};

% loop over views
for zz=1:length(allviews)
  viewname0 = allviews{zz}{1};
  surftype0 = allviews{zz}{2};
  hemiflip0 = allviews{zz}{3};
  imageres0 = allviews{zz}{4};
  fsaverage0 = allviews{zz}{5};
  xyextent0 = allviews{zz}{6};

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
    'xyextent',xyextent0,'rgbnan',1,'hemibordercolor','w','text',hemitextstouse, ...
    'textcolor','k','scalebarcolor','k','surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverageDENSETRUNC%s',fstruncate),[]));

  % make helper functions
  writefun = @(vals,filename,cmap,rng,thresh,alpha) ...
    cvnlookupimages(subjectid,setfield(VIEW,'data',double(vals)),hemistouse,viewpt,L, ...  % NOTE: double
    'xyextent',xyextent0,'rgbnan',1,'hemibordercolor','w','text',hemitextstouse, ...
    'textcolor','k','scalebarcolor','k','surftype',surftype0,'imageres',imageres0, ...
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

  % dark (>0.75) for each layer   [so, veins look black on a white background]
  for pp=1:numlayers
    writefun(~(double(vflatten(H.data(1,pp,:))) < 0.75), ...
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
  
  % lowres-related stuff
  if ~isempty(ppdirvol) && exist(ppdirvol,'dir')
  
    % for each smoothed version
    for zz=1:length(prefixes)
      for pp=1:numlayers

        % bias-corrected intensity for each layer
        writefun(double(vflatten(S(zz).data(1,pp,:))), ...
          sprintf('lowres_%s_biascorrected_layer%d.png',prefixes{zz},pp),'gray',[0 2],[],[]);
        
        % dark (>0.75) for each layer
        writefun(~(double(vflatten(S(zz).data(1,pp,:))) < 0.75), ...
          sprintf('lowres_%s_dark_layer%d.png',         prefixes{zz},pp),'gray',[0 1],[],[]);

      end
    end

  end

  %%%%% more:

  % calc
  infilenames =  [cellfun(@(x) sprintf('layer%s%d',layerprefix,x),num2cell(1:numlayers),'UniformOutput',0) {'white' 'pial'}];
  outfilenames = [cellfun(@(x) sprintf('layer%d',x),num2cell(1:numlayers),'UniformOutput',0) {sprintf('layer%d',numlayers+1) 'layer0'}];

  % process quantities for each layer
    prev = warning('query');
    warning off;
  todos = {'STRIPE1' 'STRIPE2' 'STRIPE3'};
  for q=1:length(todos)
    for p=1:length(infilenames)
      file0 = matchfiles(sprintf('%s/surf/*.%s_%s_DENSETRUNC%s.mgz',ppdir,todos{q},infilenames{p},fstruncate));
      if isempty(file0)
        continue;
      end
      temp = cvnloadmgz(file0);
      thresh0 = [];  % default
      alpha0 = [];   % default
      if isequal(todos{q}(1:6),'STRIPE')
        rng = [0.5 max(temp)+.5];  % colors will range from 1, 2, ..., max
        cmap0 = jet(max(temp));    % get a jet colormap tailored to this
        thresh0 = 0.9;             % we allow the 0 values to show the curvature underneath
      end
      writefun(temp,sprintf('%s_%s.png',todos{q},outfilenames{p}),cmap0,rng,thresh0,alpha0);
    end
  end
    warning(prev);
  
end
