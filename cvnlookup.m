function varargout = cvnlookup(FSID,view_number,data,clim0,cmap0,thresh0,Lookup,wantfig,extraopts)

% function [rawimg,Lookup,rgbimg,himg] = cvnlookup(FSID,view_number,data,clim0,cmap0,thresh0,Lookup,wantfig,extraopts)
%
% <FSID> (optional) is the FreeSurfer subject ID, e.g. 'subj01'. Default: 'fsaverage'.
% <view_number> (optional) is a positive integer with the desired view. Default: 1.
% <data> (optional) is V x 1 with the data (concatenated across lh and rh hemispheres).
%   can also be a [lh,rh].XXX.mgz file (we will attempt to find both files [lh,rh].XXX.mgz).
%   Default is [] which means to generate randn values.
% <clim0> (optional) is [MIN MAX] for the colormap range. Default: 1st and 99th percentile.
% <cmap0> (optional) is the desired colormap. Default: jet(256).
% <thresh0> (optional) is threshold value. Default is [] which means no thresholding.
% <Lookup> (optional) is the Lookup to re-use.
% <wantfig> (optional) is whether to show a figure. Default: 1.
% <extraopts> (optional) is a cell vector of extra options to cvnlookupimages.m. Default: {}.
%
% This is a simple wrapper for cvnlookupimages.m that provides basic functionality.
%
% You can call this function with no inputs, and we will prompt the user for inputs.
%
% Note that if no outputs are requested, we will still assign the output variables
%   to the base workspace in case you want them.
%
% Note that the SUBJECTS_DIR environment variable should be set appropriately, e.g.,
%   setenv('SUBJECTS_DIR','/path/to/freesurfer/subjects/');
%
% example 1:
% cvnlookup('fsaverage',1,randn(163842*2,1));
% 
% example 2:
% cvnlookup;
%
% example 3:
% [rawimg,Lookup,rgbimg] = cvnlookup('fsaverage',1,randn(163842*2,1));
% figure; himg = imshow(rgbimg);
% figure; imagesc(rawimg,[-3 3]);
%
% View numbers:
%      VIEWPOINT        SURFACE            HEMIFLIP  RES  FSAVG      XYEXTENT 
%  1 {'occip'          'sphere'                   0 1000    0         [1 1]} ...
%  2 {'occip'          'inflated'                 0  500    0         [1 1]} ...
%  3 {'ventral'        'inflated'                 1  500    0         [1 1]} ...
%  4 {'parietal'       'inflated'                 0  500    0         [1 1]} ...
%  5 {'medial'         'inflated'                 0  500    0         [1 1]} ...
%  6 {'lateral'        'inflated'                 0  500    0         [1 1]} ...
%  7 {'medial-ventral' 'inflated'                 0  500    0         [1 1]} ...
%  8 {'ventral'        'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
%  9 {''               'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
% 10 {''               'full.flat.patch.3d'       0 1500    1         [290 0]} ...   % 5.17 pixels per mm

%% Setup

% deal with inputs
if ~exist('FSID','var')
  wantinteractive = 1;
else
  wantinteractive = 0;
end
if wantinteractive
  FSID = input('FreeSurfer subject ID? (default = fsaverage)\n  --> ','s');
end
if ~exist('FSID','var') || isempty(FSID)
  FSID = 'fsaverage';
end
if wantinteractive
  view_number = input('View number? (default = 1)\n  --> ');
end
if ~exist('view_number','var') || isempty(view_number)
  view_number = 1;
end
if wantinteractive
  data = input('Data? (ENTER will bring up a dialog box)\n  --> ','s');
  if isempty(data)
    [file0,pathname0] = uigetfile('*.mgz','Select .mgz file');
    if ~isequal(file0,0)
      data = fullfile(pathname0,['??.' file0(4:end)]);
    end
  end
  if ischar(data) && exist(data,'file')
  else
    data = eval(data);
  end
end
if ~exist('data','var') || isempty(data)
  data = [];
end
if ischar(data) && ~isempty(data) && exist(data,'file')
  pathname0 = stripfile(data);
  data = stripfile(data,1);
  data = fullfile(pathname0,['??.' data(4:end)]);
  data = cvnloadmgz(data);
end

% deal with more inputs
if wantinteractive
  clim0 = input('Color range? (default = [A B] where A and B are the 1st and 99th percentiles)\n  --> ');
end
if ~exist('clim0','var') || isempty(clim0)
  clim0 = [];
end
if wantinteractive
  cmap0 = input('Color map? (default = jet(256))\n  --> ');
end
if ~exist('cmap0','var') || isempty(cmap0)
  cmap0 = jet(256);
end
if wantinteractive
  thresh0 = input('Threshold? (default = [] which means no thresholding)\n  --> ');
end
if ~exist('thresh0','var') || isempty(thresh0)
  thresh0 = [];
end
if ~exist('Lookup','var') || isempty(Lookup)
  Lookup = [];
end
if ~exist('wantfig','var') || isempty(wantfig)
  wantfig = 1;
end
if ~exist('extraopts','var') || isempty(extraopts)
  extraopts = {};
end

% define some views. inherited from cvnvisualizeanatomicalresults.m:
allviews = { ...
  {'occip'          'sphere'                   0 1000    0         [1 1]} ...
  {'occip'          'inflated'                 0  500    0         [1 1]} ...
  {'ventral'        'inflated'                 1  500    0         [1 1]} ...
  {'parietal'       'inflated'                 0  500    0         [1 1]} ...
  {'medial'         'inflated'                 0  500    0         [1 1]} ...
  {'lateral'        'inflated'                 0  500    0         [1 1]} ...
  {'medial-ventral' 'inflated'                 0  500    0         [1 1]} ...
  {'ventral'        'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
  {''               'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
  {''               'full.flat.patch.3d'       0 1500    1         [290 0]} ...   % 5.17 pixels per mm
};

% set information
hemis = {'lh', 'rh'};           % hemisphere (lh, rh, both)
surfsuffix = 'orig';            % set to standard non-dense surfaces

% load view parameters
view = allviews{view_number};   % view
viewname = view{1};             % ventral, occip, etc.
surftype = view{2};             % inflated, sphere, etc.
hemiflip = view{3};             % flip hemispheres?
imageres = view{4};             % resolution
fsaverage0 = view{5};           % want to map to fsaverage?
xyextent = view{6};             % xy extent to show

%% Load data

% deal with valstruct data
valstruct = valstruct_create(FSID,surfsuffix);
if isempty(data)
  valstruct.data = randn(size(valstruct.data));
else
  if ~isequal(size(valstruct.data),size(data))
    error('<data> does not have the correct dimensions');
  end
  valstruct.data = data;
end

% deal with color range
if isempty(clim0)
  clim0 = prctile(valstruct.data(:),[1 99]);
end

% call predefined viewpoint for lookup
[viewpt,~,viewhemis] = cvnlookupviewpoint(FSID,hemis,viewname,surftype);

%% Call cvnlookupimages

% generate image
[rawimg,Lookup,rgbimg] = cvnlookupimages(FSID,valstruct,viewhemis,viewpt,Lookup,...
                'surftype',surftype,'surfsuffix',surfsuffix,'xyextent',xyextent,...
                'text',upper(viewhemis),'imageres',imageres,'rgbnan',0.5, ...
                'clim',clim0,'colormap',cmap0,'threshold',thresh0,extraopts{:});
    % lookup_roi_params={'roiname',atlas_def,'roicolor',[1 1 1],'drawroinames',true};
    % 'threshold',1
    % 'background','sulc'
    % 'overlayalpha'
    % 'absthreshold',2
    % 'roiname',{'Kastner*' 'flocgeneral'},'roicolor',{'r' 'b'},'drawroinames',true
    % 'roiname','Kastner*','roicolor',[1 1 1],'drawroinames',true

% visualize rgbimg
if wantfig
  figure; himg = imshow(rgbimg);
else
  himg = [];
end

% deal with output
if nargout == 0
  assignin('base','rawimg',rawimg);
  assignin('base','Lookup',Lookup);
  assignin('base','rgbimg',rgbimg);
  assignin('base','himg',himg);
else
  varargout{1} = rawimg;
  varargout{2} = Lookup;
  varargout{3} = rgbimg;
  varargout{4} = himg;
end

