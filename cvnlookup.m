function varargout = cvnlookup(FSID,view_number,data,clim0,cmap0,thresh0,Lookup,wantfig,extraopts,surfsuffix)

% function [rawimg,Lookup,rgbimg,himg,hmapfig] = cvnlookup(FSID,view_number,data,clim0,cmap0,thresh0,Lookup,wantfig,extraopts,surfsuffix)
%
% <FSID> (optional) is the FreeSurfer subject ID, e.g. 'subj01'. Default: 'fsaverage'.
% <view_number> (optional) is a positive integer with the desired view. Default: 1.
%   Other options are possible (see below).
% <data> (optional) is V x 1 with the data (concatenated across lh and rh hemispheres).
%   can also be a [lh,rh].XXX.mgz file (we will attempt to find both files [lh,rh].XXX.mgz).
%   Default is [] which means to generate randn values. Note that if we get only one hemisphere,
%   we may be able to proceed by filling NaNs in the other hemisphere and issuing a warning.
% <clim0> (optional) is [MIN MAX] for the colormap range. Default: 1st and 99th percentile.
% <cmap0> (optional) is the desired colormap. Default: jet(256).
% <thresh0> (optional) is threshold value. Default is [] which means no thresholding.
%   if specified as an imaginary number X*j, we specify the 'absthreshold' option with X.
% <Lookup> (optional) is the Lookup to re-use.
% <wantfig> (optional) is whether to show a figure. Default: 1.
% <extraopts> (optional) is a cell vector of extra options to cvnlookupimages.m. Default: {}.
% <surfsuffix> (optional) is 'orig' or 'DENSETRUNCpt'. Default is 'orig' which means
%   standard non-dense FreeSurfer surfaces.
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
% example 4:
% a = zeros(2*163842,1);
% a(1:50000) = 1;
% b = zeros(2*163842,1);
% b(10000:20000) = 1;
% cvnlookup('fsaverage',13,[],[-3 3],[],5,[],[],{'roimask' {a==1 b==1} 'roicolor' {[1 0 0] [0 0 1]}});
%
% example 5 (assumes that *.corticalsulc.mgz is available)
% cvnlookup('fsaverage',13,randn(163842*2,1),[],[],10,[],[],{'roiname','corticalsulc','roicolor','r','drawroinames',true});
%
% some useful options might include (see cvnlookupimages.m for details):
% 'rgbnan',1 (this sets background to white)
% 'roiname',{'Kastner*' 'flocgeneral'},'roicolor',{'r' 'b'},'drawroinames',true, ...
% 'roimask',{rand(lh+rh,1)>.3},'roicolor',{'r'},'roiwidth',1,'drawroinames',{'ROI'}, ...
% 'hemibordercolor',[1 1 1]   (set the vertical line that separates hemispheres to white)
% 'scalebarcolor','k'   (make the scale bar black)
% 'threshold',1     (threshold the data at 1)
% 'background','sulc'    (use "sulc" as the underlay)
% 'overlayalpha',datavals > tthresh    (only allow values passing the threshold to be shown)
% 'absthreshold',2     (both positive and negative values exceeding the threshold are shown)
%
% View numbers:
%      VIEWPOINT        SURFACE            HEMIFLIP  RES  FSAVG      XYEXTENT 
%  1 {'occip'           'sphere'                   0 1000    0         [1 1]} ...
%  2 {'occip'           'inflated'                 0  500    0         [1 1]} ...
%  3 {'ventral'         'inflated'                 1  500    0         [1 1]} ...
%  4 {'parietal'        'inflated'                 0  500    0         [1 1]} ...
%  5 {'medial'          'inflated'                 0  500    0         [1 1]} ...
%  6 {'lateral'         'inflated'                 0  500    0         [1 1]} ...
%  7 {'medial-ventral'  'inflated'                 0  500    0         [1 1]} ...
%  8 {'ventral'         'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
%  9 {''                'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
% 10 {''                'full.flat.patch.3d'       0 1500    1         [290 0]} ...   % 5.17 pixels per mm
% 11 {'ventral-lateral' 'inflated'                 1 1000    0         [1 1]} ...
% 12 {'lateral-auditory' 'inflated'                0 1000    0         [1 1]} ...
% 13 {''                'full.flat.patch.3d'       0 1500    0         []} ...
% 14 {'superior'        'inflated'                 0  500    0         [1 1]} ...
% 15 {'frontal'         'inflated'                 0  500    0         [1 1]} ...
%    OR
% 'occipA1' through 'occipA8' where A can also be B or C
%    OR
% a fully specified cell vector with the options listed above. note that VIEWPOINT 
%   can take the format {viewpt viewhemis}. for example, consider the following:
%   cvnlookup('subj01',{ {{[0 0 110] [0 0 -110]} {'lh' 'rh'}} 'full.flat.patch.3d' 0 1500 0 []}, ...
%             [],[],[],10,[],[],{'savelookup',false});
%
% history:
% - 2022/06/25 - no longer default to rgbnan 0.5 (allow cvnlookupimages.m to set default)
% - 2022/02/24 - ensure that [] for threshold doesn't specify a 'threshold' option.
% - 2020/05/09 - add <hmapfig> output; minor fsaverage-related fix
% - 2020/03/30 - add <surfsuffix> input

% Internal notes:
% - special case of <wantfig> is 2 which means create an invisible figure.

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
      data = cvnloadmgz(data);
    else
      data = [];
    end
  end
  if ischar(data) && exist(data,'file')
  else
    if ~isempty(data) && ischar(data)
      data = evalin('base',data);
    end
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
if ~exist('surfsuffix','var') || isempty(surfsuffix)
  surfsuffix = 'orig';  % default is standard non-dense surfaces
end

% define some views. inherited from cvnvisualizeanatomicalresults.m:
allviews = { ...
  {'occip'           'sphere'                   0 1000    0         [1 1]} ...
  {'occip'           'inflated'                 0  500    0         [1 1]} ...
  {'ventral'         'inflated'                 1  500    0         [1 1]} ...
  {'parietal'        'inflated'                 0  500    0         [1 1]} ...
  {'medial'          'inflated'                 0  500    0         [1 1]} ...
  {'lateral'         'inflated'                 0  500    0         [1 1]} ...
  {'medial-ventral'  'inflated'                 0  500    0         [1 1]} ...
  {'ventral'         'gVTC.flat.patch.3d'       1 2000    0         [160 0]} ...   % 12.5 pixels per mm
  {''                'gEVC.flat.patch.3d'       0 1500    0         [120 0]} ...   % 12.5 pixels per mm
  {''                'full.flat.patch.3d'       0 1500    1         [290 0]} ...   % 5.17 pixels per mm
  {'ventral-lateral' 'inflated'                 1 1000    0         [1 1]} ...
  {'lateral-auditory' 'inflated'                0 1000    0         [1 1]} ...
  {''                'full.flat.patch.3d'       0 1500    0         []} ...
  {'superior'        'inflated'                 0  500    0         [1 1]} ...
  {'frontal'         'inflated'                 0  500    0         [1 1]} ...
};

% set information
hemis = {'lh', 'rh'};           % hemisphere (lh, rh, both)

% load view parameters
if isnumeric(view_number)
  view = allviews{view_number};   % view
  viewname = view{1};             % ventral, occip, etc.
  surftype = view{2};             % inflated, sphere, etc.
  hemiflip = view{3};             % flip hemispheres?
  imageres = view{4};             % resolution
  fsaverage0 = view{5};           % want to map to fsaverage?
  xyextent = view{6};             % xy extent to show
elseif ischar(view_number)
  viewname = view_number;
  surftype = 'sphere';
  hemiflip = 0;
  imageres = 1000;
  fsaverage0 = 0;
  xyextent = [1 1];
else
  viewname = view_number{1};
  surftype = view_number{2};
  hemiflip = view_number{3};
  imageres = view_number{4};
  fsaverage0 = view_number{5};
  xyextent = view_number{6};
end
if fsaverage0
  assert(isequal(surfsuffix,'orig'),'only orig surface data can be put onto fsaverage');
  surfsuffixB = 'fsaverage';     % set to fsaverage non-dense surface
else
  surfsuffixB = surfsuffix;
end

%% Load data

% deal with valstruct data
valstruct = valstruct_create(FSID,surfsuffix);
if isempty(data)
  valstruct.data = randn(size(valstruct.data));
else
  if ~isequal(size(valstruct.data),size(data))
    if valstruct.numlh == length(data)
      warning('<data> appears to have only the LH data. proceeding using NaNs for the RH data.')
      valstruct.data(:) = NaN;
      valstruct.data(1:valstruct.numlh) = data;
    elseif valstruct.numrh == length(data)
      warning('<data> appears to have only the RH data. proceeding using NaNs for the LH data.')
      valstruct.data(:) = NaN;
      valstruct.data(valstruct.numlh+1:end) = data;
    else
      error('<data> does not have the correct dimensions');
    end
  else
    valstruct.data = data;
  end
end

% deal with color range
if isempty(clim0)
  clim0 = prctile(valstruct.data(:),[1 99]);
end

% call predefined viewpoint for lookup
if iscell(viewname)
  viewpt = viewname{1};
  viewhemis = viewname{2};
else
  [viewpt,~,viewhemis] = cvnlookupviewpoint(FSID,hemis,viewname,surftype);
end

%% Call cvnlookupimages

% generate image
if ~isempty(thresh0)
  if isreal(thresh0)
    threshopt = {'threshold',thresh0};
  else
    threshopt = {'absthreshold',imag(thresh0)};
  end
else
  threshopt = {};
end
[rawimg,Lookup,rgbimg] = cvnlookupimages(FSID,valstruct,viewhemis,viewpt,Lookup,...
                'surftype',surftype,'surfsuffix',surfsuffixB,'xyextent',xyextent,...
                'imageres',imageres, ...                                    %'text',upper(viewhemis),   'rgbnan',0.5
                'clim',clim0,'colormap',cmap0,threshopt{:},extraopts{:});
    % lookup_roi_params={'roiname',atlas_def,'roicolor',[1 1 1],'drawroinames',true};
    % 'threshold',1
    % 'background','sulc'
    % 'overlayalpha'
    % 'absthreshold',2
    % 'roiname',{'Kastner*' 'flocgeneral'},'roicolor',{'r' 'b'},'drawroinames',true
    % 'roiname','Kastner*','roicolor',[1 1 1],'drawroinames',true
    % 'savelookup',false,

% visualize rgbimg
switch wantfig
case 1
  hmapfig = figure; himg = imshow(rgbimg);
case 2
  hmapfig = figure('Visible','off'); himg = imshow(rgbimg);
otherwise
  hmapfig = []; himg = [];
end

% deal with output
if nargout == 0
  assignin('base','rawimg',rawimg);
  assignin('base','Lookup',Lookup);
  assignin('base','rgbimg',rgbimg);
  assignin('base','himg',himg);
  assignin('base','hmapfig',hmapfig);
else
  varargout{1} = rawimg;
  varargout{2} = Lookup;
  varargout{3} = rgbimg;
  varargout{4} = himg;
  varargout{5} = hmapfig;
end
