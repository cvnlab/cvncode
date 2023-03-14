%% This document demonstrates basic usage of cvndefinerois.m.

% Note that cvndefinerois.m requires the cvncode github repository.

% A video walkthrough of this example is at https://youtu.be/vwqJ0EpfsFE


%% Example use of cvndefinerois.m

% define
fsdir = getenv('SUBJECTS_DIR');

% load some data
thick = cvnreadsurfacemetric('fsaverage',{'lh' 'rh'},'thickness',[],'orig');
thick = {thick.data(1:163842) thick.data(163842+1:end)};

% above, we prepared the thickness measure as the data. but of course,
% you may want to load some other data (e.g. some analysis result)
% in order to visualize on the brain and draw ROIs.

% define
subjid = 'fsaverage';   % which subject
cmap   = jet(256);      % colormap for ROIs
rng    = [0 3];         % should be [0 N] where N>=1 is the max ROI index
roilabels = {'ROI1' 'ROI2' 'ROI3'};  % 1 x N cell vector of strings
mgznames = {thick};     % quantities of interest in label/?h.MGZNAME.mgz (1 x Q)
crngs = {[0 5]};        % ranges for the quantities (1 x Q)
cmaps = {copper};       % colormaps for the quantities (1 x Q)
threshs = {[]};         % thresholds for the quantities (1 x Q)
roivals = [];           % start with a blank slate

% do it
cvndefinerois;

% keyboard shortcuts are described in drawroipoly.m.
