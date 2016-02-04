%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ANALYZE RETINOTOPY DATA [94,95,97,98,99,111,112,113,114,115,116,118]
% - shouldn't ecc vs size... be a part of the general analysis stream?

% NOTE: below, turn off glmdenoise and add "noden" to the .mat suffix for these special-case analyses!

%%%%%%%%%%%%%%%%%%%%%%% prep
%%%% QUESTION: am i using the 5 Hz jump version??

% start parallel MATLAB to speed up execution
if matlabpool('size')==0
  matlabpool open;
end

% setup
fmrisetup(111);

% load data
data = feval(datafunRET);

% load pre-processed stimulus (1-s resolution) [FIRST VERSION]
stimulus = {};
stimulus{1} = loadmulti('~/ext/stimulusfiles/ppstimulus_retinotopy105res100.mat','stimulus');
stimulus{2} = loadmulti('~/ext/stimulusfiles/ppstimulus_retinotopy106res100.mat','stimulus');
stimulus = repmat(stimulus,[1 length(data)/2]);

% load pre-processed stimulus (1-s resolution) [SECOND VERSION for 111,112,113,114,115,116,118]
stimulus = {};
stimulus{1} = loadmulti('~/ext/stimulusfiles/ppstimulus_retinotopy106res100.mat','stimulus');
stimulus = repmat(stimulus,[1 2]);

% figure out voxels to analyze
good = flatten(find(~all(data{1}==0,2)));

% upsample data to match the stimulus resolution
data = tseriesinterp(data,2,1,2);  % 2 s -> 1 s, 2nd dimension

%%%%%%%%%%%%%%%%%%%%%%% analyze the data

% SOME THOUGHTS:
% - a different approach is denoise, smash, analyze?  benefit is computational time.

      %   % find some good voxels
      %   temp = abs(fft(data{1},[],2));
      %   temp2 = temp(:,1+8) ./ sqrt(sum(temp(:,2:end).^2,2));
      %   ok = find(temp2>.35);
      %   figure; plot(data{1}(ok,:)');
      % 
      % % analyze a few voxels
      % results = analyzePRF(stimulus,data,1,struct('vxs',ok,'display','off'));

%%%%% NOTE: the following two were run for 94 and 95 but PRE-MRIS_EXPAND FIX.  WE ABANDON NOW

% % analyze
% results = analyzePRF(stimulus,data,1,struct('vxs',good,'numperjob',200,'maxiter',100,'display','off','seedmode',[0 1]));
% 
% % analyze + GLMdenoise
% results2 = analyzePRF(stimulus,data,1,struct('vxs',good,'numperjob',200,'maxiter',100,'display','off','seedmode',[0 1], ...
%                                              'wantglmdenoise',1));

%%%%%

% 300 is standard; ~2.5 times less for high res: 100
numperjob = 100;
numperjob = 300;

% analyze + GLMdenoise + supergrid
results3 = analyzePRF(stimulus,data,1,struct('vxs',good,'numperjob',numperjob,'maxiter',100,'display','off', ...  %300
                                             'wantglmdenoise',1));

% remember to download GLMdenoise figure dir (name as retGLMdenoisefigures)!

% test-retest
    %%%chosen = flatten(find(results3.R2 >= 5));   %used to do this
  % for 97
ix1 = [1 2  5 6  9 10];
ix2 = [3 4  7 8];
  % for 94,95,98,99
ix1 = 1:2;
ix2 = 3:4;
  % for 111,112,113,114,115,116,118
ix1 = 1;
ix2 = 2;
results3a = analyzePRF(stimulus(ix1),data(ix1), ...
                       1,struct('vxs',good,'numperjob',numperjob,'maxiter',100, ...
                                'display','off','wantglmdenoise',{results3.noisereg(ix1)}));
results3b = analyzePRF(stimulus(ix2),data(ix2), ...
                       1,struct('vxs',good,'numperjob',numperjob,'maxiter',100, ...
                                'display','off','wantglmdenoise',{results3.noisereg(ix2)}));

% save results
%results3a = rmfield(results3a,{'params'});
%results3b = rmfield(results3b,{'params'});
%save([outputdir '/retinotopySTANDARD.mat'],  '-struct','results');
%save([outputdir '/retinotopyGLMDENOISE.mat'],'-struct','results2');
save([outputdir '/retinotopyFINAL.mat'],     '-struct','results3');
save([outputdir '/retinotopyTEST.mat'],      '-struct','results3a');
save([outputdir '/retinotopyRETEST.mat'],    '-struct','results3b');

%%%%%%%%%%%%%%%%%%%%%% EXPORT TO FREESURFER FORMAT [94,95,98,99,111,112,113,114,115,116,118]
% AS WELL AS BV SMP FORMAT

% setup
fmrisetup(99);

% define
todo = {{'retinotopyFINAL.mat' 'retfull'} {'retinotopyTEST.mat' 'ret1'} {'retinotopyRETEST.mat' 'ret2'}};

% loop
for zz=1:length(todo)

  % load
  a1 = load([outputdir '/' todo{zz}{1}]);

  % prepare directory
  dir0 = sprintf('/software/freesurfer/subjects/%s/results/%s/',subjectid,todo{zz}{2});
  mkdirquiet(dir0);

  % define
  vars0 = {'R2' 'ang' 'ecc' 'expt' 'rfsize' 'meanvol'};

  % loop
  for p=1:length(vars0)
    vals = a1.(vars0{p});

    ix = 1:numlh;
    MRIwrite(struct('vol',vflatten(vals(ix))),sprintf('%s/lh.%s.mgh',dir0,vars0{p}));
    savesmp(sprintf('%s/lh.%s.smp',dir0,vars0{p}),flatten(vals(ix)),0,1,[0 0 0],[255 255 255],vars0{p},'');

    ix = numlh+(1:numrh);
    MRIwrite(struct('vol',vflatten(vals(ix))),sprintf('%s/rh.%s.mgh',dir0,vars0{p}));
    savesmp(sprintf('%s/rh.%s.smp',dir0,vars0{p}),flatten(vals(ix)),0,1,[0 0 0],[255 255 255],vars0{p},'');

  end

end
