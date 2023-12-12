function cvnatlasprocessing(subjectid,fstruncate,rois)

% function cvnatlasprocessing(subjectid,fstruncate,rois)
%
% <subjectid> is like 'cvn7002'
% <fstruncate> is the name of the truncation surface in fsaverage (e.g. 'pt', 
%   which refers to 'lh.pt' and 'rh.pt'). If supplied, we process both
%   the dense and non-dense cases. If [], we just do the regular non-dense case. 
% <rois> is a cell vector of ROI names
%
% Transfer some fsaverage atlases to individual subject's surface.
% Also, create a 0.8-mm volume version of the corticalsulc atlas.
%
% *** SOME BACKGROUND INFORMATION: ***
%
% Atlases defined on the fsaverage surface space are to be placed in
%   /home/stone/software/freesurferspecialfiles/fsaveragemaps/
% Please see that directory for details.
% 
% Here are the atlases that are available so far:
% - KayDataFFA1-[LH,RH].mgz - This is a file with the group-ROI (fraction of subjects with the ROI existing at that vertex) for FFA-1, taken from Kendrick’s reading data.
% - [lh,rh].Kastner2015.mgz - This contains values in 0 through 25 with ROI labels taken from Wang Cerebral Cortex 2014.
%   - See Dropbox/resources/Kastner2015Atlas for various information files. These files were obtained from Noah Benson (so we trust that he did the right thing!). Kendrick rsynced the .mgz files from this directory to the fsaveragemaps directory.
%   - Actually, as of June 4 2019, we are now using the new HCP7RET OSF version.
%   - Note: The old filename was "Kastner2015Labels-[LH,RH].mgz".
% - [lh,rh].aIPS.mgz - broad anatomical mask of the intraparietal sulcus
% - [lh,rh].aVTC.mgz - broad anatomical mask of ventral temporal cortex
% - [lh,rh].gVTC.mgz - broad anatomical mask of ventral temporal cortex, designed for gridding purposes
% - [lh,rh].hVTC.mgz - larger broad anatomical mask of ventral temporal cortex, designed for gridding purposes
% - [lh,rh].gEVC.mgz - broad anatomical mask of early visual cortex (V1-V3), designed for gridding purposes
% - [lh,rh].flocgeneral.mgz - broad mask of good R2 (layermean transferred to fsaverage, average 5 subjects) in occipital cortex
% - [lh,rh].visualsulc.mgz - This contains values in 0 through 14 with anatomical sulci and gyri labels that were manually defined by Kendrick and Keith.
% - [lh,rh].HCP_MMP1.mgz - This contains values in 0 through 180 with ROI labels from Glasser Nature 2016. See Dropbox/one-offs/HCP_MMP1.0.
% - [lh,rh].KGSROILabels.mgz - This contains values in 0 through 6 with ROI labels from KGS lab. See Dropbox/one-offs/KGSROI.
% - [lh,rh].corticalsulc.mgz - This contains values in 0 through 28 with anatomical sulci and gyri labels that were manually defined by Kendrick and Keith.
% - [lh,rh].streams.mgz - This contains values in 0 through 7 with visual system streams as defined by Dawn/Kalanit/Kendrick.

%% %%%%% Calculate some stuff

fsdir = sprintf('%s/%s/',cvnpath('freesurfer'),subjectid);
labeldir = sprintf('%s/label/',fsdir);
fmapdir = '/home/stone/software/freesurferspecialfiles/fsaveragemaps/';

%% %%%%% Transfer fsaverage atlases to an individual subject’s surface

% define
for rr=1:length(rois)

  % transfer
  cvntransferatlastosurface(subjectid,sprintf('%s/lh.%s.mgz',fmapdir,rois{rr}),'lh', ...
    rois{rr},fstruncate,@(x) nanreplace(x,0));
  cvntransferatlastosurface(subjectid,sprintf('%s/rh.%s.mgz',fmapdir,rois{rr}),'rh', ...
    rois{rr},fstruncate,@(x) nanreplace(x,0));
  
  % copy the .ctab and .txt file too:
  assert(copyfile(sprintf('%s/%s.mgz.*',fmapdir,rois{rr}),labeldir));

end

%% %%%%% Convert surface-based atlas labelings to 0.8-mm volume format

% notice that this is the non-dense case (using mid gray surface)!
cvnmapsurfacetovolume(subjectid,[],[],[], ...
  reshape(cvnloadmgz(sprintf('%s/*h.corticalsulc.mgz',labeldir)),1,1,[]),0, ...
  sprintf('%s/mri/corticalsulc',fsdir),[],28);
