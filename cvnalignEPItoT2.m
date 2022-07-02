function cvnalignEPItoT2(subjectid,outputdir,meanfunctional,mcmask,wantaffine,tr,wanthack,mode)

% function cvnalignEPItoT2(subjectid,outputdir,meanfunctional,mcmask,wantaffine,tr,wanthack,mode)
%
% <subjectid> is like 'C0001'
% <outputdir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/freesurferalignment'
% <meanfunctional> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocess/mean.nii'
% <mcmask> (optional) is {mn sd} with the mn and sd outputs of defineellipse3d.m.
%   If [] or not supplied, we prompt the user to determine these with the GUI.
% <wantaffine> (optional) is whether to use affine (instead of rigid-body). Default: 0.
% <tr> (optional) is the starting point to use. Can be an actual transformation struct,
%   or can be one of the following:
%   1 means to use the old built-in default
%   2 means to use the new built-in default (Apr 18 2018)
%   Default: 2.
% <wanthack> (optional) is to rotatematrix(...,1,2,1) to the functional to help with fitting.
%   note that the alignment parameters that are determined are with respect to the
%   rotated functional. however, all other files that we output are as if we didn't rotate. 
%   if you make use of the alignment parameters, you must remember to do the 
%   necessary compensation! <wanthack> should no longer be necessary given that we
%   exposed rotorder in alignvolumedata.m.
% <mode> (optional) is
%   0 means default behavior
%   1 means save 'mcmask' and initial alignment parameters 'tr', but quit early
%  -1 means ignore the <mcmask> and <tr> inputs,
%     load 'mcmask' and 'tr' parameters from alignment.mat,
%     and do not pause for manual intervention.
%   Default: 0.
%
% Perform alignment of the <meanfunctional> to the T2 anatomy (which should have
% been created by cvnalignT2toT1.m).  In the alignment, there is a pause for the 
% user to inspect and modify the ellipse mask that is placed on the <meanfunctional>.
% The ellipse should focus on cortex and it is okay to leave some air around the brain.
% After that, there is a pause for the user to get a rough initial seed for the alignment.
%
% Registration is automatically performed using a rigid-body (or affine) transformation
% and a correlation metric. Note that there is an initial guess for the 
% alignment, and this may need to be revisited as the need arises.
%
% Note that when the user is setting up the initial seed, if the user sets the variable
% wantmanual=1, then the auto-alignment will be skipped when dbcont is issued.
%
% Alignment parameters ('tr', 'T') and 'mcmask' are saved to alignment.mat in <outputdir>.
% Diagnostic images of the alignment quality are written to <outputdir>.
% We also write out EPIalignedtoT2.nii.gz to <outputdir>. This is the mean functional
%   that has been resliced to match the T2 (and saved using the T2 as a template).
% We also write out T2alignedtoEPI.nii.gz and T1alignedtoEPI.nii.gz to <outputdir>.
%   This is the T2 and T1 that have been resliced to match the mean functional
%   (and saved using the mean functional as a template).
%
% history:
% - 2018/10/18 - add <mode>
% - 2018/04/18 - new default <tr> and mechanism to allow different defaults.
% - 2018/03/06 - add <wanthack>
% - 2017/01/31 - add "epimatchedtoT1" png inspections
% - 2016/11/04 - round mn and sd to 6 significant digits
% - 2016/09/02 - implement wantmanual; fix the gzipping

% input
if ~exist('mcmask','var') || isempty(mcmask)
  mcmask = [];
end
if ~exist('wantaffine','var') || isempty(wantaffine)
  wantaffine = 0;
end
if ~exist('tr','var') || isempty(tr)
  tr = 2;
end
if ~exist('wanthack','var') || isempty(wanthack)
  wanthack = 0;
end
if ~exist('mode','var') || isempty(mode)
  mode = 0;
end

% make directory
mkdirquiet(outputdir);

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
t1nifti = sprintf('%s/mri/T1.nii.gz',fsdir);
t2nifti = sprintf('%s/mri/T2alignedtoT1.nii.gz',fsdir);

% revert to T1 if necessary
if ~exist(t2nifti,'file')
  fprintf('*** Warning: T2 not found. Using the T1. ***\n');
  t2nifti = t1nifti;
end

% load the T2 anatomy
vol1orig = load_untouch_nii(gunziptemp(t2nifti));
vol1size = vol1orig.hdr.dime.pixdim(2:4);
vol1 = double(vol1orig.img) * vol1orig.hdr.dime.scl_slope + vol1orig.hdr.dime.scl_inter;
vol1(isnan(vol1)) = 0;
vol1 = fstoint(vol1);  % this is necessary to get the surfaces to match the anatomy
fprintf('vol1 has dimensions %s at %s mm.\n',mat2str(size(vol1)),mat2str(vol1size));

% load the T1 anatomy
vol3orig = load_untouch_nii(gunziptemp(t1nifti));
vol3size = vol3orig.hdr.dime.pixdim(2:4);
vol3 = double(vol3orig.img) * vol3orig.hdr.dime.scl_slope + vol3orig.hdr.dime.scl_inter;
vol3(isnan(vol3)) = 0;
vol3 = fstoint(vol3);  % this is necessary to get the surfaces to match the anatomy
fprintf('vol3 has dimensions %s at %s mm.\n',mat2str(size(vol3)),mat2str(vol3size));

% load the mean functional
vol2orig = load_untouch_nii(gunziptemp(meanfunctional));
vol2size = vol2orig.hdr.dime.pixdim(2:4);
vol2 = double(vol2orig.img) * vol2orig.hdr.dime.scl_slope + vol2orig.hdr.dime.scl_inter;
vol2(isnan(vol2)) = 0;
if wanthack
  assert(round(100*vol2size(1))==round(100*vol2size(2)));
  vol2 = rotatematrix(vol2,1,2,1);
end
fprintf('vol2 has dimensions %s at %s mm.\n',mat2str(size(vol2)),mat2str(vol2size));

% manually define ellipse to be used in the auto alignment
if isequal(mode,-1)
  mcmask = loadmulti(sprintf('%s/alignment.mat',outputdir),'mcmask');
else
  if isempty(mcmask)
    [f,mn,sd] = defineellipse3d(vol2);
    mcmask = {eval(mat2str(mn,6)) eval(mat2str(sd,6))};
    fprintf('mcmask = %s;\n',cell2str(mcmask));
  end
end
mn = mcmask{1};
sd = mcmask{2};

% deal with default tr
if isequal(mode,-1)
  tr = loadmulti(sprintf('%s/alignment.mat',outputdir),'tr');
else
  if isnumeric(tr)
    switch tr
    case 1
      tr = maketransformation([0 0 0],[1 2 3],[120 60 140],[1 2 3],[-10 50 80],size(vol2),size(vol2).*vol2size,[1 1 -1],[0 0 0],[0 0 0],[0 0 0]);
    case 2
      tr = maketransformation([0 0 0],[1 2 3],[128 70 121],[1 3 2],[92 85 35],size(vol2),size(vol2).*vol2size,[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    end
  end
end

% start the alignment
alignvolumedata(vol1,vol1size,vol2,vol2size,tr);

% if mode is not -1, pause to do some manual alignment (to get a reasonable starting point)
if ~isequal(mode,-1)
  clear wantmanual;
  keyboard;
end
tr = alignvolumedata_exporttransformation;  % report to the user to save just in case

% perhaps save early?
switch mode

case {0 -1}
  % do nothing special and just proceed

case 1

  % write tr and mcmask to a .mat file and just get out
  save(sprintf('%s/alignment.mat',outputdir),'tr','mcmask');
  return;

end

% if the user sets wantmanual to 1, then we will stop instead of proceeding with auto-alignment!

% well, if the user wanted manual alignment, let it through
if exist('wantmanual','var') && wantmanual

  % do nothing

% otherwise, do auto-alignment
else  

  % auto-align (correlation)
  if wantaffine
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[4 4 4]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[2 2 2]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
    alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1]);

% MUTUAL INFORMATION:
%     alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[4 4 4],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[2 2 2],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1],[],[],[],1);
%     alignvolumedata_auto(mn,sd,[0 0 0 0 0 0 1 1 1 1 1 1],[1 1 1],[],[],[],1);
  else
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[4 4 4]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[2 2 2]);
    alignvolumedata_auto(mn,sd,[1 1 1 1 1 1 0 0 0 0 0 0],[1 1 1]);
  end

  % record transformation
  tr = alignvolumedata_exporttransformation;

end

% convert the transformation to a matrix
T = transformationtomatrix(tr,0,vol1size);
fprintf('T=%s;\n',mat2str(T));

% get slices from T2 and T1 to match EPI
anatmatch1 = extractslices(vol1,vol1size,vol2,vol2size,tr);
anatmatch3 = extractslices(vol3,vol3size,vol2,vol2size,tr);

% get slices from EPI to match T1 (and T2)
epimatch =   extractslices(vol1,vol1size,vol2,vol2size,tr,1);

% quantify goodness
good = isfinite(anatmatch1(:)) & anatmatch1(:)~=0 & isfinite(vol2(:)) & vol2(:)~=0;
rpearson = corr(anatmatch1(good),vol2(good));
rspear =   corr(anatmatch1(good),vol2(good),'Type','Spearman');

% write results to a .mat file
save(sprintf('%s/alignment.mat',outputdir),'tr','T','mcmask','rpearson','rspear');

% have to deal with the hack
if wanthack
  anatmatch1 = rotatematrix(anatmatch1,1,2,-1);
  anatmatch3 = rotatematrix(anatmatch3,1,2,-1);
  vol2 =       rotatematrix(vol2,1,2,-1);
end

% inspect the alignment
makeimagestack3dfiles(vol2,              sprintf('%s/epi', outputdir),[2 2 2],[0 0 -1],[],1);
makeimagestack3dfiles(anatmatch1,        sprintf('%s/anat',outputdir),[2 2 2],[0 0 -1],[],1);
makeimagestack3dfiles(inttofs(epimatch), sprintf('%s/epimatchedtoT1',outputdir),[5 5 5],[-1 1 0],[],1);

% save NIFTI file (EPI matched to the T2)
vol1orig.img = inttofs(cast(epimatch,class(vol1orig.img)));
file0 = sprintf('%s/EPIalignedtoT2.nii',outputdir);
save_untouch_nii(vol1orig,file0); gzip(file0); delete(file0);

% save NIFTI file (T2 matched to the EPI)
vol2orig.img = cast(anatmatch1,class(vol2orig.img));
file0 = sprintf('%s/T2alignedtoEPI.nii',outputdir);
save_untouch_nii(vol2orig,file0); gzip(file0); delete(file0);

% save NIFTI file (T1 matched to the EPI)
vol2orig.img = cast(anatmatch3,class(vol2orig.img));
file0 = sprintf('%s/T1alignedtoEPI.nii',outputdir);
save_untouch_nii(vol2orig,file0); gzip(file0); delete(file0);

%%%%%%%%%%%%%%%%%%%%%%%% JUNK:

% temp = imresizedifferentfov(vol2,vol2size(1:2),sizefull(vol2,2),vol2size(1:2));
