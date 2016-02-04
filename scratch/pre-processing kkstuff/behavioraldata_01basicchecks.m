%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% BASIC CHECKS [90,91,92,93,94,95,96,97,98,99,101,102,103,104]
%                                           [111,112,113,114,115,116,118]
% NOTE: keybuttons added and only ran for 101,102,103,104,etc.

% setup
fmrisetup(104);

% init
keytimes = {};
badtimes = {};
keybuttons = {};

% define
figuredir = sprintf('~/inout/%d/behavioral',fmrisetupnum);
badkey = 't';
deltatime = 0.05;        %% IN THE SKYRA SETUP, WE ONLY GET ONE ANYWAY
deltatimeBAD = 0.25;

% process each file
runfilesmatch = matchfiles(stimulusfiles);
strs = {};
for p=1:length(runfilesmatch)

  a = load(runfilesmatch{p});

  % run ptviewmoviecheck
  [keytimes{p},badtimes{p},keybuttons{p}] = ptviewmoviecheck(a.timeframes,a.timekeys,deltatime,badkey,deltatimeBAD,1);
  figurewrite(sprintf('timekeys%02d',p),[],[],figuredir);
  figurewrite(sprintf('timeframes%02d',p),[],[],figuredir);

  % record
  strs{p,1} = sprintf('name of file: %s\n',runfilesmatch{p});
  strs{p,2} = sprintf('first entry: %s\n',cell2str(a.timekeys(2,:)));
  strs{p,3} = sprintf('num timeframes: %d\n',length(a.timeframes));
  strs{p,4} = sprintf('timeframes last - first: %.5f\n',a.timeframes(end)-a.timeframes(1));
  strs{p,5} = sprintf('total dur: %.3f\n',length(a.timeframes)*mean(diff(a.timeframes)));
  strs{p,6} = sprintf('num triggers: %d\n',length(badtimes{p}));

end

% write text file
fid = fopen([figuredir '/info.txt'],'w');
for p=1:size(strs,2)
  for q=1:length(runfilesmatch)
    fprintf(fid,strs{q,p});
  end
end
fclose(fid);

% save button presses
save([outputdir '/behavioraltimes.mat'],'keytimes','badtimes','keybuttons');

% download figures
