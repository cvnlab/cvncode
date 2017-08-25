function cvnvisualizestandardglm(subjectid,numlayers,layerprefix,fstruncate,datadir,outputdir,assumedir)

% function cvnvisualizestandardglm(subjectid,numlayers,layerprefix,fstruncate,datadir,outputdir,assumedir)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate> is like 'pt'
% <datadir> is the data directory, like
%   '/home/stone-ext1/fmridata/20160628-CVNS003-fLoc_ph'
% <outputdir> is like
%   '/home/stone/generic/Dropbox/cvnlab/ppresults/CVNS003/glmviz/20160628-CVNS003-fLoc_ph'
% <assumedir> is like 'GLMCS_floc_assume'
%
% For a number of different views, write out figures showing a variety of quantities related
% to the GLM results in <datadir>/<assumedir>.
%
% These figures pertain to:
% (1) from the condition-split GLM: R2 values, beta weights and their errors
% (2) the visually responsive ROI that is manually defined based on the condition-split GLM R2
%
% history:
% - 2017/08/25 - remove FIR-related stuff and only do some selected viewpoints
% - 2017/08/14 - add support for flat.patch

% REMOVED / STALE:
% <firdir> is like 'GLM_FIR_Standard'
% (2) from the FIR GLM: estimates of peak time
% We also create some non-map-based figures pertaining to
% R2 values, the PCA analysis, and the peak times.

%%%%%%%%% setup

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

% construct filenames and extension names
filestoload = {}; extnames = {};
for p=1:numlayers
  filestoload{p} = sprintf('layer%d.mat',p);
  extnames{p} = sprintf('%d',p);
end
filestoload{end+1} = 'layermean.mat';
extnames{end+1} = 'mean';

% load the data
fprintf('loading data...');
clear data;
for p=1:length(filestoload)
  data(p) = load([datadir '/' assumedir '/results/' filestoload{p}]);
end
fprintf('done.\n');

% load the visually responsive ROI
vrroi = loadmulti([datadir '/' assumedir '/ROIs/?h.VIS_RESP_thresh10.mat'],'R',1);  % vertices x 1

% load valid
valid = loadmulti(sprintf([datadir '/preprocessVER1SURF%s/valid.mat'],subjectid),'data');  % 1 x 6 x vertices
valid = logical(squish(permute(valid,[3 2 1]),2));  % vertices*6 x 1

% STALE
% % load PCA results
% a1 = load([datadir '/' firdir '/results/pca.mat']);
% 
% % prep peaktime
% peaktime = reshape(copymatrix(zeros(size(valid)),valid,a1.peaktime),[],numlayers);  % vertices x 6

%%%%%%%%% proceed

% define
allviews = { ...
...%  {'ventral'        'sphere'                   0 1000    0         [1 1]} ...
   {'occip'          'sphere'                   0 1000    0         [1 1]} ...
...%  {'occip'          'inflated'                 0  500    0         [1 1]} ...
...%  {'ventral'        'inflated'                 1  500    0         [1 1]} ...
...%  {'parietal'       'inflated'                 0  500    0         [1 1]} ...
...%  {'medial'         'inflated'                 0  500    0         [1 1]} ...
...%  {'lateral'        'inflated'                 0  500    0         [1 1]} ...
...%  {'medial-ventral' 'inflated'                 0  500    0         [1 1]} ...
   {'occip'          'sphere'                   0 1000    1         [1 1]} ...
...%  {'ventral'        'inflated'                 1  500    1         [1 1]} ...
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
    'xyextent',xyextent0,'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverageDENSETRUNC%s',fstruncate),[]));

  % make helper functions
  writefun = @(vals,filename,cmap,rng,thresh,alpha) ...
    cvnlookupimages(subjectid,setfield(VIEW,'data',double(vals)),hemistouse,viewpt,L, ...  % NOTE: double
    'xyextent',xyextent0,'text',hemitextstouse,'surftype',surftype0,'imageres',imageres0, ...
    'surfsuffix',choose(fsaverage0,sprintf('fsaverageDENSETRUNC%s',fstruncate),[]), ...
    'colormap',cmap,'clim',rng,'filename',sprintf('%s/%s',outputviewdir,filename), ...
    'threshold',thresh,'overlayalpha',alpha);  % circulartype

  %%%%% CALC
  
  % calc
  numv = size(data(1).R2,1);
  
  % construct concatenations
  allmeanvol = cat(1,data(1:numlayers).meanvol);
  allR2      = cat(1,data(1:numlayers).R2);
  
  % check: when meanvol is 0, this is exactly when R2 is not finite (i.e. missing data!)
  weird1 = allmeanvol==0;
  weird2 = ~isfinite(allR2);
  assert(isequal(weird1,weird2));
  
  % calculate some nice ranges
  epimx = prctile(double(allmeanvol(~weird1)),99);
  R2rng = prctile(double(allR2(~weird1)),[.1 99.9]);
  
  %%%%% WRITE MAPS

  % mean signal intensity
  for pp=1:numlayers+1
    writefun(double(vflatten(data(pp).meanvol)), ...
      sprintf('meanvol_layer%s.png',extnames{pp}),'gray',[0 epimx],[],[]);
  end
  
  % R2
  for pp=1:numlayers+1

    % fixed range (0% to 40%)
    writefun(double(vflatten(data(pp).R2)), ...
      sprintf('R2_layer%s.png',extnames{pp}),'hot',[0 40],[],[]);
    
    % tailored range (log-ish scale, from .1 to 99.9 percentile)
    writefun(log(normalizerange(double(vflatten(data(pp).R2)),1,2,R2rng(1),R2rng(2))), ...
      sprintf('R2tailor_layer%s.png',extnames{pp}),'jet',[log(1) log(2)],[],[]);

  end
  
  % R2 per run (only for layermean) using tailored range
  pp=numlayers+1;
  for qq=1:size(data(1).R2run,2)
    writefun(log(normalizerange(double(vflatten(data(pp).R2run(:,qq))),1,2,R2rng(1),R2rng(2))), ...
      sprintf('R2runtailor_run%02d_layer%s.png',qq,extnames{pp}),'jet',[log(1) log(2)],[],[]);
  end
  
  % mean beta (signed); mean betaerr; meanbetasnr (abs of the ratio)    [useful for negative stuff in sinus?]
  for pp=1:numlayers+1
  
    % calc
    temp = reshape(data(pp).modelmd,numv,data(pp).reps_per_run,[]);
    meanbeta = mean(mean(temp,2),3);                          % mean across reps, mean across conditions
    meanbetaerr = mean(std(temp,[],2)/sqrt(size(temp,2)),3);  % SE across reps, mean across conditions

    % write the mean beta (PSC)
    writefun(double(vflatten(meanbeta)), ...
      sprintf('meanbeta_layer%s.png',   extnames{pp}),'cmapsign4',[-10 10],[],[]);

    % write the mean betaerr (PSC)
    writefun(double(vflatten(meanbetaerr)), ...
      sprintf('meanbetaerr_layer%s.png',extnames{pp}),'pink',     [0 5],   [],[]);

    % write the mean betasnr
    writefun(double(vflatten(abs(meanbeta./meanbetaerr))), ...
      sprintf('meanbetasnr_layer%s.png',extnames{pp}),'hot',      [0 10],  [],[]);
  
  end
  
  % the visually responsive ROI
  [roiimg,~,rgbimg] = writefun(double(vflatten(vrroi)), ...
    sprintf('vrroi.png'),'gray',[0 1],0.5,0.7);

% STALE
%   % peak time
%   for pp=1:numlayers
%     writefun(double(vflatten(peaktime(:,pp))), ...
%       sprintf('peaktime_layer%s.png',extnames{pp}),'jet',[4 10],[],[]);
%   end

  %%%%% proceed to non-maps
  
  if zz==1

% WELL, DO WE NEED THIS
%     % hist of R2
%     figureprep([100 100 800 800]); hold on;
%     hist(allR2(~weird1),-4:2:100);
%     xlabel('R2');
%     ax = axis; axis([-4 100 ax(3:4)]);
%     figurewrite('histR2',[],[],outputdir);

% STALE
%     % PC timecourses
%     numtoplot = 5;
%     figureprep([100 100 700 500]);
%     h = plot(a1.v(:,1:numtoplot));
%     legend(h,'Location','EastOutside');
%     set(straightline(0,'h','k-'),'LineWidth',2);
%     xlabel('time points (raw)');
%     figurewrite('PC_timecourses',[],[],outputdir);
%     
%     % PC eigenvalues
%     figureprep([100 100 500 500]);
%     plot(diag(a1.s),'ro-');
%     xlabel('PC number');
%     ylabel('Eigenvalue');
%     figurewrite('PC_eigenvalues',[],[],outputdir);
% 
%     % hist of peaktime
%     figureprep([100 100 600 600]);
%     hist(a1.peaktime(:),1000);
%     xlabel('Peak time (s)');
%     figurewrite('histpeaktime',[],[],outputdir);
% 
%     % scatter R2 vs peaktime
%     figureprep([100 100 600 600]); hold on;
%     xxx = allR2(valid);
%     yyy = a1.peaktime(:);
%     bbx = linspace(0,80,100);
%     bby = 0:0.1:15;
%     [n,x,y] = hist2d(xxx,yyy,bbx,bby);
%     imagesc(x(1,:),y(:,1),log(n));
%     colormap(jet);
%     xlabel('R2')
%     ylabel('Peak time (s)');
%     axis([0 80 0 15]);
%     figurewrite('R2_vs_peaktime',[],[],outputdir);

  end

end
