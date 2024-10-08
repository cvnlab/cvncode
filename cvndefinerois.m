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
% rng    = [0 3];      % should be [0 N] where N>=1 is the max ROI index
% roilabels = {'V1' 'V2' 'V3'};  % 1 x N cell vector of strings
% mgznames = {'prfangle' 'prfangle' 'prfeccentricity'};           % quantities of interest in label/?h.MGZNAME.mgz (1 x Q)
% crngs = {[0 360]          [0 360]             [0 12]};          % ranges for the quantities (1 x Q)
% cmaps = {cmfanglecmapRH   cmfanglecmap        cmfecccmap(4)};   % colormaps for the quantities (1 x Q)
% threshs = {[] [] []};                                           % thresholds for the quantities (1 x Q)
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
% - <mgznames> can have elements that are like {[LHx1] [RHx1]} instead of a string.
% - <mgznames> can be empty.
% - <roivals> can be V x 1 with initial values for the ROI labels. For example:
%     roivals = cvnloadmgz(sprintf('%s/fsaverage/label/?h.testroi.mgz',cvnpath('freesurfer')));
% - If <roivals> has only LH or RH vertices, we try to automatically detect this
%   and compensate accordingly.
%
% history:
% - 2020/05/09 - add a few new views
% - 2020/03/19 - the format for <mgznames> has changed!!
% - 2020/03/05 - add <threshs> input

% wishlist?:
% - clear and merge only on one hemi?
% - speckles and holes, think about this
% - allow "cancel"?
% - allow "undo"?

%% %%%%% SETUP

% prep
hemis = {'lh' 'rh'};
listsize = [300 300];
listsize2 = [800 300];

% calc
fsdir0 = sprintf('%s/%s/',cvnpath('freesurfer'),subjid);  % subject FS directory

% inputs
if isempty(roilabels)
  roilabels = mat2cellstr(1:rng(2));
end
if ~exist('threshs','var') || isempty(threshs)
  threshs = cell(1,length(crngs));
end

% load curvature
curv = cvnreadsurfacemetric(subjid,[],'curv',[],'orig');

% load data
alldata = {};
if ~isempty(mgznames)
  for pp=1:length(mgznames)
    if ischar(mgznames{pp})
      for hh=1:length(hemis)
        file0 = sprintf('%s/label/%s.%s.mgz',fsdir0,hemis{hh},mgznames{pp});
        alldata{pp,hh} = cvnloadmgz(file0);
      end
    else
      alldata{pp,1} = mgznames{pp}{1};
      alldata{pp,2} = mgznames{pp}{2};
    end
  end
end
numlh = curv.numlh;
numrh = curv.numrh;
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

%% %%%%%% MAIN LOOP

% init
viewmode = [];      % empty means the user needs to select a view
oldviewmode = [];   % keeps track of the old one
tempfigs = [];      % record of temporary figures
wantlegend = 1;     % do we want to create the legend window?

% main GUI loop
while 1

  % make legend
  if wantlegend
    curlegend = figureprep([0 0 300 600],1); hold on;
    imagesc((1:rng(2))',rng);
    set(gca,'YTick',1:rng(2),'YTickLabel',roilabels);
    set(gca,'XTick',[]);
    colormap(cmap);
    axis image tight;
    set(gca,'YDir','normal');
    wantlegend = 0;
  end

  % allow user to select view mode
  if isempty(viewmode)
    while 1
      str0 = {'1=sphere-occip' ...
              '2=inflated-occip' ...
              '3=inflated-ventral' ...
              '4=inflated-parietal' ...
              '5=inflated-medial' ...
              '6=inflated-lateral' ...
              '7=inflated-medial-ventral' ...
              '8=gVTC' ...
              '9=gEVC' ...
              '10=fsaverage-full-flat' ...
              '11=inflated-ventral-lateral' ...
              '12=inflated-lateral-auditory' ...
              '13=full-flat' ...
              '14=inflated-superior' ...
              '15=inflated-frontal' ...
              'occipA2' ...
              'occipA8' ...
              'occipC2' ...
              'occipA4' ...
              'occipC3' ...
              'occipB3'};
      masterviewlist = {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 'occipA2' 'occipA8' 'occipC2' 'occipA4' 'occipC3' 'occipB3'};
      [selection,ok] = listdlg('ListSize',listsize,'ListString',str0,'SelectionMode','single', ...
                               'PromptString','Which view do you want?'); 
      if ok, break;, end
    end
    viewmode = masterviewlist{selection};
  end

  % if this is a new view, we have to generate some maps
  if ~isequal(viewmode,oldviewmode)
    xlimOLD = [];
    ylimOLD = [];
    figposOLD = [];
    close(tempfigs);
    tempfigs = [];
    [rawimg1,Lookup1,rgbimg1,himg1] = cvnlookup(subjid,viewmode,double(curv.data<0),[-1 2],gray(256),[],[],2);
    tempfigs(end+1) = get(get(himg1,'Parent'),'Parent');
    Lookup = {}; himgs = {};
    for zz=1:size(alldata,1)
      [~,Lookup{zz},~,himgs{zz}] = cvnlookup(subjid,viewmode,cat(1,alldata{zz,:}),crngs{zz},cmaps{zz},threshs{zz},[],2);
      tempfigs(end+1) = get(get(himgs{zz},'Parent'),'Parent');
    end
    oldviewmode = viewmode;
  end

  % draw the main ROI image
  [rawimg0,Lookup0,rgbimg0,himg0] = cvnlookup(subjid,viewmode,roivals,rng,cmap,0.5,[],[]); 
  curfig = get(get(himg0,'Parent'),'Parent');
  if ~isempty(xlimOLD)
    set(get(curfig,'CurrentAxes'),'XLim',xlimOLD);
    set(get(curfig,'CurrentAxes'),'YLim',ylimOLD);
    set(curfig,'Position',figposOLD);
  end

  % ask the user what to do
  while 1

    % first, allow the user to toggle the maps and think about what to do
    figure(curfig);  % make sure this exists and is on top
%    pause(1);  % some delay is necessary in order to make sure the main ROI figure is created
    fprintf('Toggle maps using number keys. Press RETURN in window when ready to proceed.\n');
    [~,~,~,xlimOLD,ylimOLD,figposOLD] = drawroipoly([{himg0 himg1} himgs],Lookup0,[],1);
    
    % after the user presses RETURN, we are here and ready to proceed
    str0 = {'Draw' 'Draw-safe (only unlabeled)' 'Just-draw' 'Erase' 'Erase-safe (only from selected)' 'Clear' 'Add New ROI' 'Rename ROI' 'Delete ROIs' 'Merge ROIs' 'Split ROI' 'Reorder ROIs' 'Change Colormap' 'Switch View' 'Save' 'Quit'};
    [selection,ok] = listdlg('ListSize',listsize,'ListString',str0,'SelectionMode','single', ...
                             'PromptString','What do you want to do?'); 
    if ok, break;, end
  end
  whmode = selection;
  
  % we may need to ask the user more stuff
  if ismember(whmode,[1 2])
    while 1
      [selection,ok] = listdlg('ListSize',listsize,'ListString',roilabels,'SelectionMode','single', ...
                               'PromptString',sprintf('%s -- draw on which ROI?',str0{whmode})); 
      if ok, break;, end
    end
    roiix = selection;  % only 1
  elseif ismember(whmode,[5 6])
    while 1
      [selection,ok] = listdlg('ListSize',listsize,'ListString',roilabels,'SelectionMode','multiple', ...
                               'PromptString',sprintf('%s -- which ROI(s) are being erased?',str0{whmode}));
      if ok, break;, end
    end
    roiix = selection;  % might be 1 or more
  elseif whmode==11
    while 1
      [selection,ok] = listdlg('ListSize',listsize,'ListString',roilabels,'SelectionMode','single', ...
                               'PromptString',sprintf('%s -- which ROI do you want to split?',str0{whmode}));
      if ok, break;, end
    end
    roiix = selection;  % only 1
  end
  
  % if user wants to draw, let them
  if ismember(whmode,[1:5 11])
    [Rmask,~,~,xlimOLD,ylimOLD,figposOLD] = drawroipoly([{himg0 himg1} himgs],Lookup0);
  end

  % handle the request
  switch whmode
  case 1
    roivals = roivals.*(1-Rmask) + roiix*Rmask;  % assign all selected vertices to roiix
  case 2
    roivals(roivals==0 & Rmask==1) = roiix;      % non-drawn vertices that are selected become roiix
  case 3
    roiix = mode(filterout(roivals(logical(Rmask)),0));
    if isempty(roiix) || isnan(roiix)
      roiix = 1;
    end
    roivals = roivals.*(1-Rmask) + roiix*Rmask;  % assign all selected vertices to roiix
  case 4
    roivals(Rmask==1) = 0;                       % selected vertices get reset to 0
  case 5
    roivals(ismember(roivals,roiix) & Rmask==1) = 0;  % vertices that are in roiix and selected get reset to 0
  case 6
    roivals(ismember(roivals,roiix)) = 0;        % all roiix are reset to 0
    close(curfig);
  case 7  % Add New ROI
    while 1
      temp = inputdlg('Name this ROI:');
      if ~isempty(temp{1})
        break;
      end
    end
    roilabels{end+1} = temp{1};
    rng(2) = rng(2) + 1;
    close(curlegend);
    wantlegend = 1;
    close(curfig);
  case 8  % Rename ROI
    while 1
      [selection,ok] = listdlg('ListSize',listsize,'ListString',roilabels,'SelectionMode','single', ...
                               'PromptString','Rename which ROI?');
      if ok, break;, end
    end
    while 1
      temp = inputdlg('What is the new name?','',1,{roilabels{selection}});
      if ~isempty(temp{1})
        break;
      end
    end
    roilabels{selection} = temp{1};
    close(curlegend);
    wantlegend = 1;
    close(curfig);
  case 9  % Delete ROIs
    while 1
      [selection,ok] = listdlg('ListSize',listsize,'ListString',roilabels,'SelectionMode','multiple', ...
                               'PromptString','Delete which ROI(s)?');
      if ok, break;, end
    end
    for pp=fliplr(selection)  % need to do from the end
      todelete = roivals==pp;
      roivals(roivals>pp) = roivals(roivals>pp) - 1;
      roivals(todelete) = 0;
      roilabels(pp) = [];
      rng(2) = rng(2) - 1;
    end
    if rng(2)==0  % need at least one ROI
      roilabels = {'label1'};
      rng = [0 1];
    end
    close(curlegend);
    wantlegend = 1;
    close(curfig);
  case 10   % Merge ROIs
    while 1
      [selection,ok] = listdlg('ListSize',listsize,'ListString',roilabels,'SelectionMode','multiple', ...
                               'PromptString',sprintf('%s -- which ROIs would you like to merge?',str0{whmode}));
      if ok, break;, end
    end
    temp = ismember(roivals,selection);
    for pp=fliplr(selection(2:end))  % need to do from the end
      todelete = roivals==pp;
      roivals(roivals>pp) = roivals(roivals>pp) - 1;
      roivals(todelete) = 0;
      roilabels(pp) = [];
      rng(2) = rng(2) - 1;
    end
    roivals(temp) = selection(1);
    close(curlegend);
    wantlegend = 1;
    close(curfig);
  case 11  % Split ROI
    while 1
      temp = inputdlg('Name this ROI:');
      if ~isempty(temp{1})
        break;
      end
    end
    roilabels{end+1} = temp{1};
    rng(2) = rng(2) + 1;
    roivals(roivals==roiix & Rmask==1) = rng(2);
    close(curlegend);
    wantlegend = 1;
  case 12  % Reorder ROIs
    oldorder = 1:length(roilabels);
    neworder = [];
    while ~isempty(oldorder)
      while 1
        temp = cellfun(@(x) [x ','],roilabels(neworder),'UniformOutput',0);
        temp = cat(2,temp{:});
        [selection,ok] = listdlg('ListSize',listsize2,'ListString',roilabels(oldorder),'SelectionMode','single', ...
                                 'PromptString',sprintf('Which ROI is next? %s',temp));
        if ok, break;, end
      end
      neworder = [neworder oldorder(selection)];
      oldorder = setdiff(oldorder,oldorder(selection));
    end
    temp = roivals==0;
    roivals(temp) = 1;
    roivals = calcposition(neworder,roivals);
    roivals(temp) = 0;
    roivals = roivals(:);
    roilabels = roilabels(neworder);
    close(curlegend);
    wantlegend = 1;
    close(curfig);
  case 13  % Change Colormap
    while 1
      temp = inputdlg('Specify new colormap:');
      if ~isempty(temp{1})
        break;
      end
    end
    cmap = eval(temp{1});
    close(curlegend);
    wantlegend = 1;
    close(curfig);
  case 14  % Switch View
    viewmode = [];
    close(curfig);
  case 15  % Save
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
      fprintf('Here are your roilabels in one format: %s\n\n',cell2str(roilabels));
      fprintf('Here are your roilabels in another format:\n');
      for pp=0:rng(2)
        if pp==0
          fprintf('0 Unknown\n');
        else
          fprintf('%d %s\n',pp,roilabels{pp});
        end
      end
      if isequal(savefilename(1:2),'lh')
        nsd_savemgz(roivals(1:numlh),    fullfile(savepathname,savefilename),fsdir0);
      else
        nsd_savemgz(roivals(numlh+1:end),fullfile(savepathname,savefilename),fsdir0);
      end
      fprintf('File %s saved!\n',savefilename);
      break;
    end
    close(curfig);
  case 16
    break;  % quit!
  end

end

%%%%%

% notes
% - do we need to handle holes?
