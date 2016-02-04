%%%% THESE ARE JUST NOTES. NEED TO POLISH, FORMALIZE

% check Talairach transform by eye.  if basically sane, OK.
tkregister2 --subject S019 --fstal

% check skull stripping stuff.  if sane, OK.
tkmedit S019 orig.mgz -segmentation brainmask.mgz
tkmedit S019 brainmask.mgz -aux T1.mgz

% check white matter segmentation.  WTF hard to know.  also, white-matter is not the end-all (sometimes surfs seem to override).
tkmedit S018 brainmask.mgz -aux wm.mgz -surfs
tkmedit S018 brainmask.mgz -surfs -aux T1.mgz

% more checks
cd /software/freesurfer/subjects/S018/
freeview -v \
  mri/brainmask.mgz \
  mri/wm.mgz:colormap=heat:opacity=0.4 \
  -f surf/lh.white:edgecolor=blue \
     surf/lh.pial:edgecolor=red \
     surf/rh.white:edgecolor=blue \
     surf/rh.pial:edgecolor=red \
     surf/rh.inflated:visible=0 \
     surf/lh.inflated:visible=0

% streamline checks
cd /software/freesurfer/subjects/S018/
freeview -v \
  mri/brainmask.mgz \
  -f surf/lh.white:edgecolor=blue \
     surf/lh.pial:edgecolor=red \
     surf/rh.white:edgecolor=blue \
     surf/rh.pial:edgecolor=red

tksurfer S015 lh white
tksurfer S015 lh smoothwm
tksurfer S015 lh inflated
tksurfer S015 lh pial
tksurfer S015 lh sphere

tksurfer S015 rh white           % inner
tksurfer S015 rh smoothwm
tksurfer S015 rh inflated        % for visualization
tksurfer S015 rh pial            % outer
tksurfer S015 rh sphere
