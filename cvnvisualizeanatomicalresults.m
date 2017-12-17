function cvnvisualizeanatomicalresults(subjectid,numlayers,layerprefix,fstruncate,figdir,altmode)

% function cvnvisualizeanatomicalresults(subjectid,numlayers,layerprefix,fstruncate,figdir,altmode)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6          or [] when non-dense processing
% <layerprefix> is like 'A'      or [] when non-dense processing
% <fstruncate> is like 'pt'      or [] when non-dense processing
% <figdir> is directory to write figures to.
% <altmode> (optional) is
%   0 means do nothing special
%   1 means generate alternative sphere viewpoints
%
% For a number of different views, write out figures showing a variety of different
% anatomical and atlas-related quantities.
%
% history:
% - 2017/12/17 - set hemibordercolor to 'w' and add non-dense T1divT2 support
% - 2017/12/03 - add support for KGSROI
% - 2017/12/02 - add support for <altmode>
% - 2017/11/28 - add support for SWI
% - 2017/08/25 - add support for HCP_MMP1
% - 2017/08/25 - add new images (rand, curvature no shading, curvature bordered, flocgeneral);
%                change to black text, black scale bar
% - 2017/08/24 - add support for gVTC, gEVC
% - 2017/08/14 - add support for flat.patch (for flat.patch, we skip T1 T2 FMAP);
%                drop DIM, sapv; reduce SURFVOX to just 0.8 and 2
% - 2017/08/04 - update for visualsulc new range (0 through 14)
% - 2017/07/16 - add support for non-dense processing
% - 2016/12/29 - add support for visualsulc
% - 2016/11/30 - add support for aparc2009
% - 2016/11/29 - add support for SURFVOX
% - 2016/11/28 - add support for new volumes: DIM1-3, BVOL, MAXEDIT
% - 2016/11/22 - omit a few of these for the fsaverage case

%%%%% PREP

% input
if ~exist('altmode','var') || isempty(altmode)
  altmode = 0;
end

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
switch altmode
case 0
  allviews = { ...
    {'ventral'        'sphere'                   0 1000    0         [1 1]} ...
    {'occip'          'sphere'                   0 1000    0         [1 1]} ...
    {'occip'          'inflated'                 0  500    0         [1 1]} ...
    {'ventral'        'inflated'                 1  500    0         [1 1]} ...
    {'parietal'       'inflated'                 0  500    0         [1 1]} ...
    {'medial'         'inflated'                 0  500    0         [1 1]} ...
    {'lateral'        'inflated'                 0  500    0         [1 1]} ...
    {'medial-ventral' 'inflated'                 0  500    0         [1 1]} ...
    {'occip'          'sphere'                   0 1000    1         [1 1]} ...
    {'ventral'        'inflated'                 1  500    1         [1 1]} ...
    {'ventral'        'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
    {''               'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
  };
case 1

  % like: occipA1
  todo = {'A' 'B' 'C'};
  allviews = {};
  for xx=1:length(todo)
    for yy=1:8
      allviews{end+1} = {sprintf('occip%s%d',todo{xx},yy)         'sphere'                   0 1000    0         [1 1]};
    end
  end

% EXPERIMENTAL:
%     {'occipC2'        'sphere'                   0 1000    0         [1 1]} ...
%     {'occipC2'        'sphere'                   0 1000    1         [1 1]} ...

end

% loop over views
for zz=1:length(allviews)
  viewname0 = allviews{zz}{1};
  surftype0 = allviews{zz}{2};
  hemiflip0 = allviews{zz}{3};
  imageres0 = allviews{zz}{4};
  fsaverage0 = allviews{zz}{5};
  xyextent0 = allviews{zz}{6};
  
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
    'xyextent',xyextent0,'rgbnan',1,'hemibordercolor','w','text',hemitextstouse, ...
    'textcolor','k','scalebarcolor','k','surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverage%s',surfsuffix2),surfsuffix));

  % make helper functions
  writefun = @(vals,filename,cmap,rng,thresh,alpha,others) ...
    cvnlookupimages(subjectid,setfield(V,'data',double(vals)),hemistouse,viewpt,L, ...  % NOTE: double
    'xyextent',xyextent0,'rgbnan',1,'hemibordercolor','w','text',hemitextstouse, ...
    'textcolor','k','scalebarcolor','k','surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverage%s',surfsuffix2),surfsuffix), ...
    'colormap',cmap,'clim',rng,'filename',sprintf('%s/%s',outputdir,filename), ...
    'threshold',thresh,'overlayalpha',alpha,others{:});     % circulartype

  %%%%% WRITE MAPS

  if ~isempty(numlayers)

% Aug 14 2017 - just drop these.
%     % SAPV for each layer
%     if ~isequal(subjectid,'fsaverage')
%       for p=1:numlayers
%         writefun(cvnloadmgz(sprintf('%s/surf/*.sapv_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate)), ...
%           sprintf('sapv_layer%d.png',p),'jet',[0 .25],[],[]);
%       end
%     end
% 
%     % SAPV for the sphere
%     writefun(cvnloadmgz(sprintf('%s/surf/*.sapv_sphere_DENSETRUNC%s.mgz',fsdir,fstruncate)), ...
%       sprintf('sapv_sphere.png'),     'jet',[0 .25],[],[]);

    % distortion map for each layer
    %   log2(sapv_sphere/sapv_layer)
    %   0 means no distortion. + means sphere is enlarged. - means sphere is shrunken.
    if ~isequal(subjectid,'fsaverage')
      for p=1:numlayers
        writefun( ...
          log2(cvnloadmgz(sprintf('%s/surf/*.sapv_sphere_DENSETRUNC%s.mgz',fsdir,fstruncate)) ./ ...
               cvnloadmgz(sprintf('%s/surf/*.sapv_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate))), ...
          sprintf('distortion_layer%d.png',p),'cmapsign4',[-2 2],[],[],{});
      end
    end

    % AEL for each layer (probably very very similar to SAPV)
    if ~isequal(subjectid,'fsaverage')
      for p=1:numlayers
        writefun(cvnloadmgz(sprintf('%s/surf/*.ael_layer%s%d_DENSETRUNC%s.mgz',fsdir,layerprefix,p,fstruncate)), ...
          sprintf('ael_layer%d.png',p),'jet',[0 1],[],[],{});
      end
    end

  end

  % rand values
  writefun(rand(size(V.data)), ...
    sprintf('rand.png'),'jet',[0 1],[],[],{});
  
  % load curvature
  curvval = cvnloadmgz(sprintf('%s/surf/*.curvature%s.mgz',fsdir,surfsuffix2));

  % curvature
  %   + (red) means sulci
  %   - (blue) means gyri
  writefun(curvval, ...
    sprintf('curvatureraw.png'),'cmapsign4',[-1 1],[],[],{});

  % curvature thresholded
  %   dark gray is 0  (curvature value is > 0)
  %   light gray is 1 (curvature value is < 0)
  writefun(curvval < 0, ...
    sprintf('curvature.png'),   'gray',     [-1 2],[],[],{});

  % curvature thresholded and no shading
  writefun(curvval < 0, ...
    sprintf('curvaturenoshade.png'),'gray',     [-1 2],[],[],{'surfshading' false});

  % curvature bordered (and no shading)
  writefun(ones(size(V.data)), ...
    sprintf('curvatureborder.png'),'gray',  [0 1],[],[], ...
    {'roimask',curvval < 0,'roicolor','k','roiwidth',.05,'surfshading',false});

  % thickness
  %   red means thick
  %   blue means thin
  writefun(cvnloadmgz(sprintf('%s/surf/*.thickness%s.mgz',fsdir,surfsuffix2)), ...
    sprintf('thickness.png'),   'jet',      [0 4],[],[],{});

  % sulc
  %   + (red) means sulci (far from brain boundary)
  %   - (blue) means gyri (close to brain boundary)
  writefun(cvnloadmgz(sprintf('%s/surf/*.sulc%s.mgz',fsdir,surfsuffix2)), ...
    sprintf('sulcraw.png'),     'cmapsign4',[-1.5 1.5],[],[],{});

  % sulc thresholded
  %   dark gray is 0  (sulc value is > 0)
  %   light gray is 1 (sulc value is < 0)
  writefun(cvnloadmgz(sprintf('%s/surf/*.sulc%s.mgz',fsdir,surfsuffix2)) < 0, ...
    sprintf('sulc.png'),        'gray',     [-1 2],[],[],{});

  % Kastner atlas stuff (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.Kastner2015Labels.mgz',fsdir,surfsuffix2)), ...
    sprintf('kastner.png'),     'jet',      [0 25],     0.5,0.85,{});

  % Kastner atlas stuff (with names)
  [~,roinames,~]=cvnroimask(subjectid,hemis,'Kastner*',[],'orig','cell');
  roinames=regexprep(roinames{1},'@.+','');
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(roinames),cleantext(roinames));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'kastner_names.png'));

  % visualsulc atlas stuff (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.visualsulc.mgz',fsdir,surfsuffix2)), ...
    sprintf('visualsulc.png'),  'jet',      [0 14],      0.5,0.85,{});

  % visualsulc atlas stuff (with names)
  [~,roinames,~]=cvnroimask(subjectid,hemis,'visualsulc*',[],'orig','cell');
  roinames=regexprep(roinames{1},'@.+','');
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(roinames),cleantext(roinames));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'visualsulc_names.png'));

  % HCP_MMP1 atlas stuff (without names)
  vals0 = cvnloadmgz(sprintf('%s/label/?h%s.HCP_MMP1.mgz',fsdir,surfsuffix2));
  [roiimg,~,rgbimg]=writefun(vals0, ...
    sprintf('mmp.png'),  colormap_hcp_mmp(),[-.5 180.5], 0.5,0.85,{'roimask',vals0,'roicolor','w'});

  % HCP_MMP1 atlas stuff (with names)
  [~,roinames,~]=cvnroimask(subjectid,hemis,'HCP_MMP1*',[],'orig','cell');
  roinames=regexprep(roinames{1},'@.+','');
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(roinames),cleantext(roinames));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'mmp_names.png'));

  % KGSROI atlas stuff (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.KGSROILabels.mgz',fsdir,surfsuffix2)), ...
    sprintf('kgsroi.png'),         'jet',         [0 6],     0.5,0.85,{});

  % KGSROI atlas stuff (with names)
  [~,roinames,~]=cvnroimask(subjectid,hemis,'KGSROI*',[],'orig','cell');
  roinames=regexprep(roinames{1},'@.+','');
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(roinames),cleantext(roinames));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'kgsroi_names.png'));

  % gVTC (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.gVTC.mgz',fsdir,surfsuffix2)), ...
    sprintf('gVTC.png'),        'copper',      [0 1],      0.5,[],{});

  % gEVC (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.gEVC.mgz',fsdir,surfsuffix2)), ...
    sprintf('gEVC.png'),        'copper',      [0 1],      0.5,[],{});

  % flocgeneral (without names)
  [roiimg,~,rgbimg]=writefun(cvnloadmgz(sprintf('%s/label/?h%s.flocgeneral.mgz',fsdir,surfsuffix2)), ...
    sprintf('flocgeneral.png'), 'copper',      [0 1],      0.5,[],{});
 
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
    sprintf('aparc.png'),     jet(36),      [0.5 36.5], 0.5,0.85,{});

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
    sprintf('aparc2009.png'), jet(76),      [0.5 76.5], 0.5,0.75,{});

  % FreeSurfer aparc.a2009s (with names)
  rgbimg=drawroinames(roiimg,rgbimg,L,1:numel(fslabels2009),cleantext(fslabels2009));
  imwrite(rgbimg,sprintf('%s/%s',outputdir,'aparc2009_names.png'));

  %%%%% anatomical data stuff:
  
  if ~isempty(numlayers)

    % calc
    infilenames =  [cellfun(@(x) sprintf('layer%s%d',layerprefix,x),num2cell(1:numlayers),'UniformOutput',0) {'white' 'pial'}];
    outfilenames = [cellfun(@(x) sprintf('layer%d',x),num2cell(1:numlayers),'UniformOutput',0) {sprintf('layer%d',numlayers+1) 'layer0'}];

    % special SURFVOX stuff
% Aug 14 2017: drop these and reduce the list
%    mms = [0.5 0.8 1 1.5 2 2.5 3];
    mms = [0.8 2];
    volnames = arrayfun(@(x) sprintf('SURFVOX%.1f',x),mms,'UniformOutput',0);

    % process quantities for each layer
      prev = warning('query');
      warning off;
    todos = [{'T1' 'T2' 'FMAP' 'BVOL' 'MAXEDIT' 'SINUSBW' 'SWI'} volnames];   % Aug 14 2017 - drop: 'DIM1' 'DIM2' 'DIM3' 
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
          if ~isempty(regexp(surftype0,'flat.patch'))  % hm, why is this here?
            continue;
          end
          if p==1
            rng = [0 mean(temp)*3];  % WEIRD HEURISTIC!
          end
          cmap0 = 'gray';
        elseif ismember(todos{q},{'SWI'})
          if p==1
            rng = [0 prctile(temp(:),99)];
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
        writefun(temp,sprintf('%s_%s.png',todos{q},outfilenames{p}),cmap0,rng,thresh0,alpha0,{});
      end
    end
      warning(prev);

  else

    % calc
    infilenames =  {'graymid'};  % 'white' 'pial' 
    outfilenames = {'graymid'};  % 'white' 'pial' 

    % process quantities for each layer
      prev = warning('query');
      warning off;
    todos = {'T1divT2'};
    for q=1:length(todos)
      for p=1:length(infilenames)
        file0 = matchfiles(sprintf('%s/surf/*.%s_%s.mgz',fsdir,todos{q},infilenames{p}));
        if isempty(file0)
          continue;
        end
        temp = cvnloadmgz(file0);
        thresh0 = [];  % default
        alpha0 = [];   % default
        if ismember(todos{q},{'T1divT2'})
%           if ~isempty(regexp(surftype0,'flat.patch'))  % hm, why is this here?
%             continue;
%           end
          if p==1
            rng = prctile(temp(:),[1 99]);
          end
          cmap0 = 'jet';
        end
        writefun(temp,sprintf('%s_%s.png',todos{q},outfilenames{p}),cmap0,rng,thresh0,alpha0,{});
      end
    end
      warning(prev);

  end

  %%%%% flatgrid stuff:

  if ~isempty(regexp(surftype0,'flat.patch'))
    writefun(cvnloadmgz(sprintf('%s/label/?h%s.%s.badness.mgz',fsdir,surfsuffix2,surftype0)), ...
      sprintf('badness.png'),  'hot',  [-1 2],[],[],{});
  end

end
