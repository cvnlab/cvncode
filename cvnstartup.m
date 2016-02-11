function cvnstartup(resetpath)
% cvnstartup
% cvnstartup reset
%
% set default settings and matlab paths, including:
%   cvn code directories
%   knkutils
%   fsl and freesurfer toolboxes
%
% Optional input:
% if resetpath='reset', reset matlab default path before adding cvn
% if resetpath='' (default), just add cvn paths to existing paths


if(~exist('resetpath','var') || isempty(resetpath))
    resetpath='';
end
if(strcmpi(resetpath,'reset'))
    restoredefaultpath;
end

%% user-specific paths are hardcoded here
codehome=[getenv('HOME') '/Source'];
cvnroot=[codehome '/cvncode'];
knkroot=[codehome '/knkutils'];


fsldir=getenv('FSLDIR');
if(isempty(fsldir) || ~exist(fsldir,'dir'))
  fsldir='/usr/local/fsl';
end
freesurfdir=getenv('FREESURFER_HOME');
if(isempty(freesurfdir) || ~exist(freesurfdir,'dir'))
  freesurfdir='/Applications/freesurfer';
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define path (top is highest priority)!

pth = '';
pth = [pth cvnroot ':'];
pth = [pth genpath([cvnroot '/utilities'])];
pth = [pth genpath([cvnroot '/kjutils'])];
pth = [pth genpath(knkroot)];
pth = [pth fsldir '/etc/matlab:'];
pth = [pth freesurfdir '/matlab:'];
pth = [pth freesurfdir '/fsfast/toolbox:'];

% clean up path
bad = {'/.' '.svn' '.git' 'DNBdata' 'DNBresults' '@'};

pth = regexp(pth,'(.+?):','match');
badpat=strjoin(regexptranslate('escape',bad),'|');
pth=pth(cellfun(@isempty,regexp(pth,badpat,'match')));

% add to path
pth = cat(2,pth{:});
addpath(pth);

%% set other defaults
set(0,'DefaultFigureInvertHardCopy','off');
set(0,'DefaultFigurePaperPositionMode','auto');
set(0,'DefaultFigureColor',[1 1 1]);
set(0,'DefaultFigureColormap',gray(64));
set(0,'DefaultLineLineWidth',1);
set(0,'DefaultLineMarkerSize',9);
set(0,'DefaultTextFontSize',10);
set(0,'DefaultAxesFontSize',10);
set(0,'DefaultTextFontName','Helvetica');
set(0,'DefaultAxesFontName','Helvetica');
%set(0,'DefaultFigureToolbar','none');
%set(0,'DefaultFigureMenuBar','none');
%fprintf(1,'default font size: 10\n');

% set rand state
rand('state',sum(100*clock));
randn('state',sum(100*clock));

% set format
format long g;