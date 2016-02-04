%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SMOOTH LOCALIZER DATA [90,91,92,93,94,111,112,113,114,115,116,118]

% setup
fmrisetup(111);

% define
fwhm = 4;
numiter = 100;

% prepare data
if ismember(fmrisetupnum,[90 91])
  runix = 2:3;
elseif ismember(fmrisetupnum,[111 112 113 114 115 116 118])
  runix = 13:14;
else
  runix = 1:2;
end
datafunB = @() cellfun(@(x) single(loadbinary(x,'int16',[numlh+numrh 0])), ...
                       subscript(matchfiles([datadir '/preprocessVERTICES/run*.nii']),runix),'UniformOutput',0);

% load data
data = feval(datafunB);

  % generate random data
  % for 92 only [EXPERIMENTAL]
  for p=1:length(data)
    ts = generatepinknoise1D(size(data{p},2),[],size(data{p},1),1)';
    ts = bsxfun(@rdivide,ts,std(ts,[],2));
    ts = bsxfun(@plus,mean(data{p},2),bsxfun(@times,ts,std(data{p},[],2)));
    data{p} = single(ts);
  end

% smooth data
for p=1:length(data)
  load(lhmidgray,'weight','nbr');
  data{p}(1:numlh,:)         = (smoothmap(data{p}(1:numlh,:)',        fwhm,numiter,weight,nbr))';
  load(rhmidgray,'weight','nbr');
  data{p}(numlh+(1:numrh),:) = (smoothmap(data{p}(numlh+(1:numrh),:)',fwhm,numiter,weight,nbr))';
end

% save data
save([outputdir '/smoothedlocalizer.mat'],'data');

  % for random case only
  save([outputdir '/smoothedlocalizerRANDOM.mat'],'data');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RUN GLMDENOISE (SPECIAL CASE: YEATMAN LOCALIZER) [90,91,92,93,94,100]
%                                           [111,112,113,114,115,116,118]

  %%%%% NOTE: SHOULD I THINK ABOUT STANDARD CONTRAST E.G. HCPPILOT??

% setup
fmrisetup(111);

% define
whichdata = 1;             % unsmoothed, bootstrap
converttosingle = 0;
bootgroups = [1 1];
numboots = 100;
name0 = 'GLMlocalizer';
  % OR
whichdata = 2;             % smoothed, single-trial
converttosingle = 1;
bootgroups = [];
numboots = 0;
name0 = 'GLMlocalizerSM';
  % USE THIS FOR SPECIAL RANDOM CASE:
  % name0 = 'GLMlocalizerSMRANDOM';

% ONLY FOR SUBJECT 100, USE THIS LINE:
whichdata = 3;

% prepare stimulus
stimulus = loadmulti('~/ext/stimuli.final/preprocessedstimuli/ppstimulus_yeatmeanlocalizer.mat','design');
stimulus = repmat({stimulus(1:tr:end,:)},[1 2]);
assert(isint(tr));

% convert to single-blocks
if converttosingle
  stimulus0 = {};
  for p=1:length(stimulus)
    stimulus0{p} = zeros(168,16+16);
    for pp=1:4
      ix = find(stimulus{p}(:,pp));
      for q=1:length(ix)
        stimulus0{p}(ix(q),(p-1)*16 + (pp-1)*4 + q) = 1;
      end
    end
  end
  stimulus = stimulus0;
  clear stimulus0;
end

        %   datafunB = @() cellfun(@(x) single(getfield(load_untouch_nii(x),'img')), ...
        %                            subscript(matchfiles([datadir '/preprocess/run*.nii']),runix),'UniformOutput',0);
        %   data = feval(datafunB);
% load data
if ismember(fmrisetupnum,[90 91])
  runix = 2:3;
elseif ismember(fmrisetupnum,[111 112 113 114 115 116 118])
  runix = 13:14;
else
  runix = 1:2;
end
switch whichdata
case 1
  datafunB = @() cellfun(@(x) single(loadbinary(x,'int16',[numlh+numrh 0])), ...
                         subscript(matchfiles([datadir '/preprocessVERTICES/run*.nii']),runix),'UniformOutput',0);
  data = feval(datafunB);
case 2
  load([outputdir '/smoothedlocalizer.mat'],'data');
    % USE THIS FOR SPECIAL 92 RANDOM CASE [SKIP THE RESAMPLING]
    % load([outputdir '/smoothedlocalizerRANDOM.mat'],'data');
case 3
  load([outputdir '/subjectaveragedlocalizer.mat'],'data');
end

% deal with resampling
if isequal(fmrisetupnum,92)
  data = tseriesinterp(data,1.994,2.001,ndims(data{1}),168);
end

% do the GLM [ASSUME HRF, NO DENOISING]
stimdur = 16;
results = GLMdenoisedata(stimulus,data,stimdur,tr, ...
                         'assume',[],struct('bootgroups',bootgroups,'numpcstotry',0,'numboots',numboots),[]);  % no figs

% NOPE: download the figures!

confun = @(x,y) (x-y)./(x+y);

% massage the output [WSFO]
if converttosingle

  tval = [];
  snrval = [];
  conindex = [];
  
  wordix = 1:4;
  scrix = 5:8;
  wallix = setdiff(1:16,wordix);
  faceix = 9:12;
  objix = 13:16;
  fallix = setdiff(1:16,faceix);
  cons = {{wordix scrix} {wordix wallix} {faceix objix} {faceix fallix}};
  
  cnt = 1;
  for q=[3 1 2]  % all, test, retest
    for p=1:length(cons)

      xxx = []; yyy = [];
      if bitget(q,1)
        xxx = [xxx cons{p}{1}];
        yyy = [yyy cons{p}{2}];
      end
      if bitget(q,2)
        xxx = [xxx 16+cons{p}{1}];
        yyy = [yyy 16+cons{p}{2}];
      end
      vals1 = results.modelmd{2}(:,xxx)';
      vals2 = results.modelmd{2}(:,yyy)';
      [h,p,ci,stats] = ttest2(vals1,vals2,[],[],'unequal');
      tval(:,cnt) = stats.tstat;
      snrval(:,cnt) = max(abs(mean(vals1,1)),abs(mean(vals2,1))) ./ ...
                      mean(cat(1,std(vals1,[],1)/sqrt(size(vals1,1)),std(vals2,[],1)/sqrt(size(vals2,1))),1);
      conindex(:,cnt) = confun(abs(mean(vals1,1)),abs(mean(vals2,1)));
      cnt = cnt + 1;

    end
  end

  % calc [ADDED THIS IN POST HOC. HOPEFULLY OK.]
  stim = {[1:4 16+(1:4)] [5:8 16+(5:8)] [9:12 16+(9:12)] [13:16 16+(13:16)]};
  mn = []; se = [];
  for p=1:length(stim)
    mn = [mn mean(results.modelmd{2}(:,stim{p}),2)];
    se = [se std(results.modelmd{2}(:,stim{p}),[],2)/sqrt(length(stim{p}))];
  end
  SNRF = max(abs(mn),[],2) ./ mean(se,2);

else
  secommon = sqrt(mean(results.modelse{2}.^2,2));
  tval = [];
  tval(:,1) = (results.modelmd{2}(:,1) - results.modelmd{2}(:,2))./secommon;                % word > scramble
  tval(:,2) = (results.modelmd{2}(:,1) - mean(results.modelmd{2}(:,2:4),2))./secommon;      % word > all
  tval(:,3) = (results.modelmd{2}(:,3) - results.modelmd{2}(:,4))./secommon;                % face > object
  tval(:,4) = (results.modelmd{2}(:,3) - mean(results.modelmd{2}(:,[1 2 4]),2))./secommon;  % face > all
  snrval = [];  % omit
  conindex = [];
  conindex(:,1) = confun(results.modelmd{2}(:,1),results.modelmd{2}(:,2));
  conindex(:,2) = confun(results.modelmd{2}(:,1),mean(results.modelmd{2}(:,2:4),2));
  conindex(:,3) = confun(results.modelmd{2}(:,3),results.modelmd{2}(:,4));
  conindex(:,4) = confun(results.modelmd{2}(:,3),mean(results.modelmd{2}(:,[1 2 4]),2));
  SNRF = [];    % omit
end
results.tval = tval;
results.snrval = snrval;
results.conindex = conindex;
results.SNRF = SNRF;

% save output
save([outputdir '/' name0 '.mat'],'-struct','results','-v7.3');

%%%%%%%%%%%%%%%%%%%%%% EXPORT TO FREESURFER FORMAT [91,92,93,94]
%                      [111,112,113,114,115,116,118]
% - hm, but shouldn't we write out t-values from the localizer as .curv or some fsaverage file??

% setup
fmrisetup(111);

% define
todo = {{'GLMlocalizer.mat' 'locfull'}}

% loop
for zz=1:length(todo)

  % load
  a1 = load([outputdir '/' todo{zz}{1}]);

  % prepare directory
  dir0 = sprintf('/software/freesurfer/subjects/%s/results/%s/',subjectid,todo{zz}{2});
  mkdirquiet(dir0);

  % define
  vars0 = {'word' 'scr' 'face' 'obj' 'wordSE' 'scrSE' 'faceSE' 'objSE' 'R2' 'meanvol'};

  % loop
  for p=1:length(vars0)

    if p<=8
      if p<=4
        vals = a1.modelmd{2}(:,p);
      else
        vals = a1.modelse{2}(:,p-4);
      end
    else
      vals = a1.(vars0{p});
    end

    ix = 1:numlh;
    MRIwrite(struct('vol',vflatten(vals(ix))),sprintf('%s/lh.%s.mgh',dir0,vars0{p}));

    ix = numlh+(1:numrh);
    MRIwrite(struct('vol',vflatten(vals(ix))),sprintf('%s/rh.%s.mgh',dir0,vars0{p}));

  end

end
