function cvndefinemcmask(datadir,ppdir,wantforce)

% function cvndefinemcmask(datadir,ppdir,wantforce)
% 
% <datadir> is the directory with the raw data
% <ppdir> is the directory with the preprocessed data
% <wantforce> (optional) is 0/1 indicating whether to overwrite an existing mcmask file.
%   Default: 0.
%
% Create and save the mcmask.

% inputs
if ~exist('wantforce','var') || isempty(wantforce)
  wantforce = 0;
end

% prep
mkdirquiet(ppdir);

% if we need to create the mcmask
if ~exist([ppdir '/mcmask.mat'],'file') || wantforce

  % try to find any and all fMRI dicom directories
  epifilenames = matchfiles({[datadir '/dicom/*fMRI*'] ...
                             [datadir '/dicom/*bold*'] ...
                             [datadir '/dicom/*GE_continuous*']...
                             [datadir '/dicom/*continuous*']...
                             [datadir '/dicom/*sparse*']});

  % load the first one
  epinumonly = [];
  epidesiredinplanesize = [];
  epiphasemode = [];
  dformat = [];
  [tempepi] = dicomloaddir(epifilenames(1),[],epinumonly,epidesiredinplanesize,epiphasemode,dformat);

  % define the ellipse on the first volume
  [~,tempmn,tempsd] = defineellipse3d(tempepi{1}(:,:,:,1),[],0);
  mcmask = {tempmn tempsd};

  % save it
  save([ppdir '/mcmask.mat'],'mcmask');

end
