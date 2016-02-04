%%%% THIS INHERITED FROM masteranalysis3_category.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREPARE THE DATA

% transfer all data (DICOMs, fieldmaps, screenshots, etc.) to ~knk/ext/rawdata/XXX/
%   use rsync to preserve dates! [check modification dates]
% clean out the hard drive (move to folder or delete)
% organize the files (dicoms, pfiles, SS, Stimuli (including script file), eye, physio).
% remove unnecessary test runs.
% remove physio data if bad:
%   rm -rf */*physio*
% get local copy of SS for reference.

% convert each diffusion run to NIFTI
foreach d0 (DWI_DIR??_??_????)
  echo "***************** $d0 ****************"
  dcm2nii -a y -o . $d0
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROCESS THE ANATOMY
% [S015,S016,S017,S018,S019,S020,S021,S022,S023,S024,S025,S027]

% see [anatomicaldata notesNEW.m].
% this saves various surface .mat files.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EDIT FMRISETUP

% edit fmrisetup.m as necessary.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREPROCESS THE DATA [90,91,92,93,94,95,96,97,98,99,101,102,103,104]
%                                           [111,112,113,114,115,116,118]
% - in general, be careful of modification dates!
% - consider nonlinear warping? [due to weird distortions?]

  % MAYBE?:
  % if applicable, perform cross-session alignment using the script alignment_XXX.m [and potentially do a pre-preprocessing]
  % then, perform the preprocessing using the script preprocessfmri_XXX.m  (consider less aggressive LPF of motion)
  % then, if applicable, perform postprocessfmri_XXX.m

% NEW PROCESSING SCHEME:
% 1. preprocess (in volume)
% 2. align mean functional to anatomy OR for-cross-session align EPI to EPI
% 3. preprocessVERTICES (using alignment, going straight to surface) [don't download the fig folders]

% watch the entire dataset for quality-control purposes    [we can use imagesequencetomovie.m]
for fff=[111:116 118]
  fmrisetup(fff);
  files = matchfiles([datadir '/preprocess/run*.nii']);
  data = single([]);
  for p=1:length(files)
    data = cat(4,data,single(getfield(load_untouch_nii(files{p}),'img')));
  end
  viewmovie(data,{sprintf('~/inout/allruns%d.mov',fmrisetupnum) 30});
end

%OLD: rsync -av knk@stone.psychology.wustl.edu:"~/ext/data/20140814S015/preprocess" .
%OMIT:
%% fix permissions (read-only):
%cd ~/ext/data/20140814S015; chmod -R 555 *

% if applicable, go back to anatomicaldata if epitr was made.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CHECK STIMULUS PRESENTATION + ANALYZE BEHAVIORAL DATA [IMPORTANT]

% see "behavioraldata".

% [behavioraldata_01basicchecks.m]
% BASIC CHECKS: [90,91,92,93,94,95,96,97,98,99,101,102,103,104]
%               [111,112,113,114,115,116,118]
%   (keybuttons added and only ran for 101,102,103,104,etc.)
% this saves results to [outputdir '/behavioraltimes.mat']

% [behavioraldata_02readingD.m]
% ADDITIONAL ANALYSIS: [101,102,103,104]
%                      [111,112,113,114,115,116,118]
% this saves consolidated results to '~/ext/figurefiles/readingDbehavioralresults.mat'

% [behavioraldata_02readingDparttwo.m]
% this saves results to ~/ext/figurefiles/BEHAVIORALEXTRACTION.mat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN GLMDENOISE [90,91,92,93,94,95,96,98,99,101,102,103,104]
%                                           [111,112,113,114,115,116,118]
% - hm. do we have a big motion case coming? [yes]
% - dvars before and after? [hm]
% - spatial pattern before and after? [we could look at this...]
% - take residuals for RSFC?? [save the residuals??] test-retest? [hmm]

% [for 91,92,93,etc. don't save the .bin files]

% setup
fmrisetup(111);

        % data = feval(datafunB);
        % 
        % for p=1:length(data)
        % 
        %       % a sample of white noise
        %       temp2 = randn(size(data{p}));
        % 
        %       % new regressor has the amplitude spectrum of the original regressor,
        %       % but the phase spectrum of the white noise
        %       data{p} = real(ifft(abs(fft(data{p},[],4)) .* exp(j * angle(fft(temp2,[],4))),[],4));
        % end
        % 
        % results = GLMdenoisedata(stimulus,data,stimdur,tr, ...
        %                          [],[],struct('bootgroups',bootgroups,'numpcstotry',20,'numboots',100), ...
        %                          ['~/inout/GLMdenoisefigures']);
        % a1=load([outputdir '/GLMdenoise.mat']);
        % 
        % figure; hist(results.R2(:),100);
        % figure; hold on;
        % hist(a1.R2(:),100);
        % straightline(prctile(results.R2(:),99.9),'v','g-');
        % 
        % vals = [1 .1 .01 .001];
        % xx = []; yy = [];
        % for zz=1:length(vals)
        %   cutoff = prctile(results.R2(:),100-vals(zz));
        %   xx(zz) = sum(a1.R2(:)>cutoff);
        %   yy(zz) = sum(results.R2(:)>cutoff);
        % end
        % figure; scatter(xx,yy,'ro');
        % figure; scatter(xx-yy,yy,'ro');

% do the GLM
results = GLMdenoisedata(stimulus,feval(datafunB),stimdur,tr, ...
                         [],[],struct('bootgroups',bootgroups,'numpcstotry',20,'numboots',100), ...
                         [outputdir '/GLMdenoisefigures']);
save([outputdir '/GLMdenoise.mat'],'-struct','results','-v7.3');
% savebinary([outputdir '/GLMdenoisemodelmd.bin'],'single',squish(results.modelmd{2},3)');
% savebinary([outputdir '/GLMdenoisemodelse.bin'],'single',squish(results.modelse{2},3)');
% savebinary([outputdir '/GLMdenoisemodels.bin'],'single',permute(squish(results.models{2},3),[2 3 1]));

% do the GLM [VERTICES]
data = feval(datafunV);

        % ONLY for 101,102,103,104,111,112,113,114,115,116,118
        %    (for 111 onwards, we don't run the original (non-ALT) version)
        % [didn't download figures / re-run full and test and retest]
        % SAVE TO FILES: GLMdenoisefiguresVERTICESALT, GLMdenoiseVERTICESALT
        wh = setdiff((1+8):2:(172-8),find(sum(stimulus{1},2)));
        for p=1:length(stimulus)
          if mod2(p,3)==1
            blanks1 = copymatrix(zeros(172,1),wh,1);
            blanks2 = zeros(172,1);
            blanks3 = zeros(172,1);
          elseif mod2(p,3)==2
            blanks1 = zeros(172,1);
            blanks2 = copymatrix(zeros(172,1),wh,1);
            blanks3 = zeros(172,1);
          else
            blanks1 = zeros(172,1);
            blanks2 = zeros(172,1);
            blanks3 = copymatrix(zeros(172,1),wh,1);
          end
          stimulus{p} = cat(2,stimulus{p}(:,1:24),blanks1,stimulus{p}(:,24+(1:24)),blanks2,stimulus{p}(:,24*2+(1:24)),blanks3);
        end

% full
results = GLMdenoisedata(stimulus,data,stimdur,tr, ...
                         [],[],struct('bootgroups',bootgroups,'numpcstotry',20,'numboots',100), ...
                         [outputdir '/GLMdenoisefiguresVERTICES']);
save([outputdir '/GLMdenoiseVERTICES.mat'],'-struct','results','-v7.3');
clear results;

% test (odd)
results = GLMdenoisedata(stimulus(1:2:end),data(1:2:end),stimdur,tr, ...
                         [],[],struct('bootgroups',bootgroups(1:2:end),'numpcstotry',20,'numboots',100), ...
                         [outputdir '/GLMdenoisefiguresVERTICES1']);
results = rmfield(results,'models');
save([outputdir '/GLMdenoiseVERTICES1.mat'],'-struct','results','-v7.3');
clear results;

% retest (even)
results = GLMdenoisedata(stimulus(2:2:end),data(2:2:end),stimdur,tr, ...
                         [],[],struct('bootgroups',bootgroups(2:2:end),'numpcstotry',20,'numboots',100), ...
                         [outputdir '/GLMdenoisefiguresVERTICES2']);
results = rmfield(results,'models');
save([outputdir '/GLMdenoiseVERTICES2.mat'],'-struct','results','-v7.3');
clear results;

% download the figures!

% notes: for 104, GLMdenoiseVERTICES2 (AND ALT2), manually set pc to 5 (crazy image artifact)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STITCH DATASETS TOGETHER [UNDER DEVELOPMENT, DEPRECATED?] [95,96,98]

%%%% MAYBE ONLY DO WHEN WE CARE ABOUT INDIVIDUAL VOXELS?

% 92 <- 95
% 94 <- 96
% 91 <- 98

% define
dataset1 = 94;
dataset2 = 96;

% load dataset 1
fmrisetup(dataset1);
a1 = load([outputdir '/GLMdenoiseVERTICES.mat'],'modelmd','modelse','meanvol','pcR2final');

% load dataset 2
fmrisetup(dataset2);
a2 = load([outputdir '/GLMdenoiseVERTICES.mat'],'modelmd','modelse','meanvol','pcR2final');

% WHICH
rr1 = load(lhroi);
ix1 = find(rr1.FACE3);
%good = permutedim(find(a1.pcR2final > 15 & a2.pcR2final > 15));
%good = permutedim(ix1(a1.pcR2final(ix1) > 30));
good = ix1(a1.pcR2final(ix1) > 30);

% visualize
for vvv=1:length(good)
  figureprep([100 100 500 300]);
  
  subplot(2,1,1); hold on;
  ix = [setdiff(1:32,[2 31 32]) 2 31 32];
  xx = [a1.modelmd{2}(good(vvv),ix) a2.modelmd{2}(good(vvv),:)];
  ee = [a1.modelse{2}(good(vvv),ix) a2.modelse{2}(good(vvv),:)];
  bar(xx,1);
  errorbar2(1:length(xx),xx,ee,'v','r-');
  straightline([32.5-3 32.5 32.5+3],'v','c-');

  subplot(2,1,2); hold on;
  ix = [setdiff(1:32,[2 31 32]) 2 31 32];
  xx = [a1.modelmd{2}(good(vvv),ix)/100*a1.meanvol(good(vvv)) a2.modelmd{2}(good(vvv),:)/100*a2.meanvol(good(vvv))];
  ee = [a1.modelse{2}(good(vvv),ix)/100*a1.meanvol(good(vvv)) a2.modelse{2}(good(vvv),:)/100*a2.meanvol(good(vvv))];
  bar(xx,1);
  errorbar2(1:length(xx),xx,ee,'v','r-');
  straightline([32.5-3 32.5 32.5+3],'v','c-');

  figurewrite(sprintf('ex%03d',vvv),[],[],'~/inout');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPUTE GENERAL SUBJECT SNR [90,91,92,93,94,95,96,98,99,101,102,103,104]
%                                           [111,112,113,114,115,116,118]
% [put in /research/datasummary]

% compute
sessions = [90 91 92 93 94 95 96 98 99 101 102 103 104 111 112 113 114 115 116 118];
snrs = [];
pcr2s = [];
snames = {};
for zzzz=1:length(sessions)
  fmrisetup(sessions(zzzz));
  a1 = load([outputdir '/GLMdenoise.mat'],'SNR','pcR2final');
  snrs(zzzz) = prctile(a1.SNR(:),99);
  pcr2s(zzzz) = prctile(a1.pcR2final(:),99);
  snames{zzzz} = stripfile(outputdir,1);
end

% SNR figure
figureprep;
barh(snrs);
set(gca,'YTick',1:length(snames),'YTickLabel',snames);
set(gca,'YDir','reverse');
xlabel('SNR');
figurewrite('snrsummary',[],[],'~/inout/');

% pcR2final figure
figureprep;
barh(pcr2s);
set(gca,'YTick',1:length(snames),'YTickLabel',snames);
set(gca,'YDir','reverse');
xlabel('pcR2final');
figurewrite('pcr2summary',[],[],'~/inout/');

% download figures

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COMPUTE SUBJECT-AVERAGED DATA [100] [deprecated..]

% see [subjectaverageddata notes.m]
% this saves results to subjectaveragedlocalizer.mat.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ANALYZE THE RETINOTOPY DATA [94,95,97,98,99,111,112,113,114,115,116,118]

% see [retinotopydata notes.m]
% this saves results to various .mat files.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ANALYZE THE LOCALIZER DATA [90,91,92,93,94,100,111,112,113,114,115,116,118]

% see [localizerdata notes.m]
% this saves results to GLMlocalizer.mat or GLMlocalizerSM.mat.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% GENERATE SURFACE MAPS [90,91,92,93,94,95,96,97,98,99,100,101,102,103,104]
%                                           [111,112,113,114,115,116,118]
% NOTE: 101,102,103,104 generated using the non-blank trial version. update at some point?

% see [surfacemaps notes.m]
% this makes a bunch of .png files.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEFINE ROIS

% see [ROIdefinition notes.m].
% this saves results to roislh.mat and roisrh.mat files in anatomicals directory.
% if new ROIs were defined, perhaps go back above and generate surface figures and check for sanity. [is this applicable???]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WHERE ARE THE ROIS IN EPI VOLUME SPACE? [90,91,92,93,94]
%%%% HM, SKIP THIS NOWADAYS...

% NOTE: run only for the sessions that control the epitr in fmrisetup.m (is this because of voxelwise?)

% setup
fmrisetup(93);

% load
a1 = load(lhmidgray);
a2 = load(rhmidgray);
a3 = load(lhroi);
a4 = load(rhroi);

% cvertex is volume with values indicating closest vertex
% dvertex is volume with values indicating distance in mm
[cvertex,dvertex] = verticestovoxels({a1.vertices a2.vertices},epitr,[1 1 1],xyzsize);

% make roivol
roivol = zeros(xyzsize);
for p=1:length(masterroilabels)
  good = [];
  if isfield(a3,masterroilabels{p})
    good = [good flatten(find(ismember(cvertex,find(a3.(masterroilabels{p})))))];
  end
  if isfield(a4,masterroilabels{p})
    good = [good flatten(find(ismember(cvertex,numlh+find(a4.(masterroilabels{p})))))];
  end
  good = good(dvertex(good) <= 2);  % only show those that are within 2mm of the vertex
  roivol(good) = p;  % clobber if overlap!
end

% write it out
mkdirquiet(sprintf('~/inout/%d',fmrisetupnum));
imwrite(uint8(makeimagestack(roivol)),masterroicolormap,sprintf('~/inout/%d/roivol.png',fmrisetupnum));

    % %%%%%%%%%%%%%%%%%%%%
    % 
    % - do relative to standard T1.mgz???
    %     YES, this would be useful so I can think about slice prescription planning.
    % 
    % - measure the cortical surface area. [well]
    % 
    % % ??map vertices to voxels
    % SM = load([outputdir '/surfacemappingLH.mat']);
    % roivxs = {};
    % for p=1:length(rois)
    %   valid = flatten(find(SM.voxelpass));
    %   roivxs{p} = flatten(valid(ismember(SM.cvertex(valid),find(rois{p}))));
    % end
    % 
    % % ??visualize in high res (high res or EPI)   ?write out every 3D slice, mapping each vertex to nearest 1mm cube.
    % save viewroisinvolume/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FINALLY, VIEW ROIS ON CURVATURE [surface] 
%   [90,91,92,93,94,95,96,97,98,99,101,102,103,104]
%   [111,112,113,114,115,116,118]

% setup
fmrisetup(118);

% load rois
a5 = load(lhroi);
a6 = load(rhroi);

% construct roi values
roivalslh = zeros(1,numlh);
roivalsrh = zeros(1,numrh);
for p=1:length(masterroilabels)
  if isfield(a5,masterroilabels{p})
    roivalslh(a5.(masterroilabels{p})) = p;
  end
  if isfield(a6,masterroilabels{p})
    roivalsrh(a6.(masterroilabels{p})) = p;
  end
end
roivals = [roivalslh roivalsrh];

% load surface information
lhinfo = load(lhwhite);
rhinfo = load(rhwhite);

% load camera views
vp = viewsurfacedata_preferences;
camlookup = @(suffix,vp) vp.camerapresets{find(cellfun(@(x)isequal(x,[subjectid suffix]),vp.camerapresets(:,1))),2};

% define some stuff
alltodo = {{'lhmidgray' 'lhflat'     {'leftflat'}                                                         1:numlh}
           {'lhmidgray' 'lhinflated' {'leftinflatedventral' 'leftinflatedlateral' ...
                                      'leftinflatedmedial' 'leftinflatedventralmedial'}   1:numlh}
           {'rhmidgray' 'rhflat'     {'rightflat'}                                                         numlh+(1:numrh)}
           {'rhmidgray' 'rhinflated' {'rightinflatedventral' 'rightinflatedlateral' ...
                                      'rightinflatedmedial' 'rightinflatedventralmedial'} numlh+(1:numrh)}};
alltodohemi = [1 1 2 2];
name = 'roioncurvature';

% visualize!
cd ~/inout;
for p=1:length(alltodo)  % for each surface type
  opt = alltodo{p};
  
  for r=1:length(opt{3})  % for each view
    viewname = opt{3}{r};
    dir0 = [sprintf('%d',fmrisetupnum) '/' viewname];
    mkdirquiet(dir0);

    % prepare some values
    val1 = -restrictrange(cat(1,lhinfo.curvature,rhinfo.curvature),-.5,.5)>0;
    val2 = roivals;
    val3 = val2>=9;  % THIS CONTROLS WHICH ROIS TO SEE
    
    % calc
    val = {flatten(val1(opt{4})) flatten(val2(opt{4}))};
    rng = {[-1 2] [-.5 nummasterroi+.5]};
    pval = {[] flatten(val3(opt{4}))};
    cmapnum = {64 1+nummasterroi};
    cmaptype = {0 0};

    % get the picture
    viewsurfacedata(evalin('base',opt{1}),evalin('base',opt{2}),val, ...
                    rng,   [],[],  pval,                   cmapnum,cmaptype);  % run it
    viewsurfacedata_importcamerapreset(camlookup(viewname,vp));                             % set the camera
    viewsurfacedata_setsurfaceoptions(1,{[] [] [] 'gray' [] [] [] [] []});                  % set the colormap
    viewsurfacedata_setsurfaceoptions(2,{[] [] [] 'masterroicolormap' [] 4 1 [] 1});        % set the colormap, pval, restrict
    viewsurfacedata_autosnapshot2;                                                          % take snapshot
    movefile('image000.png',[dir0 '/' name '.png']);                                        % set filename

    % clean up
    close all;

  end

end

% now, create compilationALT.ai and define finalroilabels and finalroiindices in fmrisetup.m!!
