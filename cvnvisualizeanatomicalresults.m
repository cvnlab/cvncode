function cvnvisualizeanatomicalresults(subjectid,numlayers,layerprefix,fstruncate,figdir)

% function cvnvisualizeanatomicalresults(subjectid,numlayers,layerprefix,fstruncate,figdir)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate> is like 'pt'
% <figdir> is directory to write figures to.
%
% For a number of different views, write out figures showing a variety of different
% anatomical and atlas-related quantities.

%%%%% PREP

% define
hemis = {'lh' 'rh'};
hemitexts = {'L' 'R'};

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
[numlh,numrh] = cvnreadsurface(subjectid,hemis,'sphere',sprintf('DENSETRUNC%s',fstruncate),'justcount',true);

% init some stuff
V = struct('data',zeros(numlh+numrh,1),'numlh',numlh,'numrh',numrh);

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
  outputdir = sprintf('%s/%s-%s',figdir,surftype0,viewname0);
  if hemiflip0
    hemistouse = fliplr(hemis);
    hemitextstouse = fliplr(hemitexts);
  else
    hemistouse = hemis;
    hemitextstouse = hemitexts;
  end

  % make directories
  mkdirquiet(figdir);
  mkdirquiet(outputdir);
  
  % calc some lookup stuff
  viewpt = cvnlookupviewpoint(subjectid,hemistouse,viewname0,surftype0);
  L = [];
  [mappedvals,L,rgbimg] = cvnlookupimages(subjectid,V,hemistouse,viewpt,L, ...
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0);

  % make helper functions
  writefun = @(vals,filename,cmap,rng,thresh,alpha) ...
    cvnlookupimages(subjectid,setfield(V,'data',vals),hemistouse,viewpt,L, ...
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
    'colormap',cmap,'clim',rng,'filename',sprintf('%s/%s',outputdir,filename), ...
    'threshold',thresh,'overlayalpha',alpha);     % circulartype

  %%%%% WRITE MAPS

  % SAPV for each layer
  for p=1:numlayers
    writefun(cvnloadmgz(sprintf('%s/surf/*.sapv_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate)), ...
      sprintf('sapv_layer%d.png',p),'jet',[0 .25],[],[]);
  end

  % SAPV for the sphere
  writefun(cvnloadmgz(sprintf('%s/surf/*.sapv_sphere_DENSETRUNC%s.mgz',fsdir,fstruncate)), ...
    sprintf('sapv_sphere.png'),     'jet',[0 .25],[],[]);

  % distortion map for each layer
  %   log2(sapv_sphere/sapv_layer)
  %   0 means no distortion. + means sphere is enlarged. - means sphere is shrunken.
  for p=1:numlayers
    writefun( ...
      log2(cvnloadmgz(sprintf('%s/surf/*.sapv_sphere_DENSETRUNC%s.mgz',fsdir,fstruncate)) ./ ...
           cvnloadmgz(sprintf('%s/surf/*.sapv_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate))), ...
      sprintf('distortion_layer%d.png',p),'cmapsign4',[-2 2],[],[]);
  end

  % AEL for each layer (probably very very similar to SAPV)
  for p=1:numlayers
    writefun(cvnloadmgz(sprintf('%s/surf/*.ael_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate)), ...
      sprintf('ael_layer%d.png',p),'jet',[0 1],[],[]);
  end

  % curvature
  %   + (red) means sulci
  %   - (blue) means gyri
  writefun(cvnloadmgz(sprintf('%s/surf/*.curvatureDENSETRUNC%s.mgz',fsdir,fstruncate)), ...
    sprintf('curvatureraw.png'),'cmapsign4',[-1 1],[],[]);

  % curvature thresholded
  %   dark gray is 0  (curvature value is > 0)
  %   light gray is 1 (curvature value is < 0)
  writefun(cvnloadmgz(sprintf('%s/surf/*.curvatureDENSETRUNC%s.mgz',fsdir,fstruncate)) < 0, ...
    sprintf('curvature.png'),   'gray',     [-1 2],[],[]);

  % thickness
  %   red means thick
  %   blue means thin
  writefun(cvnloadmgz(sprintf('%s/surf/*.thicknessDENSETRUNC%s.mgz',fsdir,fstruncate)), ...
    sprintf('thickness.png'),   'jet',      [0 4],[],[]);

  % sulc
  %   + (red) means sulci (far from brain boundary)
  %   - (blue) means gyri (close to brain boundary)
  writefun(cvnloadmgz(sprintf('%s/surf/*.sulcDENSETRUNC%s.mgz',fsdir,fstruncate)), ...
    sprintf('sulcraw.png'),     'cmapsign4',[-1.5 1.5],[],[]);

  % sulc thresholded
  %   dark gray is 0  (sulc value is > 0)
  %   light gray is 1 (sulc value is < 0)
  writefun(cvnloadmgz(sprintf('%s/surf/*.sulcDENSETRUNC%s.mgz',fsdir,fstruncate)) < 0, ...
    sprintf('sulc.png'),        'gray',     [-1 2],[],[]);

  % Kastner atlas stuff (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/*DENSETRUNC%s*Kastner2015Labels*.mgz',fsdir,fstruncate)), ...
    sprintf('kastner.png'),     'jet',      [0 25],     0.5,0.85);

  % Kastner atlas stuff (with names)
  [~,roinames,~]=cvnroimask(subjectid,hemis,'Kastner*',[],sprintf('DENSETRUNC%s',fstruncate),'cell');
  roinames=regexprep(roinames{1},'@.+','');
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(roinames),cleantext(roinames));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'kastner_names.png'));
 
  % FreeSurfer aparc (without names) [see one-offs/freesurfer aparc colormap]
  fsconstants;
  vals = [];
  for p=1:length(hemis)  % NOTE: must be hemis (same LH first convention)
    roimask = cvnroimask(subjectid,hemis{p},'aparc',[],sprintf('DENSETRUNC%s',fstruncate),'vals');  % column vector
    bad = find(roimask==0);
    roimask(bad) = 6500;  % just a random valid entry
    roimask = calcposition(fscolortable(:,end)',roimask');
    roimask(bad) = 0;     % 0 is preserved. other entries are indices relative to fscolortable.
    vals = [vals; roimask(:)];
  end
  [roiimg,~,rgbimg]=writefun(vals, ...
    sprintf('aparc.png'),     jet(36),      [0.5 36.5], 0.5,0.85);

  % FreeSurfer aparc (with names)
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(fslabels),cleantext(fslabels));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'aparc_names.png'));

  %%%%% T1/T2/FMAP/SINUSBW stuff:

  % calc
  infilenames =  [cellfun(@(x) sprintf('layer%s%d',layerprefix,x),num2cell(1:numlayers),'UniformOutput',0) {'white' 'pial'}];
  outfilenames = [cellfun(@(x) sprintf('layer%d',x),num2cell(1:numlayers),'UniformOutput',0) {sprintf('layer%d',numlayers+1) 'layer0'}];

  % process quantities for each layer
  todos = {'T1' 'T2' 'FMAP' 'SINUSBW'};
  for q=1:length(todos)
    for p=1:length(infilenames)
      file0 = matchfiles(sprintf('%s/surf/*.%s_%s_DENSETRUNC%s.mgz',fsdir,todos{q},infilenames{p},fstruncate));
      if isempty(file0)
        continue;
      end
      temp = cvnloadmgz(file0);
      if ismember(todos{q},{'T1' 'T2' 'FMAP'}) && p==1
        rng = [0 mean(temp)*3];  % WEIRD HEURISTIC!
        cmap0 = 'gray';
      elseif isequal(todos{q},'SINUSBW')
        rng = [0 10];
        cmap0 = 'hot';
      end
      writefun(temp,sprintf('%s_%s.png',todos{q},outfilenames{p}),cmap0,rng,[],[]);
    end
  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% maybe for future:
  %% aparc 2009?
  %% fsaverage sphere?
  %% fsaverage inflated?
  %% HCP
