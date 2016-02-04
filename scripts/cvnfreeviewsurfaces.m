% change to subject directory
cd /software/freesurfer/subjects/C0041/

% check number of vertices
mris_info surf/lh.inflatedDENSETRUNCpt  % 412008
mris_info surf/rh.inflatedDENSETRUNCpt  % 469547

% define
datadir = '/stone/ext1/fmridata/20151008-ST001-kk,test/';
numlh = 412008;
numrh = 469547;
numlayers = 6;

% load in data
file0 = [datadir '/preprocessSURF/mean.nii'];
data = single(loadbinary(file0,'int16',[numlh+numrh numlayers 0]));

% write out a temporary mgz file
cvnwritemgz('C0041','temp',data(1:numlh,1,1),'lh','/home/knk/');
cvnwritemgz('C0041','temp',data(1:numlh,6,1),'lh','/home/knk/');

% view it in freeview
freeview -f surf/lh.inflatedDENSETRUNCpt:curv=surf/lhDENSETRUNCpt.curv:overlay=/home/knk/lh.temp.mgz



% i.e. look at mean EPI on dense surface with curvature underlay
