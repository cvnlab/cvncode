function cvnvisualizeanatomicalresults(subjectid,numlayers,layerprefix,fstruncate,figdir)

% function cvnvisualizeanatomicalresults(subjectid,numlayers,layerprefix,fstruncate,figdir)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6          or [] when non-dense processing
% <layerprefix> is like 'A'      or [] when non-dense processing
% <fstruncate> is like 'pt'      or [] when non-dense processing
% <figdir> is directory to write figures to.
%
% For a number of different views, write out figures showing a variety of different
% anatomical and atlas-related quantities.
%
% history:
% - 2017/08/04 - update for visualsulc new range (0 through 14)
% - 2017/07/16 - add support for non-dense processing
% - 2016/12/29 - add support for visualsulc
% - 2016/11/30 - add support for aparc2009
% - 2016/11/29 - add support for SURFVOX
% - 2016/11/28 - add support for new volumes: DIM1-3, BVOL, MAXEDIT
% - 2016/11/22 - omit a few of these for the fsaverage case

%%%%% PREP

% define
hemis = {'lh' 'rh'};
hemitexts = {'L' 'R'};

% calc
if isempty(numlayers)
  surfsuffix = 'orig';
  surfsuffix2 = '';
else
  surfsuffix = sprintf('DENSETRUNC%s',fstruncate);
  surfsuffix2 = sprintf('DENSETRUNC%s',fstruncate);
end
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
[numlh,numrh] = cvnreadsurface(subjectid,hemis,'sphere',surfsuffix,'justcount',true);

% init some stuff
V = struct('data',zeros(numlh+numrh,1),'numlh',numlh,'numrh',numrh);

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
  
  % get out early
  if isequal(subjectid,'fsaverage') && fsaverage0
    % NOTE: this is a bit awkward. there was a crash (a transfer file missing) when trying to do this case.
    %       conceptually, it is a bit redundant and crazy (to transfer fsaverage to fsaverage).
    %       so, we just do a hack and omit this for-loop case!!
    continue;
  end

  % calc
  outputdir = sprintf('%s/%s%s-%s',figdir,choose(fsaverage0,'fsaverage-',''),surftype0,viewname0);
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
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverage%s',surfsuffix2),surfsuffix));

  % make helper functions
  writefun = @(vals,filename,cmap,rng,thresh,alpha) ...
    cvnlookupimages(subjectid,setfield(V,'data',double(vals)),hemistouse,viewpt,L, ...  % NOTE: double
    'xyextent',[1 1],'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverage%s',surfsuffix2),surfsuffix), ...
    'colormap',cmap,'clim',rng,'filename',sprintf('%s/%s',outputdir,filename), ...
    'threshold',thresh,'overlayalpha',alpha);     % circulartype

  %%%%% WRITE MAPS

  if ~isempty(numlayers)

    % SAPV for each layer
    if ~isequal(subjectid,'fsaverage')
      for p=1:numlayers
        writefun(cvnloadmgz(sprintf('%s/surf/*.sapv_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate)), ...
          sprintf('sapv_layer%d.png',p),'jet',[0 .25],[],[]);
      end
    end

    % SAPV for the sphere
    writefun(cvnloadmgz(sprintf('%s/surf/*.sapv_sphere_DENSETRUNC%s.mgz',fsdir,fstruncate)), ...
      sprintf('sapv_sphere.png'),     'jet',[0 .25],[],[]);

    % distortion map for each layer
    %   log2(sapv_sphere/sapv_layer)
    %   0 means no distortion. + means sphere is enlarged. - means sphere is shrunken.
    if ~isequal(subjectid,'fsaverage')
      for p=1:numlayers
        writefun( ...
          log2(cvnloadmgz(sprintf('%s/surf/*.sapv_sphere_DENSETRUNC%s.mgz',fsdir,fstruncate)) ./ ...
               cvnloadmgz(sprintf('%s/surf/*.sapv_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate))), ...
          sprintf('distortion_layer%d.png',p),'cmapsign4',[-2 2],[],[]);
      end
    end

    % AEL for each layer (probably very very similar to SAPV)
    if ~isequal(subjectid,'fsaverage')
      for p=1:numlayers
        writefun(cvnloadmgz(sprintf('%s/surf/*.ael_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate)), ...
          sprintf('ael_layer%d.png',p),'jet',[0 1],[],[]);
      end
    end

  end

  % curvature
  %   + (red) means sulci
  %   - (blue) means gyri
  writefun(cvnloadmgz(sprintf('%s/surf/*.curvature%s.mgz',fsdir,surfsuffix2)), ...
    sprintf('curvatureraw.png'),'cmapsign4',[-1 1],[],[]);

  % curvature thresholded
  %   dark gray is 0  (curvature value is > 0)
  %   light gray is 1 (curvature value is < 0)
  writefun(cvnloadmgz(sprintf('%s/surf/*.curvature%s.mgz',fsdir,surfsuffix2)) < 0, ...
    sprintf('curvature.png'),   'gray',     [-1 2],[],[]);

  % thickness
  %   red means thick
  %   blue means thin
  writefun(cvnloadmgz(sprintf('%s/surf/*.thickness%s.mgz',fsdir,surfsuffix2)), ...
    sprintf('thickness.png'),   'jet',      [0 4],[],[]);

  % sulc
  %   + (red) means sulci (far from brain boundary)
  %   - (blue) means gyri (close to brain boundary)
  writefun(cvnloadmgz(sprintf('%s/surf/*.sulc%s.mgz',fsdir,surfsuffix2)), ...
    sprintf('sulcraw.png'),     'cmapsign4',[-1.5 1.5],[],[]);

  % sulc thresholded
  %   dark gray is 0  (sulc value is > 0)
  %   light gray is 1 (sulc value is < 0)
  writefun(cvnloadmgz(sprintf('%s/surf/*.sulc%s.mgz',fsdir,surfsuffix2)) < 0, ...
    sprintf('sulc.png'),        'gray',     [-1 2],[],[]);

  % Kastner atlas stuff (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.Kastner2015Labels.mgz',fsdir,surfsuffix2)), ...
    sprintf('kastner.png'),     'jet',      [0 25],     0.5,0.85);

  % Kastner atlas stuff (with names)
  [~,roinames,~]=cvnroimask(subjectid,hemis,'Kastner*',[],surfsuffix,'cell');
  roinames=regexprep(roinames{1},'@.+','');
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(roinames),cleantext(roinames));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'kastner_names.png'));

  % visualsulc atlas stuff (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.visualsulc.mgz',fsdir,surfsuffix2)), ...
    sprintf('visualsulc.png'),  'jet',      [0 14],      0.5,0.85);

  % visualsulc atlas stuff (with names)
  [~,roinames,~]=cvnroimask(subjectid,hemis,'visualsulc*',[],surfsuffix,'cell');
  roinames=regexprep(roinames{1},'@.+','');
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(roinames),cleantext(roinames));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'visualsulc_names.png'));
 
  %%%%% aparc stuff:
  
  % setup
  fsconstants;

  % FreeSurfer aparc (without names) [see one-offs/freesurfer aparc colormap]
  vals = [];
  for p=1:length(hemis)  % NOTE: must be hemis (same LH first convention)
    roimask = cvnroimask(subjectid,hemis{p},'aparc',[],surfsuffix,'vals');  % column vector
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

  % FreeSurfer aparc.a2009s (without names) [see one-offs/freesurfer aparc colormap]
  vals = [];
  for p=1:length(hemis)  % NOTE: must be hemis (same LH first convention)
    roimask = cvnroimask(subjectid,hemis{p},'aparc.a2009s',[],surfsuffix,'vals');  % column vector
    bad = find(roimask==0);
    roimask(bad) = 15386;  % just a random valid entry
      % super ugly hack so that we can use calcposition (the 0s were causing problems)
      temp = fscolortable2009(:,end)';
      assert(temp(1)==0);
      temp(1) = 1;
      temp2 = roimask';
      assert(all(temp2~=1));
      temp2(temp2==0) = 1;
    roimask = calcposition(temp,temp2);
    roimask(bad) = 0;     % 0 is preserved. other entries are indices relative to fscolortable2009.
    vals = [vals; roimask(:)];
  end
  [roiimg,~,rgbimg]=writefun(vals, ...
    sprintf('aparc2009.png'), jet(76),      [0.5 76.5], 0.5,0.75);

  % FreeSurfer aparc.a2009s (with names)
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(fslabels2009),cleantext(fslabels2009));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'aparc2009_names.png'));

  %%%%% anatomical data stuff:
  
  if ~isempty(numlayers)

    % calc
    infilenames =  [cellfun(@(x) sprintf('layer%s%d',layerprefix,x),num2cell(1:numlayers),'UniformOutput',0) {'white' 'pial'}];
    outfilenames = [cellfun(@(x) sprintf('layer%d',x),num2cell(1:numlayers),'UniformOutput',0) {sprintf('layer%d',numlayers+1) 'layer0'}];

    % special SURFVOX stuff
    mms = [0.5 0.8 1 1.5 2 2.5 3];
    volnames = arrayfun(@(x) sprintf('SURFVOX%.1f',x),mms,'UniformOutput',0);

    % process quantities for each layer
      prev = warning('query');
      warning off;
    todos = [{'T1' 'T2' 'FMAP' 'DIM1' 'DIM2' 'DIM3' 'BVOL' 'MAXEDIT' 'SINUSBW'} volnames];
    for q=1:length(todos)
      for p=1:length(infilenames)
        file0 = matchfiles(sprintf('%s/surf/*.%s_%s_DENSETRUNC%s.mgz',fsdir,todos{q},infilenames{p},fstruncate));
        if isempty(file0)
          continue;
        end
        temp = cvnloadmgz(file0);
        thresh0 = [];  % default
        alpha0 = [];   % default
        if ismember(todos{q},{'T1' 'T2' 'FMAP'})
          if p==1
            rng = [0 mean(temp)*3];  % WEIRD HEURISTIC!
          end
          cmap0 = 'gray';
        elseif ismember(todos{q},{'DIM1' 'DIM2' 'DIM3'})
          rng = [1 320];
          cmap0 = 'jet';
        elseif isequal(todos{q},'BVOL')
          rng = [0 3];  % values are 0, 1, 2, 3
          cmap0 = 'jet';
          thresh0 = 1.5;
          alpha0 = 0.6;
        elseif isequal(todos{q},'MAXEDIT')
          rng = [0 1];
          cmap0 = 'gray';
          thresh0 = 0.5;
          alpha0 = 0.6;
        elseif isequal(todos{q},'SINUSBW')
          rng = [0 10];
          cmap0 = 'hot';
        elseif isequal(todos{q}(1:7),'SURFVOX')
          rng = [0 7];
          cmap0 = 'jet';
        end
        writefun(temp,sprintf('%s_%s.png',todos{q},outfilenames{p}),cmap0,rng,thresh0,alpha0);
      end
    end
      warning(prev);

  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% maybe for future:
  %% HCP
