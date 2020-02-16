% cvndefinerois
%
% This is a script that handles the drawing of a ROI file that
% consists of integers from 0 through N.
%
% The basic usage is something like this:
%
% % define
% subjid = 'subj01';   % which subject
% cmap   = jet(256);   % colormap for ROIs
% rng    = [0 3];      % should be [0 N] where N is the max ROI index
% roilabels = {'V1' 'V2' 'V3'};  % 1 x N cell vector of strings
% mgznames = {'prfangle' 'prfangle' 'prfeccentricity'};           % quantities of interest in label/?h.MGZNAME.mgz (1 x Q)
% crngs = {[0 360]          [0 360]             [0 12]};          % ranges for the quantities (1 x Q)
% cmaps = {cmfanglecmapRH   cmfanglecmap        cmfecccmap(4)};   % colormaps for the quantities (1 x Q)
% roivals = [];                                                   % start with a blank slate
%
% % do it
% cvndefinerois;
%
% After you are done, you should save out the ROI information
% (which lives in the workspace variable <roivals>) into
% files called lh.NAME.mgz and rh.NAME.mgz.
%
% Note that there are some alternative formats for the inputs:
% - <roilabels> can be [], in which we default to simple integer labels.
% - <mgznames> can be a Q x 2 cell with the quantities of interest like this:
%     {[LHx1] [RHx1]
%      [LHx1] [RHx1]
%      ...    ...   }
% - <roivals> can be V x 1 with initial values for the ROI labels. For example:
%     roivals = cvnloadmgz(sprintf('%s/fsaverage/label/?h.testroi.mgz',cvnpath('freesurfer')));
% - If <roivals> has only LH or RH vertices, we try to automatically detect this
%   and compensate accordingly.

%% %%%%% SETUP

% prep
hemis = {'lh' 'rh'};

% calc
fsdir0 = sprintf('%s/%s/',cvnpath('freesurfer'),subjid);  % subject FS directory

% inputs
if isempty(roilabels)
  roilabels = mat2cellstr(1:rng(2));
end

% load data
if ischar(mgznames{1,1})
  alldata = {};
  for mm=1:length(mgznames)
    for hh=1:length(hemis)
      file0 = sprintf('%s/label/%s.%s.mgz',fsdir0,hemis{hh},mgznames{mm});
      alldata{mm,hh} = cvnloadmgz(file0);
    end
  end
else
  alldata = mgznames;
end
numlh = size(alldata{1,1},1);
numrh = size(alldata{1,2},1);
totalv = numlh+numrh;

% roi data
if ~exist('roivals','var') || isempty(roivals)
  roivals = zeros(totalv,1);
else
  if length(roivals)==totalv
  elseif length(roivals)==numlh
    fprintf('roivals seems to have only LH vertices. we are automatically compensating for this.\n');
    roivals = [roivals; zeros(numrh,1)];
  elseif length(roivals)==numrh
    fprintf('roivals seems to have only RH vertices. we are automatically compensating for this.\n');
    roivals = [zeros(numlh,1); roivals];
  else
    error('roivals does not have the correct number of vertices');
  end
end

% make legend
figureprep([0 0 300 600],1); hold on;
imagesc((1:rng(2))',rng);
set(gca,'YTick',1:rng(2),'YTickLabel',roilabels);
set(gca,'XTick',[]);
colormap(cmap);
axis image tight;
set(gca,'YDir','normal');

%% %%%%%% MAIN LOOP

% init
viewmode = [];      % empty means the user needs to select a view
oldviewmode = [];   % keeps track of the old one
tempfigs = [];      % record of temporary figures

% main GUI loop
while 1

  % allow user to select view mode
  if isempty(viewmode)
    while 1
      str0 = {'1=sphere-occip' '13=subjectflat'};
      masterviewlist = [1 13];
      [selection,ok] = listdlg('ListString',str0,'SelectionMode','single', ...
                               'PromptString','Which view do you want?'); 
      if ok, break;, end
    end
    viewmode = masterviewlist(selection);
  end

  % if this is a new view, we have to generate some maps
  if ~isequal(viewmode,oldviewmode)
    close(tempfigs);
    tempfigs = [];
    Lookup = {}; himgs = {};
    for zz=1:length(mgznames)
      [~,Lookup{zz},~,himgs{zz}] = cvnlookup(subjid,viewmode,cat(1,alldata{zz,:}),crngs{zz},cmaps{zz},[],[],2);
      tempfigs(end+1) = get(get(himgs{zz},'Parent'),'Parent');
    end
    oldviewmode = viewmode;
  end

  % draw the main ROI image
  [rawimg0,Lookup0,rgbimg0,himg0] = cvnlookup(subjid,viewmode,roivals,rng,cmap,0.5,[],[]); 
  curfig = get(get(himg0,'Parent'),'Parent');

  % ask the user what to do
  while 1

    % first, allow the user to toggle the maps and think about what to do
    figure(curfig);  % make sure this exists and is on top
%    pause(1);  % some delay is necessary in order to make sure the main ROI figure is created
    fprintf('Toggle maps using number keys. Press RETURN in window when ready to proceed.\n');
    drawroipoly([{himg0} himgs],Lookup0,[],1);
    
    % after the user presses RETURN, we are here and ready to proceed
    str0 = {'Draw' 'Draw-safe (only unlabeled)' 'Erase' 'Erase-safe (only from selected)' 'Clear' 'Switch View' 'Save' 'Quit'};
    [selection,ok] = listdlg('ListString',str0,'SelectionMode','single', ...
                             'PromptString','What do you want to do?'); 
    if ok, break;, end
  end
  whmode = selection;
  
  % we may need to ask the user more stuff
  if ismember(selection,[1 2])
    while 1
      [selection,ok] = listdlg('ListString',roilabels,'SelectionMode','single', ...
                               'PromptString',sprintf('%s -- draw on which ROI?',str0{whmode})); 
      if ok, break;, end
    end
    roiix = selection;  % only 1
  elseif ismember(selection,[4 5])
    while 1
      [selection,ok] = listdlg('ListString',roilabels,'SelectionMode','multiple', ...
                               'PromptString',sprintf('%s -- which ROI(s) are being erased?',str0{whmode}));
      if ok, break;, end
    end
    roiix = selection;  % might be 1 or more
  end
  
  % if user wants to draw, let them
  if ismember(whmode,1:4)
    Rmask = drawroipoly([{himg0} himgs],Lookup0);
  end

  % handle the request
  switch whmode
  case 1
    roivals = roivals.*(1-Rmask) + roiix*Rmask;  % assign all selected vertices to roiix
  case 2
    roivals(roivals==0 & Rmask==1) = roiix;      % non-drawn vertices that are selected become roiix
  case 3
    roivals(Rmask==1) = 0;                       % selected vertices get reset to 0
  case 4
    roivals(ismember(roivals,roiix) & Rmask==1) = 0;  % vertices that are in roiix and selected get reset to 0
  case 5
    close(curfig);   % close just to keep things tidy (and more similar to 1-4)
    roivals(ismember(roivals,roiix)) = 0;        % all roiix are reset to 0
  case 6
    close(curfig);   % close just to keep things tidy (and more similar to 1-4)
    viewmode = [];
    continue;
  case 7
    % get filename from user and try to save
    while 1
      [savefilename,savepathname] = uiputfile('lh.testroi.mgz','Save ROI labels');
      if isequal(savefilename,0) || isequal(savepathname,0)  % if user just canceled, do nothing
        fprintf('No file saved.\n');
        break;
      end
      if ~ismember(savefilename(1:2),hemis)
        fprintf('Error: Filename must start with lh or rh.\n');
        break;
      end
      if isequal(savefilename(1:2),'lh')
        nsd_savemgz(roivals(1:numlh),fullfile(savepathname,savefilename),fsdir0);
      else
        nsd_savemgz(roivals(numlh+1:end),fullfile(savepathname,savefilename),fsdir0);
      end
      fprintf('File %s saved.\n',savefilename);
      break;
    end
  case 8
    break;  % quit!
  end

end

%%%%%

% notes
% - do we need to handle holes?
