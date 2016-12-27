function cvngrandfunctionalinspection(subjids,sessions,ppname,outputdir)

% function cvngrandfunctionalinspection(subjids,sessions,ppname,outputdir)
%
% <subjids> is a cell vector of subject ids
% <sessions> is a cell vector of cell vectors of scan session names (corresponding to <subjids>)
% <ppname> is like 'preprocessVER1SURF' (when loading data, we tack on the subject id automatically)
% <outputdir> is like '/home/stone/generic/Dropbox/cvnlab/ppresults/allsubjects'
%
% Take the surface-based pre-processed results in all of the scan sessions
% and write out some figures to <outputdir>. These figures pertain to raw 
% signal intensities and tSNR, and explore dependence on layers.

%%%%%%%%%%%% load in stuff

% make output directory
mkdirquiet(outputdir);

% init
vals = [];
cnt = 1;

% loop over sessions
for p=1:length(subjids)
  for q=1:length(sessions{p})
  
    % define
    dir0 = sessions{p}{q};
    ppdir = sprintf('/home/stone-ext1/fmridata/%s/%s%s',dir0,ppname,subjids{p});

    % load
    V = load(sprintf('%s/valid.mat',ppdir));  % load in valid mask
    M = load(sprintf('%s/mean.mat',ppdir));   % load in mean intensities
    T = load(sprintf('%s/tsnr.mat',ppdir));   % load in tSNR
    
    % extract
    for r=1:V.numlayers
      valid0 = find(V.data(1,r,:));
      vals(cnt,r,1) = median(double(M.data(1,r,valid0)));
      vals(cnt,r,2) = nanmedian(double(T.data(1,r,valid0)));   % nanmedian necessary because some vertices can be NaN (if mean is negative)
    end
    
    % increment
    cnt = cnt + 1;

  end
end

%%%%%%%%%%%% make figures

% calc
sessionnames = catcell(2,cellfun(@(x,y) cellfun(@(z) [x ' -- ' z],y,'UniformOutput',0),subjids,sessions,'UniformOutput',0));

% figure for signal intensity
figureprep([100 100 1000 700]);
barh(vals(:,:,1),1);
xlabel('Raw signal intensity');
set(gca,'YTick',1:size(vals,1));
set(gca,'YTickLabel',sessionnames);
set(gca,'YDir','reverse');
title('Median signal intensity as a function of layers');
figurewrite('grandsignalintensity',[],[],outputdir);

% figure for tSNR
figureprep([100 100 1000 700]);
barh(vals(:,:,2),1);
xlabel('tSNR');
set(gca,'YTick',1:size(vals,1));
set(gca,'YTickLabel',sessionnames);
set(gca,'YDir','reverse');
title('Median tSNR as a function of layers');
figurewrite('grandtsnr',[],[],outputdir);
