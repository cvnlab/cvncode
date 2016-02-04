function fmrisetup(x)

% function fmrisetup(x)
%
% <x> is the dataset number.
%   28: MP20110920
%   29: MP20110930
%   30: MP20110920b (MP20110920 + MP20110930)
%   31: FP20111019
%   32: FP20111024
%   33: JW20111103
%   34: MP20111108
%   35: JW20111118
%   36: JW20111103b (JW20111103 + JW20111118)
%   37: JW20111229
%   38: KW20120102
%   39: MP20120314
%   40: KW20120808
%   41: KG20120831
%   42: KG20120918
%   43: KG20120924
%   44: KG20120918b
%   45: KW20120927
%   46: KW20121113
%   47: KG20121113
%   48: JW20121212
%   49: MP20121212
%   50: KG20121221
%   51: KG20121113b
%   52: KW20130212
%   53: KW20130315
%   54: KW20130411
%   55: KW20130415
%   56: KW20130411b
%   57: KG20130416
%   58: KG20130421
%   59: KG20130416b
%   60: KK20130423
%   61: KG20130423
%   62: KG20130416c
%   63: KW20130424
%   64: KW20130411c
%   65: KK20130425
%   66: KK20130426
%   67: KK20130423c
%   68: KG20130506
%   69: KG20130416d
%   70: KW20130523
%   71: KG20130527
%   72: MT20130528
%   73: KH20130528
%   74: KK20130605
%   75: KW20130606
%   76: KK20130610
%   77: GT20130611
%   78: AS20130611
%   79: KG20130611
%   80: KG20130702
%   81: KG20130703
%   82: KK20130711
%   83: KW20130714
%   84: PS20130925
%   85: KG20130702b
%   86: KW20130606b
%   87: KK20130610b
%   88: UP20131213
%   89: UP20131221
%   90: 20140428S016
%   91: 20140505S017
%   92: 20140512S018
%   93: 20140602S019
%   94: 20140605S015
%   95: 20140605S018
%   96: 20140608S015
%   97: 20140619S015
%   98: 20140623S017
%   99: 20140707S019
%  100: fsaverage
%  101: 20140721S017
%  102: 20140727S019
%  103: 20140810S018
%  104: 20140814S015
%  105: KW20141031
%  106: KK20141031
%  107: KG20141031
%  108: KW20141101
%  109: KK20141101
%  110: KG20141101
%  111: 20150115S020
%  112: 20150118S021
%  113: 20150122S022
%  114: 20150129S023
%  115: 20150201S024
%  116: 20150202S025
%  117: FAILED
%  118: 20150209S027
%  119: MT20150218
%  120: JG20150225
%  121: RL20150421
%  122: AS20150423
%
% assign various variables to the base workspace.
%
% FOR NEW ROI STUFF, see "code graveyard"
% the variables are as follows:
%%%%%%%% <xyzsize>:   % matrix size (the data are now in a voxel X time matrix, but we want to reconstruc timages of the brain to show figures so the function 'fitprffast' takes the original scan size)
% <maxpolydeg>: % maximum polynomial degree to use for nuisance functions (baseline, trend, ...)
% <maxpcnum>: % maximum number of PCs to try (kendrick found that at least 5 are enough, in general)
% <numinchunk>: % number of voxels to process simultaneously, the bigger the faster, given enough memory on the local machine
% <wantresample>: % cross-validation scheme  % fit all runs except first two, the cross validate the first two, then shift to the next two runs and repeat...
% <datafun>:   % this inline routine loads nifti files, get data out of it, convert to single, creates a cell array of time X voxel
  % squish squeezes the first 3 dimensions later we will get this back into a 4d matrix to show images
  
% input
if ~exist('x','var')
  x = 0;
end

% prep
fprintf('running fmrisetup for dataset %d.\n',x);
fmrisetupnum = x;

% get the variables
switch x

case {28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99  100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 118 119 120 121 122}
  switch x
  case 28
    datadir = '/home/knk/ext/rawdata/MP20110920';  % where the original data live
    outputdir = '/home/knk/ext/datasets/MP20110920';  % where to save analysis results
    pcnum = 5;              % number of PCs to use
    numnicevoxels = 590;    % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.8;         % total size of stimulus in deg
  case 29
    datadir = '/home/knk/ext/rawdata/MP20110930';  % where the original data live
    outputdir = '/home/knk/ext/datasets/MP20110930';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = [];     % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.8;         % total size of stimulus in deg
  case 30
    datadir = '/home/knk/ext/rawdata/MP20110920b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/MP20110920b';  % where to save analysis results
    pcnum = 5;              % number of PCs to use
    numnicevoxels = 1271;   % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.8;         % total size of stimulus in deg
  case 31
    datadir = '/home/knk/ext/rawdata/FP20111019';  % where the original data live
    outputdir = '/home/knk/ext/datasets/FP20111019';  % where to save analysis results
    pcnum = 3;              % number of PCs to use
    numnicevoxels = 2825;   % number of voxels with positive GLM R^2 (initial GLM model)
  case 32
    datadir = '/home/knk/ext/rawdata/FP20111024';  % where the original data live
    outputdir = '/home/knk/ext/datasets/FP20111024';  % where to save analysis results
    pcnum = 3;              % number of PCs to use
    numnicevoxels = 2863;   % number of voxels with positive GLM R^2 (initial GLM model)
  case 33
    datadir = '/home/knk/ext/rawdata/JW20111103';  % where the original data live
    outputdir = '/home/knk/ext/datasets/JW20111103';  % where to save analysis results
    pcnum = 3;              % number of PCs to use
    numnicevoxels = 898;    % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.5;         % total size of stimulus in deg
  case 34
    datadir = '/home/knk/ext/rawdata/MP20111108';  % where the original data live
    outputdir = '/home/knk/ext/datasets/MP20111108';  % where to save analysis results
    pcnum = 4;             % number of PCs to use
    numnicevoxels = 3391;  % number of voxels with positive GLM R^2 (initial GLM model)
  case 35
    datadir = '/home/knk/ext/rawdata/JW20111118';  % where the original data live
    outputdir = '/home/knk/ext/datasets/JW20111118';  % where to save analysis results
    pcnum = [];              % number of PCs to use
    numnicevoxels = [];    % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.5;         % total size of stimulus in deg
  case 36
    datadir = '/home/knk/ext/rawdata/JW20111103b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/JW20111103b';  % where to save analysis results
    pcnum = 3;              % number of PCs to use
    numnicevoxels = 1323;   % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.5;         % total size of stimulus in deg
  case 37
    datadir = '/home/knk/ext/rawdata/JW20111229';  % where the original data live
    outputdir = '/home/knk/ext/datasets/JW20111229';  % where to save analysis results
    pcnum = 6;              % number of PCs to use
    numnicevoxels = 1930;    % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.5;         % total size of stimulus in deg
  case 38
    datadir = '/home/knk/ext/rawdata/KW20120102';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20120102';  % where to save analysis results
    pcnum = 5;              % number of PCs to use
    numnicevoxels = 1502;    % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.7;         % total size of stimulus in deg
  case 39
    datadir = '/home/knk/ext/rawdata/MP20120314';  % where the original data live
    outputdir = '/home/knk/ext/datasets/MP20120314';  % where to save analysis results
    pcnum = 4;             % number of PCs to use
    numnicevoxels = 1271;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.8;        % total size of stimulus in deg
  case 40
    datadir = '/home/knk/ext/rawdata/KW20120808';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20120808';  % where to save analysis results
    pcnum = 3;             % number of PCs to use
    numnicevoxels = 1502;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.7;        % total size of stimulus in deg
  case 41
    datadir = '/home/knk/ext/rawdata/KG20120831';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20120831';  % where to save analysis results
    pcnum = 3;             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 20;        % total size of stimulus in deg
  case 42
    datadir = '/home/knk/ext/rawdata/KG20120918';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20120918';  % where to save analysis results
    pcnum = 5;             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 20;        % total size of stimulus in deg
  case 43
    datadir = '/home/knk/ext/rawdata/KG20120924';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20120924';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 20;        % total size of stimulus in deg
  case 44
    datadir = '/home/knk/ext/rawdata/KG20120918b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20120918b';  % where to save analysis results
    pcnum = 3;             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 20;        % total size of stimulus in deg
  case 45
    datadir = '/home/knk/ext/rawdata/KW20120927';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20120927';  % where to save analysis results
    pcnum = 3;             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 20;        % total size of stimulus in deg
  case 46
    datadir = '/home/knk/ext/rawdata/KW20121113';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20121113';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.5;        % total size of stimulus in deg
  case 47
    datadir = '/home/knk/ext/rawdata/KG20121113';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20121113';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.6;        % total size of stimulus in deg
  case 48
    datadir = '/home/knk/ext/rawdata/JW20121212';  % where the original data live
    outputdir = '/home/knk/ext/datasets/JW20121212';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = [];        % total size of stimulus in deg
  case 49
    datadir = '/home/knk/ext/rawdata/MP20121212';  % where the original data live
    outputdir = '/home/knk/ext/datasets/MP20121212';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = [];        % total size of stimulus in deg
  case 50
    datadir = '/home/knk/ext/rawdata/KG20121221';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20121221';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.6;        % total size of stimulus in deg
  case 51
    datadir = '/home/knk/ext/rawdata/KG20121113b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20121113b';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.6;        % total size of stimulus in deg
  case 52
    datadir = '/home/knk/ext/rawdata/KW20130212';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130212';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.5;        % total size of stimulus in deg
  case 53
    datadir = '/home/knk/ext/rawdata/KW20130315';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130315';  % where to save analysis results
    pcnum = [];             % number of PCs to use
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model)
    stimdeg = 12.5;        % total size of stimulus in deg
  case 54
    datadir = '/home/knk/ext/rawdata/KW20130411';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130411';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 55
    datadir = '/home/knk/ext/rawdata/KW20130415';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130415';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 56
    datadir = '/home/knk/ext/rawdata/KW20130411b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130411b';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 57
    datadir = '/home/knk/ext/rawdata/KG20130416';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130416';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 196;
  case 58
    datadir = '/home/knk/ext/rawdata/KG20130421';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130421';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 196;
  case 59
    datadir = '/home/knk/ext/rawdata/KG20130416b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130416b';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 196;
  case 60
    datadir = '/home/knk/ext/rawdata/KK20130423';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130423';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 61
    datadir = '/home/knk/ext/rawdata/KG20130423';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130423';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 196;
  case 62
    datadir = '/home/knk/ext/rawdata/KG20130416c';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130416c';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 196;
  case 63
    datadir = '/home/knk/ext/rawdata/KW20130424';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130424';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 64
    datadir = '/home/knk/ext/rawdata/KW20130411c';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130411c';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 65
    datadir = '/home/knk/ext/rawdata/KK20130425';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130425';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 66
    datadir = '/home/knk/ext/rawdata/KK20130426';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130426';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 67
    datadir = '/home/knk/ext/rawdata/KK20130423c';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130423c';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 68
    datadir = '/home/knk/ext/rawdata/KG20130506';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130506';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 196;
  case 69
    datadir = '/home/knk/ext/rawdata/KG20130416d';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130416d';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 196;
  case 70
    datadir = '/home/knk/ext/rawdata/KW20130523';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130523';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 75;
  case 71
    datadir = '/home/knk/ext/rawdata/KG20130527';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130527';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 75;
  case 72
    datadir = '/home/knk/ext/rawdata/MT20130528';  % where the original data live
    outputdir = '/home/knk/ext/datasets/MT20130528';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = [];        % total size of stimulus in deg
    numstim = 9;
  case 73
    datadir = '/home/knk/ext/rawdata/KH20130528';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KH20130528';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = [];        % total size of stimulus in deg
    numstim = 9;
  case 74
    datadir = '/home/knk/ext/rawdata/KK20130605';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130605';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 75;
  case 75
    datadir = '/home/knk/ext/rawdata/KW20130606';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130606';  % where to save analysis results
    outputdirALT = '/home/knk/ext/datasets/KW20130714';
    outputdirNK = '/home/knk/ext/datasets/KW20130606.nk';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 81;
  case 76
    datadir = '/home/knk/ext/rawdata/KK20130610';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130610';  % where to save analysis results
    outputdirALT = '/home/knk/ext/datasets/KK20130711';
    outputdirNK = '/home/knk/ext/datasets/KK20130610.nk';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 81;
  case 77
    datadir = '/home/knk/ext/rawdata/GT20130611';  % where the original data live
    outputdir = '/home/knk/ext/datasets/GT20130611';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = [];        % total size of stimulus in deg
    numstim = 20;
  case 78
    datadir = '/home/knk/ext/rawdata/AS20130611';  % where the original data live
    outputdir = '/home/knk/ext/datasets/AS20130611';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = [];        % total size of stimulus in deg
    numstim = 20;
  case 79
    datadir = '/home/knk/ext/rawdata/KG20130611';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130611';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 81;
  case 80
    datadir = '/home/knk/ext/rawdata/KG20130702';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130702';  % where to save analysis results
    outputdirALT = '/home/knk/ext/datasets/KG20130703';
    outputdirNK = '/home/knk/ext/datasets/KG20130702.nk';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 81;
  case 81
    datadir = '/home/knk/ext/rawdata/KG20130703';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130703';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 81;
  case 82
    datadir = '/home/knk/ext/rawdata/KK20130711';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130711';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 81;
  case 83
    datadir = '/home/knk/ext/rawdata/KW20130714';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130714';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 81;
  case 84
    datadir = '/home/knk/ext/rawdata/PS20130925';  % where the original data live
    outputdir = '/home/knk/ext/datasets/PS20130925';  % where to save analysis results
    pcnum = [];             % number of PCs to use [obsolete now i think]
    numnicevoxels = NaN;  % number of voxels with positive GLM R^2 (initial GLM model) [obsolete?]
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 196;
  case 85
    datadir = '/home/knk/ext/rawdata/KG20130702b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20130702b';  % where to save analysis results
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 81;
  case 86
    datadir = '/home/knk/ext/rawdata/KW20130606b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20130606b';  % where to save analysis results
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 81;
  case 87
    datadir = '/home/knk/ext/rawdata/KK20130610b';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20130610b';  % where to save analysis results
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 81;
  case 88
    datadir = '/home/knk/ext/rawdata/UP20131213';  % where the original data live
    outputdir = '/home/knk/ext/datasets/UP20131213';  % where to save analysis results
    stimdeg = 10;        % total size of stimulus in deg
    numstim = 45;
  case 89
    datadir = '/home/knk/ext/rawdata/UP20131221';  % where the original data live
    outputdir = '/home/knk/ext/datasets/UP20131221';  % where to save analysis results
    stimdeg = 10;        % total size of stimulus in deg
    numstim = 45;
  case 90
    datadir = '/home/knk/ext/rawdata/20140428S016';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140428S016';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 91
    datadir = '/home/knk/ext/rawdata/20140505S017';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140505S017';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 92
    datadir = '/home/knk/ext/rawdata/20140512S018';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140512S018';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 93
    datadir = '/home/knk/ext/rawdata/20140602S019';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140602S019';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 94
    datadir = '/home/knk/ext/rawdata/20140605S015';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140605S015';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 95
    datadir = '/home/knk/ext/rawdata/20140605S018';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140605S018';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 96
    datadir = '/home/knk/ext/rawdata/20140608S015';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140608S015';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 97
    datadir = '/home/knk/ext/rawdata/20140619S015';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140619S015';  % where to save analysis results
    stimdeg = 10;         % total size of stimulus in deg
    numstim = NaN;
  case 98
    datadir = '/home/knk/ext/rawdata/20140623S017';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140623S017';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 99
    datadir = '/home/knk/ext/rawdata/20140707S019';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140707S019';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 32;
  case 100
    datadir = [];  % where the original data live
    outputdir = '/home/knk/ext/datasets/readingsubjectaveraged';  % where to save analysis results
    stimdeg = [];         % total size of stimulus in deg
    numstim = [];
  case 101
    datadir = '/home/knk/ext/rawdata/20140721S017';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140721S017';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 102
    datadir = '/home/knk/ext/rawdata/20140727S019';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140727S019';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 103
    datadir = '/home/knk/ext/rawdata/20140810S018';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140810S018';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 104
    datadir = '/home/knk/ext/rawdata/20140814S015';  % where the original data live
    outputdir = '/home/knk/ext/datasets/20140814S015';  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 105
    datadir = '/home/knk/ext/rawdata/KW20141031';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20141031';  % where to save analysis results
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 75;
  case 106
    datadir = '/home/knk/ext/rawdata/KK20141031';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20141031';  % where to save analysis results
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 75;
  case 107
    datadir = '/home/knk/ext/rawdata/KG20141031';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20141031';  % where to save analysis results
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 75;
  case 108
    datadir = '/home/knk/ext/rawdata/KW20141101';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KW20141101';  % where to save analysis results
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 50;
  case 109
    datadir = '/home/knk/ext/rawdata/KK20141101';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KK20141101';  % where to save analysis results
    stimdeg = 12.5;        % total size of stimulus in deg
    numstim = 50;
  case 110
    datadir = '/home/knk/ext/rawdata/KG20141101';  % where the original data live
    outputdir = '/home/knk/ext/datasets/KG20141101';  % where to save analysis results
    stimdeg = 12.6;        % total size of stimulus in deg
    numstim = 50;
  case 111
    datadirraw = '20150115S020';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 112
    datadirraw = '20150118S021';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 113
    datadirraw = '20150122S022';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 114
    datadirraw = '20150129S023';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 115
    datadirraw = '20150201S024';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 116
    datadirraw = '20150202S025';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 118
    datadirraw = '20150209S027';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 2;         % total size of stimulus in deg
    numstim = 24*3;
  case 119
    datadirraw = 'MT20150218';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 23;         % total size of stimulus in deg
    numstim = 15*3;
  case 120
    datadirraw = 'JG20150225';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 23;         % total size of stimulus in deg
    numstim = 15*3;
  case 121
    datadirraw = 'RL20150421';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 23;         % total size of stimulus in deg
    numstim = 15*3;
  case 122
    datadirraw = 'AS20150423';
    datadir = sprintf('/home/knk/ext/rawdata/%s',datadirraw);  % where the original data live
    outputdir = sprintf('/home/knk/ext/datasets/%s',datadirraw);  % where to save analysis results
    stimdeg = 23;         % total size of stimulus in deg
    numstim = 15*3;
  end

  % make the output directory
  mkdirquiet(outputdir);

  switch x
  case {72 73}  % NONE AVAILABLE
  case {88 89}
    highresanatomy = '/stone/ext1/knk/anatomicals/UP/t1_acpc.nii';  % path to high-res volume
    highresclass = [];  % path to corresponding class file
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roifiles = '/stone/ext1/knk/anatomicals/UP/rois/*.nii.gz';  % wildcard matching all the ROI files
    roinames = {'LaOTSwords' 'LaSTSwords' 'LFFA1' 'LFFA2' 'LOTSwords' 'LpSTSwords'}; ...  % short names for the ROI files
      % how do we group and label the ROI files? (note that we insert a dummy first ROI)
    roigroups = {    [1]   2 3 4 5 6 7  };
    roigrouplabels = [{'?'} roinames];
    epitr = maketransformation([0 0 0],[1 2 3],[90.4122497938969 114.538768004163 71.8178908341887],[1 2 3],[-0.873762349048663 13.7683473162048 90.4531073861354],[116 116 42],[232 232 84],[-1 1 1],[0 0 0],[0 0 0],[0 0 0]);
    xform = [0.0153618005859968 -1.99964750653226 -0.0342617089775493 207.229590334771;-1.94247107342825 -0.0230728396184518 0.475682428692144 219.295914700513;0.475993848675875 -0.0296225200016375 1.94230593942651 3.94559040907598;0 0 0 1];
  case {90}
    highresanatomy = '/software/freesurfer/subjects/S016/mri/T1.mgz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    subjectid = 'S016';
    numlh = 121229;
    numrh = 122850;
    epitr = maketransformation([0 0 0],[1 2 3],[126.479349621688 130.20452839796 111.007833142262],[1 2 3],[-3.98642666123907 -14.7773535421649 -90.0729282336782],[80 80 28],[200 200 70],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [0.00181049202421024 0.731937920081625 -16.3503944698768;0.731448327981944 -0.000933337560935149 -75.3323632743114;1 1 1];
    illflatrh = [-0.000104120140112838 0.664723037927469 -3.00414750882131;0.665331780927418 0.00056066144697939 -72.7200165395709;1 1 1];
  case {100}
    highresanatomy = [];  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roifiles = [];%'/stone/ext1/knk/anatomicals/UP/rois/*.nii.gz';  % wildcard matching all the ROI files
    roinames = [];%{'LaOTSwords' 'LaSTSwords' 'LFFA1' 'LFFA2' 'LOTSwords' 'LpSTSwords'}; ...  % short names for the ROI files
      % how do we group and label the ROI files? (note that we insert a dummy first ROI)
    roigroups = [];%{    [1]   2 3 4 5 6 7  };
    roigrouplabels = [];%[{'?'} roinames];
    subjectid = 'fsaverage';
    numlh = 163842;
    numrh = 163842;
    epitr = [];
    illflatlh = [];
    illflatrh = [];
  case {91 98 101}
    highresanatomy = '/software/freesurfer/subjects/S017/mri/T1.mgz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    subjectid = 'S017';
    numlh = 143130;
    numrh = 141492;
      % 91 only:
    epitr = maketransformation([0 0 0],[1 2 3],[129.138878614001 129.962747694953 113.786895366123],[1 2 3],[2.82342572046386 -8.04601590115277 -90.0081077096648],[80 80 28],[200 200 70],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [-0.000607087076487581 0.76914773793744 -22.9494533912126;0.76964707842076 0.000265669934239799 -87.5450245461832;1 1 1];
    illflatrh = [-0.128402020275497 0.686245305045523 33.6260928263595;0.685074962803477 0.127926612029002 -108.637589898279;1 1 1];
  case {92 95 103}
    highresanatomy = '/software/freesurfer/subjects/S018/mri/T1.mgz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    subjectid = 'S018';
    numlh = 144074;
    numrh = 143135;
      % ONLY FOR 92:
    epitr = maketransformation([0 0 0],[1 2 3],[127.913055397762 128.108048876016 105.446807464751],[1 2 3],[4.26655187960481 -11.5919874540656 -89.5357408198478],[80 80 28],[200 200 70],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [0.144192743422631 0.725114477588717 -66.7214633426537;0.723481440856636 -0.14380476919936 -66.6931692140233;1 1 1];
    illflatrh = [-0.185947869023262 0.669586567314651 43.0367672260293;0.66943030200391 0.187857860454073 -117.950866064949;1 1 1];
  case {93 99 102}
    highresanatomy = '/software/freesurfer/subjects/S019/mri/T1.mgz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    subjectid = 'S019';
    numlh = 128031;
    numrh = 128565;
      % ONLY FOR 93
    epitr = maketransformation([0 0 0],[1 2 3],[128.381676912327 125.598483649499 111.530902705605],[1 2 3],[-2.14231042562658 -7.48615757158666 -90.1246594045494],[80 80 28],[200 200 70],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [-0.000650539835889987 0.745496280781459 -18.2225982841646;0.744969091311892 0.00143964269985916 -79.9515927095565;1 1 1];
    illflatrh = [0.000368184441529209 0.691957342780814 -8.18296775615723;0.691726133111158 0.000870283208914418 -80.9802455653223;1 1 1];
  case {94 96 97 104}
    highresanatomy = '/software/freesurfer/subjects/S015/mri/T1.mgz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    subjectid = 'S015';
    numlh = 160824;
    numrh = 159099;
      % ONLY FOR 94:
    switch fmrisetupnum
    case {94 96 104}
      epitr = maketransformation([0 0 0],[1 2 3],[126.862887495251 125.044612521307 110.457087365733],[1 2 3],[-3.30283708990763 -6.97917079539512 -91.3611309014024],[80 80 28],[200 200 70],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    case {97}
      epitr = maketransformation([0 0 0],[1 2 3],[125.350681715985 90.0325249602594 95.7579118744828],[1 2 3],[-3.67918067197537 -26.9537364964869 -92.295776539827],[104 128 42],[156 192 63],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    end
    illflatlh = [0.000184191961020058 0.800666340814719 -29.1959523322404;0.801310704376265 0.000250526531664517 -97.6234423360754;1 1 1];
    illflatrh = [0.000448939439451415 0.819758386541743 -32.9357830324924;0.819785914176428 -8.58472786496997e-05 -121.54485941785;1 1 1];

  case {111}
    subjectid = 'S020';
    highresanatomy = sprintf('/software/freesurfer/subjects/%s/mri/T1.mgz',subjectid);  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    numlh = 171015;
    numrh = 168342;
    epitr = maketransformation([0 0 0],[1 2 3],[126.671905080236 120.710103682018 98.9355585590238],[1 2 3],[-1.97567327975687 -19.8629319634784 -90.5223305293074],[80 80 28],[200 200 70],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [-8.6821186949476e-05 0.817446857981597 -679.627293256066;0.818248869997959 -0.000701218123956245 -117.214836364325;1 1 1];
    illflatrh = [-0.190436472047195 0.706034689392689 -530.451514188258;0.707054410807431 0.189091770699187 -277.47773394884;1 1 1];

  case {112}
    subjectid = 'S021';
    highresanatomy = sprintf('/software/freesurfer/subjects/%s/mri/T1.mgz',subjectid);  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    numlh = 155220;
    numrh = 153180;
    epitr = maketransformation([0 0 0],[1 2 3],[128.686907289357 127.801506751656 98.330347359218],[1 2 3],[0.054754233991134 -9.49171942430095 -90.2724811036218],[80 80 28],[200 200 70],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [0.135371528412687 0.766621409533785 -672.569310083066;0.768077413039563 -0.135177941034526 31.291657012159;1 1 1];
    illflatrh = [-0.195982395070481 0.728888092415133 -538.425020231393;0.72900799144331 0.195481867810471 -287.434091012677;1 1 1];

  case {113}
    subjectid = 'S022';
    highresanatomy = sprintf('/software/freesurfer/subjects/%s/mri/T1.mgz',subjectid);  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    numlh = 156890;
    numrh = 155657;
    epitr = maketransformation([0 0 0],[1 2 3],[130.406399415569 127.06432470138 138.606386007598],[1 2 3],[-2.66245079005191 -0.241574983794639 -92.7269772662171],[80 80 58],[200 200 145],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [0.255304243042402 0.696680079436995 -641.670887153424;0.697401503193892 -0.253468884295642 170.198858689207;1 1 1];
    illflatrh = [-0.30119462406977 0.645477022966896 -423.071326389333;0.645664709051114 0.300347796310969 -364.130778581199;1 1 1];

  case {114}
    subjectid = 'S023';
    highresanatomy = sprintf('/software/freesurfer/subjects/%s/mri/T1.mgz',subjectid);  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    numlh = 146195;
    numrh = 144438;
    epitr = maketransformation([0 0 0],[1 2 3],[128.646027299389 131.534879149349 137.67766830892],[1 2 3],[-3.61445805528418 -7.26681278261071 -90.8783431109701],[80 80 58],[200 200 145],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [-0.000722334064664054 0.756696161436355 -626.480044495989;0.756698776985159 -0.000394744965731041 -97.9738433839167;1 1 1];
    illflatrh = [-0.123632338405226 0.699933278377453 -526.638113537033;0.700909216609248 0.122848672761443 -205.786673296579;1 1 1];

  case {115}
    subjectid = 'S024';
    highresanatomy = sprintf('/software/freesurfer/subjects/%s/mri/T1.mgz',subjectid);  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    numlh = 139987;
    numrh = 140290;
    epitr = maketransformation([0 0 0],[1 2 3],[128.027361350044 128.773280627902 140.026720761347],[1 2 3],[2.0340799073874 -12.7647490173162 -89.8915377925919],[80 80 58],[200 200 145],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [0.0623405894118364 0.70616415457072 -590.222851135035;0.706439531914576 -0.0601492842590295 -23.686220525877;1 1 1];
    illflatrh = [-0.186228526392983 0.696624380579469 -503.401713936875;0.69567217205372 0.185774564850875 -266.058543034444;1 1 1];

  case {116}
    subjectid = 'S025';
    highresanatomy = sprintf('/software/freesurfer/subjects/%s/mri/T1.mgz',subjectid);  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    numlh = 157562;
    numrh = 153451;
    epitr = maketransformation([0 0 0],[1 2 3],[126.258429538652 126.501986229354 130.950343239762],[1 2 3],[-0.813126798518636 -15.5041669172648 -92.6667752469366],[80 80 58],[200 200 145],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [0.000157673663744646 0.785872337610542 -649.046433929877;0.785356533254827 0.000668393226664779 -108.595390425229;1 1 1];
    illflatrh = [0.000734345964718665 0.743220181846719 -608.497150775121;0.74185626463009 -0.000395588118165597 -97.5261891645366;1 1 1];

  case {118}
    subjectid = 'S027';
    highresanatomy = sprintf('/software/freesurfer/subjects/%s/mri/T1.mgz',subjectid);  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    numlh = 154813;
    numrh = 152468;
    epitr = maketransformation([0 0 0],[1 2 3],[129.600369392299 126.294028609528 136.98893323221],[1 2 3],[-2.80878241958675 -0.955010946168162 -89.5733586807966],[80 80 58],[200 200 145],[1 -1 1],[0 0 0],[0 0 0],[0 0 0]);
    illflatlh = [0.256079809670716 0.704854352357948 -650.265469929183;0.702630124088067 -0.254957592329202 169.227518086195;1 1 1];
    illflatrh = [-0.186263830084285 0.69626279808127 -509.628412783007;0.695850039120391 0.187414552279849 -269.448601996297;1 1 1];

  case {28 29 30 34 39 49}
    highresanatomy = '/stone/ext1/knk/anatomicals/MP/t1_resamp_1mm.nii.gz';  % path to high-res volume
    highresclass = '/stone/ext1/knk/anatomicals/MP/t1_resamp_1mm_class.nii.gz';  % path to corresponding class file
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roifiles = '/stone/ext1/knk/anatomicals/MP/rois/*3and14deg*';  % wildcard matching all the ROI files
    roinames = {'LLO1' 'LLO2' 'LTO1' 'LTO2' 'LV1' 'LV2d' 'LV2v' 'LV3ab' 'LV3d' 'LV3v' ...  % short names for the ROI files
                'LVO1' 'LVO2' 'LhV4' 'RLO1' 'RLO2' 'RTO1' 'RTO2' 'RV1' 'RV2d' 'RV2v' 'RV3ab' ...
                'RV3d' 'RV3v' 'RVO1' 'RVO2' 'RhV4'};
      % how do we group and label the ROI files? (note that we insert a dummy first ROI)
    roigroups = {    [1]   [6 19]  [7 8 20 21]  [10 11 23 24] [9 22]  [14 27] [12 25]  [13 26] [2 15]  [3 16]  [4 17]  [5 18]};
    roigrouplabels = {'?'  'V1'    'V2'        'V3'          'V3AB'  'hV4'   'VO1'    'VO2'   'LO1'   'LO2'   'TO1'    'TO2'};
  case {31 32}
    highresanatomy = '/stone/ext1/knk/anatomicals/FP/t1.nii.gz';  % path to high-res volume
    highresclass = '/stone/ext1/knk/anatomicals/FP/t1_class.nii.gz';  % path to corresponding class file
    anatlen = 0.7;  % size in mm of the high-res voxels (assumed to be isotropic)
      roistem = '/stone/ext1/knk/anatomicals/FP/rois/';
    roifiles = cellfun(@(a) [roistem a],{'RIPS1.mat' 'RIPS2.mat' 'RIPS3.mat' 'RV1.mat' 'RV2d.mat' 'RV2v.mat' 'RV3d.mat' 'RV3v.mat' 'RV4.mat' 'RVO1.mat'},'UniformOutput',0);  % wildcard matching all the ROI files
    roinames = {'RIPS1' 'RIPS2' 'RIPS3' 'RV1' 'RV2d' 'RV2v' 'RV3d' 'RV3v' 'RV4' 'RVO1'};  % short names for the ROI files
      % how do we group and label the ROI files? (note that we insert a dummy first ROI)
    roigroups = {    [1]   [5]     [6 7]       [8 9]        [10]    [11]   [2]     [3]    [4] };
    roigrouplabels = {'?'  'V1'    'V2'        'V3'         'hV4'   'VO1'  'IPS1' 'IPS2' 'IPS3'};
  case {33 35 36 37 48}
    highresanatomy = '/stone/ext1/knk/anatomicals/JW/t1.nii.gz';  % path to high-res volume
    highresclass = '/stone/ext1/knk/anatomicals/JW/t1_class.nii.gz';  % path to corresponding class file
    anatlen = 0.7;  % size in mm of the high-res voxels (assumed to be isotropic)
    roifiles = '/stone/ext1/knk/anatomicals/JW/rois/*3and14*';  % wildcard matching all the ROI files
    roinames = {'LLO1' 'LLO2' 'LTO1' 'LTO2' 'LV1' 'LV2d' 'LV2v' 'LV3ab' 'LV3d' 'LV3v' ...
                'LVO1' 'LVO2' 'LhV4' 'RLO1' 'RLO2' 'RTO1' 'RTO2' 'RV1' 'RV2d' 'RV2v' 'RV3ab' ...
                'RV3d' 'RV3v' 'RVO1' 'RVO2' 'RhV4'};  % short names for the ROI files
      % how do we group and label the ROI files? (note that we insert a dummy first ROI)
    roigroups = {     [1]  [6 19]  [7 8 20 21]  [10 11 23 24] [9 22]  [14 27] [12 25]  [13 26] [2 15]  [3 16]  [4 17]  [5 18]};
    roigrouplabels = {'?'  'V1'    'V2'        'V3'          'V3AB'  'hV4'   'VO1'    'VO2'   'LO1'   'LO2'   'TO1'    'TO2'};
  case {38 40}
    highresanatomy = '/stone/ext1/knk/anatomicals/KW/t1.nii.gz';  % path to high-res volume
    highresclass = '/stone/ext1/knk/anatomicals/KW/t1_class.nii.gz';  % path to corresponding class file
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roifiles = '/stone/ext1/knk/anatomicals/KW/roisjw/*3and14deg*';  % wildcard matching all the ROI files
    roinames = {'LLO1' 'LLO2' 'LTO1' 'LTO2' 'LV1' 'LV2d' 'LV2v' 'LV3ab' 'LV3d' 'LV3v' ...
                'LVO1' 'LVO2' 'LhV4' 'RLO1' 'RLO2' 'RTO1' 'RTO2' 'RV1' 'RV2d' 'RV2v' 'RV3ab' ...
                'RV3d' 'RV3v' 'RVO1' 'RVO2' 'RhV4'};  % short names for the ROI files
      % how do we group and label the ROI files? (note that we insert a dummy first ROI)
    roigroups = {     [1]  [6 19]  [7 8 20 21]  [10 11 23 24] [9 22]  [14 27] [12 25]  [13 26] [2 15]  [3 16]  [4 17]  [5 18]};
    roigrouplabels = {'?'  'V1'    'V2'        'V3'          'V3AB'  'hV4'   'VO1'    'VO2'   'LO1'   'LO2'   'TO1'    'TO2'};
  case {41 42 43 44 47 50 51 57 58 59 61 62 68 69 71 79 80 81 85 107 110}  % Kalanit
    highresanatomy = '/stone/ext1/knk/anatomicals/KG/vAnatomy.nii.gz';  % path to high-res volume
    highresanatomyNEW = '/stone/ext1/knk/anatomicals/KGdump/kalanit_2013/t1.nii.gz';
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = '/stone/ext1/knk/anatomicals/KG/rois';
    roinames = {'lh_MTG_limbs_resting'
'lh_AT_faces_resting'
''
'lh_IOG_faces_resting'
'lh_mFus_faces_resting'
'lh_pFus_faces_new_pos'
'lh_pSTS_faces_resting'
'lh_LOS_limbs_resting'
'lh_V7_limbs_resting'
'lV1_nw_082608'
'lV2d_nw_082608'
'lV2v_nw_082608'
'lV3d_nw_082608'
'lV3v_nw_082608'
'lV4_nw'
'rh_AT_faces_resting'
'rh_IOG_faces_resting'
'rh_LOS_limbs_resting'
'rh_mFus_faces_resting'
'rh_MTG_limbs_resting'
'rh_OTS_limbs_resting'
'rh_pFus_faces_resting'
'rh_pSTS_faces_resting'
'rh_V7_limbs_resting'
'rV1_nw_082608_ave'
'rV2d_nw_082608'
'rV2v_nw_082608'
'rV3d_nw_082608'
'rV3v_nw_082608'
'rV4_nw'};
    shortroinames = {'EBAl' 'ATl' 'FBAl' 'IOGl' 'mFusl' 'pFusl' 'STSl' 'EBAl' 'V7l' 'V1l' 'V2dl' 'V2vl' 'V3dl' 'V3vl' 'V4l' 'ATr' 'IOGr' 'LOSr' 'mFusr' 'MTGr' 'OTSr' 'pFusr' 'STSr' 'V7r' 'V1r' 'V2dr' 'V2vr' 'V3dr' 'V3vr' 'V4r'};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
    leftwrinkled = '~/ext/anatomicals/KGdump/KGleftwrinkled.mat';
    leftinflated = '~/ext/anatomicals/KGdump/KGleftinflated.mat';
    rightwrinkled = '~/ext/anatomicals/KGdump/KGrightwrinkled.mat';
    rightinflated = '~/ext/anatomicals/KGdump/KGrightinflated.mat';
    epitr = maketransformation([0 0 0],[1 2 3],[130.922607775516 129.870307688923 91.3737025702284],[1 2 3],[88.3041046679928 0.824899790725837 154.491479301032],[80 80 26],[160 160 52],[-1.00285087561688 -1.00445001022094 -0.982107047026832],[0 0 0],[0.000455677439355937 -0.00131079364518602 0.00325927563664365],[0 0 0]);
    
    % this is because we went to new way with Freesurfer
    epitrNEW = maketransformation([0 0 0],[1 2 3],[127.979860141954 109.806567394164 122.154766972224],[1 2 3],[1.1205167875851 -25.2955081254817 -90.9701472140949],[80 80 26],[160 160 52],[0.999827146106493 -1.00440935048297 0.987069738709636],[0 0 0],[-0.00115578755788052 0.000451051482925875 0.00120089265702703],[0 0 0]);
    subjectid = 'KGb';
    numlh = 113723;
    numrh = 115451;
  case {45 46 52 53 54 55 56 63 64 70 75 83 86 105 108}  % Kevin
    highresanatomy = '/stone/ext1/knk/anatomicals/KW/t1.nii.gz';  % path to high-res volume
    highresanatomyNEW = '/stone/ext1/knk/anatomicals/KWdump/kevin_2013/t1.nii.gz';
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = '/stone/ext1/knk/anatomicals/KW/roiskw';
    roinames = {'lh_aEBA_event_new_b'
'lh_AT_faces_resting'
'lh_FBA_event_loc'
'lh_IOG_faces_new_pos'
'lh_mFus_faces_new_pos'
'lh_pFus_faces_new_pos'
'lh_pSTS_faces_resting'
'lh_sEBA_event_new_b'
'lh_V7_limbs_resting'
'lV1_nw'
'lV2d_nw'
'lV2v_nw'
'lV3d_nw'
'lV3v_nw'
'lV4_nw'
'rh_AT_faces_resting'
'rh_IOG_faces_new_pos'
'rh_LOS_limbs_resting'
'rh_mFus_faces_new_pos'
'rh_MTG_limbs_resting'
'rh_OTSlimbs_NRNfig'
'rh_pFus_faces_new_pos'
'rh_pSTS_faces_resting'
'rh_V7_limbs_resting'
'rV1_nw'
'rV2d_nw'
'rV2v_nw'
'rV3d_nw'
'rV3v_nw'
'rV4_nw'};
    shortroinames = {'EBAl' 'ATl' 'FBAl' 'IOGl' 'mFusl' 'pFusl' 'STSl' 'EBAl' 'V7l' 'V1l' 'V2dl' 'V2vl' 'V3dl' 'V3vl' 'V4l' 'ATr' 'IOGr' 'LOSr' 'mFusr' 'MTGr' 'OTSr' 'pFusr' 'STSr' 'V7r' 'V1r' 'V2dr' 'V2vr' 'V3dr' 'V3vr' 'V4r'};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
    leftwrinkled = '~/ext/anatomicals/KWdump/KWleftwrinkled.mat';
    leftinflated = '~/ext/anatomicals/KWdump/KWleftinflated.mat';
    rightwrinkled = '~/ext/anatomicals/KWdump/KWrightwrinkled.mat';
    rightinflated = '~/ext/anatomicals/KWdump/KWrightinflated.mat';
    epitr = maketransformation([0 0 0],[1 2 3],[137.510905589052 131.94068616713 90.4527401476619],[1 2 3],[91.9089953068375 -0.534013814634498 155.868438005832],[80 80 26],[160 160 52],[-0.99914885761754 -1.00364935079721 -0.979299272264126],[0 0 0],[-0.00175055502602659 -0.0024494627231074 0.00462729908229289],[0 0 0]);

    % this is because we went to new way with Freesurfer
    epitrNEW = maketransformation([0 0 0],[1 2 3],[129.056284843022 98.6306342691552 88.6205650262407],[1 2 3],[0.765496017798138 28.1102110503623 92.2290594499939],[80 80 26],[160 160 52],[-0.992555224536791 1.01098999331508 0.984368259261753],[0 0 0],[-0.00332852379745588 -0.00313421893236769 0.0027099099253855],[0 0 0]);
    subjectid = 'KW';
    numlh = 141064;
    numrh = 142071;
  case {60 65 66 67 74 76 82 87 106 109}  % Kendrick
    highresanatomy = '/stone/ext1/knk/anatomicals/KKb/t1.nii.gz';  % path to high-res volume
    highresanatomyNEW = '/stone/ext1/knk/anatomicals/KKdump/t1.nii.gz';
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = '/stone/ext1/knk/anatomicals/KKb/rois';
    roinames = {'lh_MTG_limbs_resting'
'lh_AT_faces_resting'
''
'lh_IOG_faces_resting'
'lh_mFus_faces_resting'
'lh_pFus_faces_resting'
''
'lh_LOS_limbs_resting'
'lh_V7_limbs_resting'
''
''
''
''
''
''
'rh_AT_faces_resting'
'rh_IOG_faces_resting'
'rh_LOS_limbs_resting'
'rh_mFus_faces_resting'
'rh_MTG_limbs_resting'
'rh_OTS_limbs_resting'
'rh_pFus_faces_resting'
'rh_pSTS_faces_resting'
'rh_V7_limbs_resting'
''
''
''
''
''
''};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
    highresanatomyHACK = '/stone/ext1/knk/anatomicals/KKc/t1.nii.gz';  % path to high-res volume
    anatlenHACK = 0.7;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidirHACK = '/stone/ext1/knk/anatomicals/KKc/rois';
    roinamesHACK = {''
''
''
''
''
''
''
''
''
'lh_V1_kw'
'lh_V2d_kw'
'lh_V2v_kw'
'lh_V3d_kw'
'lh_V3v_kw'
'lh_hV4_kw'
''
''
''
''
''
''
''
''
''
'rh_V1_kw'
'rh_V2d_kw'
'rh_V2v_kw'
'rh_V3d_kw'
'rh_V3v_kw'
'rh_hV4_kw'};
    roifilesHACK = cellfun(@(x) choose(isempty(x),'',[roidirHACK '/' x '.mat']),roinamesHACK,'UniformOutput',0);
    shortroinames = {'EBAl' 'ATl' 'FBAl' 'IOGl' 'mFusl' 'pFusl' 'STSl' 'EBAl' 'V7l' 'V1l' 'V2dl' 'V2vl' 'V3dl' 'V3vl' 'V4l' 'ATr' 'IOGr' 'LOSr' 'mFusr' 'MTGr' 'OTSr' 'pFusr' 'STSr' 'V7r' 'V1r' 'V2dr' 'V2vr' 'V3dr' 'V3vr' 'V4r'};
    leftwrinkled = '~/ext/anatomicals/KKdump/KKleftwrinkled.mat';
    leftinflated = '~/ext/anatomicals/KKdump/KKleftinflated.mat';
    rightwrinkled = '~/ext/anatomicals/KKdump/KKrightwrinkled.mat';
    rightinflated = '~/ext/anatomicals/KKdump/KKrightinflated.mat';
    epitr = maketransformation([0 0 0],[1 2 3],[132.211301136318 135.251799998458 91.1971429815159],[1 2 3],[120.059844706545 86.2685899545796 -0.0578023715612924],[80 80 26],[160.000030517578 160.000015258789 52.0000123977661],[0.99706603216181 0.99699281475182 0.99771889946235],[0 0 0],[-0.0025105487174844 -6.86649787582523e-05 -0.000196782167276013],[0 0 0]);

    % this is because we went to new way with Freesurfer
    epitrNEW = maketransformation([0 0 0],[1 2 3],[127.631791981074 105.362144451802 82.9740230063315],[1 2 3],[149.573544481356 0.120815301706941 3.69020347835041],[80 80 26],[160.000030517578 160.000015258789 52.0000123977661],[-1.00059907986765 1.00124119214483 -0.992417125111119],[0 0 0],[-0.00345348834169808 0.000763585660066432 0.000440644280103887],[0 0 0]);
    subjectid = 'KK';
    numlh = 158349;
    numrh = 159359;
  case {119}  % MT
    highresanatomyNEW = '/stone/ext1/knk/anatomicals/MT/t1_1mm_average.nii.gz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = '/stone/ext1/knk/anatomicals/MT/ROIs';
    roinames = { ...
'lh_IOG_faces_FastLocs_new'
'lh_pFus_faces_FastLocs_new'
'lh_mFus_faces_FastLocs_new'
'rh_IOG_faces_FastLocs_new'
'rh_pFus_faces_FastLocs_new'
'rh_mFus_faces_FastLocs_new'
};
    shortroinames = {'IOGl' 'pFusl' 'mFusl' 'IOGr' 'pFusr' 'mFusr'};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
    leftwrinkled = [];
    leftinflated = [];
    rightwrinkled = [];
    rightinflated = [];
    epitr = maketransformation([0 0 0],[1 2 3],[119.90097887366 121.31691941212 91.026871072308],[1 2 3],[87.6943550627526 176.550523597506 97.8883290771528],[256 256 26],[159.999969482422 160.000030517578 51.9999287128448],[-1.0001228467937 1.01256843069337 1.00682542382627],[0 0 0],[-0.00938818808495944 -0.00516315878886385 -0.00217846550506835],[0 0 0]);
  case {120}  % JG
    highresanatomyNEW = '/stone/ext1/knk/anatomicals/JG/t1_1mm_average.nii.gz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = '/stone/ext1/knk/anatomicals/JG/ROIs';
    roinames = { ...
'lh_IOG_faces_FastLocs_new'
'lh_pFus_faces_FastLocs_new'
'lh_mFus_faces_FastLocs_new'
'rh_IOG_faces_FastLocs_new'
'rh_pFus_faces_FastLocs_new'
'rh_mFus_faces_FastLocs_new'
};
    shortroinames = {'IOGl' 'pFusl' 'mFusl' 'IOGr' 'pFusr' 'mFusr'};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
    leftwrinkled = [];
    leftinflated = [];
    rightwrinkled = [];
    rightinflated = [];
    epitr = maketransformation([0 0 0],[1 2 3],[128.095390609132 138.141406785458 89.9732955654295],[1 2 3],[90.3448803683302 181.103851886504 114.423792381145],[256 256 26],[160 160.000076293945 51.9994142055511],[-1.00012140330794 1.00404006950835 0.99712212769086],[0 0 0],[-0.000807203391820837 4.74661558461821e-05 -0.000100003326129801],[0 0 0]);
  case {121}  % RL
    highresanatomyNEW = '/stone/ext1/knk/anatomicals/RL/t1.nii.gz';  % path to high-res volume
    anatlen = 0.8;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = '/stone/ext1/knk/anatomicals/RL/ROIs';
    roinames = { ...
'lh_IOG_faces_FastLocs_new'
'lh_pFus_faces_FastLocs_new'
'lh_mFus_faces_FastLocs_new'
'rh_IOG_faces_FastLocs_new'
'rh_pFus_faces_FastLocs_new'
'rh_mFus_faces_FastLocs_new'
};
    shortroinames = {'IOGl' 'pFusl' 'mFusl' 'IOGr' 'pFusr' 'mFusr'};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
    leftwrinkled = [];
    leftinflated = [];
    rightwrinkled = [];
    rightinflated = [];
    epitr = maketransformation([0 0 0],[1 2 3],[124.522707652093 125.439668224822 90.7245714671912],[1 2 3],[90.4868123995942 -174.865655621089 102.819952852713],[256 256 26],[159.999969482422 160.000076293945 51.9998636245728],[-1 1 1],[0 0 0],[0 0 0],[0 0 0]);
  case {122}  % AS
    highresanatomyNEW = '/stone/ext1/knk/anatomicals/AS/t1.nii.gz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = '/stone/ext1/knk/anatomicals/AS/ROIs';
    roinames = { ...
'lh_IOG_faces_FastLocs_new'
'lh_pFus_faces_FastLocs_new'
'lh_mFus_faces_FastLocs_new'
'rh_IOG_faces_FastLocs_new'
'rh_pFus_faces_FastLocs_new'
'rh_mFus_faces_FastLocs_new'
};
    shortroinames = {'IOGl' 'pFusl' 'mFusl' 'IOGr' 'pFusr' 'mFusr'};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
    leftwrinkled = [];
    leftinflated = [];
    rightwrinkled = [];
    rightinflated = [];
    epitr = maketransformation([0 0 0],[1 2 3],[121.525486676558 136.951543742203 89.8049091676527],[1 2 3],[92.528631717002 -179.059226727395 111.681042778358],[256 256 26],[159.999984741211 159.999984741211 51.9987230300903],[-1 1 1],[0 0 0],[0 0 0],[0 0 0]);
  case {84}  % PS

% /biac4/kgs/biac2/kgs/3Danat/patient_ps/ROI/rh_pFus_faces_kw2.4.mat
% /biac4/kgs/biac2/kgs/3Danat/patient_ps/ROI/lh_V1.mat

    highresanatomy = [];%'/stone/ext1/knk/anatomicals/KW/t1.nii.gz';  % path to high-res volume
    anatlen = 1;  % size in mm of the high-res voxels (assumed to be isotropic)
    roidir = [];%'/stone/ext1/knk/anatomicals/KW/roiskw';
    roinames = {'lh_aEBA_event_new_b'
'lh_AT_faces_resting'
'lh_FBA_event_loc'
'lh_IOG_faces_new_pos'
'lh_mFus_faces_new_pos'
'lh_pFus_faces_new_pos'
'lh_pSTS_faces_resting'
'lh_sEBA_event_new_b'
'lh_V7_limbs_resting'
'lV1_nw'
'lV2d_nw'
'lV2v_nw'
'lV3d_nw'
'lV3v_nw'
'lV4_nw'
'rh_AT_faces_resting'
'rh_IOG_faces_new_pos'
'rh_LOS_limbs_resting'
'rh_mFus_faces_new_pos'
'rh_MTG_limbs_resting'
'rh_OTSlimbs_NRNfig'
'rh_pFus_faces_new_pos'
'rh_pSTS_faces_resting'
'rh_V7_limbs_resting'
'rV1_nw'
'rV2d_nw'
'rV2v_nw'
'rV3d_nw'
'rV3v_nw'
'rV4_nw'};
    shortroinames = {'EBAl' 'ATl' 'FBAl' 'IOGl' 'mFusl' 'pFusl' 'STSl' 'EBAl' 'V7l' 'V1l' 'V2dl' 'V2vl' 'V3dl' 'V3vl' 'V4l' 'ATr' 'IOGr' 'LOSr' 'mFusr' 'MTGr' 'OTSr' 'pFusr' 'STSr' 'V7r' 'V1r' 'V2dr' 'V2vr' 'V3dr' 'V3vr' 'V4r'};
    roifiles = cellfun(@(x) choose(isempty(x),'',[roidir '/' x '.mat']),roinames,'UniformOutput',0);
  end
  
  % freesurfer stuff
  if exist('subjectid','var')
    surfacedir = ['~/ext/anatomicals/' subjectid];
    lhwhite =    [surfacedir '/lhwhite.mat'];
    lhmidgray =  [surfacedir '/lhmidgray.mat'];
    lhinflated = [surfacedir '/lhinflated.mat'];
    lhflat =     [surfacedir '/lhflat.mat'];
    lhoccipflat =[surfacedir '/lhoccipflat.mat'];
    lhsphere =   [surfacedir '/lhspherereg.mat'];
    rhwhite =    [surfacedir '/rhwhite.mat'];
    rhmidgray =  [surfacedir '/rhmidgray.mat'];
    rhinflated = [surfacedir '/rhinflated.mat'];
    rhflat =     [surfacedir '/rhflat.mat'];
    rhoccipflat =[surfacedir '/rhoccipflat.mat'];
    rhsphere =   [surfacedir '/rhspherereg.mat'];
    lhroi =      [surfacedir '/roislh.mat'];
    rhroi =      [surfacedir '/roisrh.mat'];
    if ~exist(lhroi,'file')
      saveemptymat(lhroi);
    end
    if ~exist(rhroi,'file')
      saveemptymat(rhroi);
    end
  end

  switch x
  case {88}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [1 1 1];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 1;            % stimulus duration
    tr = 1;                 % the TR
    numtrtrial = 1;         % number of TRs per stimulus trial
  case {89}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [1 1 1];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 5;            % stimulus duration
    tr = 1;                 % the TR
    numtrtrial = 6;         % number of TRs per stimulus trial
  case {90 91 92 93 94 95 96 98 99 100 101 102 103 104 111 112 113 114 115 116 118}
    stimdur = 4;            % stimulus duration
    tr = 2;                 % the TR
    numtrtrial = 2;         % number of TRs per stimulus trial
  case {97}
    stimdur = NaN;            % stimulus duration
    tr = 2;                 % the TR
    numtrtrial = NaN;         % number of TRs per stimulus trial
  case {41 42 43 44 45}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [256 256 26]./[80 80 26];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 3.5;            % stimulus duration
    tr = 1.985626;          % the TR
    numtrtrial = 2;         % number of TRs per stimulus trial
  case {46 47 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 74 105 106 107 108 109 110}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [256 256 26]./[80 80 26];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 3.5;            % stimulus duration
    tr = 2.006553;          % the TR
    numtrtrial = 2;         % number of TRs per stimulus trial
    switch x
    case {105 106 107}
      numtrtrial = 3;  % special 6-s trials
    end
  case {119 120 121 122}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [256 256 26]./[80 80 26];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 4;            % stimulus duration
    tr = 2.003055;          % the TR
    numtrtrial = 3;         % number of TRs per stimulus trial
  case {84}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [256 256 26]./[80 80 26];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 3.5;            % stimulus duration
    tr = 2.003096;          % the TR
    numtrtrial = 2;         % number of TRs per stimulus trial
  case {75 76 79 86 87}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [256 256 26]./[80 80 26];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 5;            % stimulus duration
    tr = 2.006553;          % the TR
    numtrtrial = 3;         % number of TRs per stimulus trial
  case {80 81 82 83 85}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [256 256 26]./[80 80 26];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 5;            % stimulus duration
    tr = 2.003096;          % the TR
    numtrtrial = 3;         % number of TRs per stimulus trial
  case {77 78}
    roiasstradius = 2*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [256 256 26]./[80 80 26];  % DOES NOT HAVE TO BE INTEGRAL I THINK ???? % integral upsampling factor to go from functional to inplane
    stimdur = 3;            % stimulus duration
    tr = 2.006553;          % the TR
    numtrtrial = 4;         % number of TRs per stimulus trial
  otherwise
    roiasstradius = 2.5*sqrt(3)/2;  % radius in mm for sphere used in ROI assignment
    inplanefactor = [4 4 1];  % integral upsampling factor to go from functional to inplane
    stimdur = 3;            % stimulus duration
    tr = 1.337702;          % the TR
    numtrtrial = 6;         % number of TRs per stimulus trial
  end
  inplaneanatomy = [datadir '/dicoms/*T1*'];  % path to in-plane volume
  inplaneanatomyNII = [datadir '/*T1*/*.nii*'];
  meanfunctional = [datadir '/preprocess/mean.nii'];  % path to mean preprocessed functional volume
  switch x
  case {88 89 90 91 92 93 94 95 96 97 98 99 101 102 103 104 ...
        111 112 113 114 115 116 118}
    ignorenum = 0;
  otherwise
    ignorenum = 5;          % number of volumes that were ignored at the beginning of each run
  end
  switch x
  case {88 89}
    xyzsize = [116 116 42];   % matrix size of the data
  case {90 91 92 93 94 95 96 98 99 101 102 103 104 111 112}
    xyzsize = [80 80 28];   % matrix size of the data
  case {113 114 115 116 118}
    xyzsize = [80 80 58];   % matrix size of the data
  case {97}
    xyzsize = [128 104 42];  % matrix size of the data
  case {34}
    xyzsize = [64 64 21];   % matrix size of the data
  case {41 42 43 44 45 46 47 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 74 75 76 77 78 79 80 81 82 83 84 85 86 87 105 106 107 108 109 110 119 120 121 122}
    xyzsize = [80 80 26];   % matrix size of the data
  otherwise
    xyzsize = [64 64 22];   % matrix size of the data
  end
  switch x
  case {39 72 73}
    maxpolydeg = 2;         % maximum degree of polynomials to use for each run
  otherwise
    maxpolydeg = 4;         % maximum degree of polynomials to use for each run
  end
  maxpcnum = 10;          % maximum number of PCs to test out
  switch x
  case {88}
    nreps = 6;              % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {89}
    nreps = 8;              % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {90 91 92 93 94 95 96 98 99}
    nreps = 10;             % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {97}
    nreps = 5;              % number of run repetitions
    ndistinct = 2;          % number of distinct run types
  case {28 29 30 33 35 36 38}
    nreps = 3;              % number of run repetitions
    ndistinct = 4;          % number of distinct run types
  case {31 32 40}
    nreps = 10;             % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {34}
    nreps = 7;              % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {37}
    nreps = 6;              % number of run repetitions
    ndistinct = 2;          % number of distinct run types
  case {39}
    nreps = 15;             % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {72 73}
    nreps = 4;              % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {41}
    nreps = 10;             % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {42 43 44 45 46 47 50 51}
    nreps = 7;              % number of run repetitions
    ndistinct = 2;          % number of distinct run types
  case {52 53}
    nreps = 4;              % number of run repetitions
    ndistinct = 3;          % number of distinct run types
  case {54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 84}
    nreps = 3;              % number of run repetitions
    ndistinct = 4;          % number of distinct run types
  case {70 71 74 101 102 103 104 111 112 113 114 115 116 118}
    nreps = 4;              % number of run repetitions
    ndistinct = 3;          % number of distinct run types
  case {105 106 107}
    nreps = 6;              % number of run repetitions
    ndistinct = 2;          % number of distinct run types
  case {119 120 121 122}
    nreps = 12;             % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  case {108 109 110}
    nreps = 5;              % number of run repetitions
    ndistinct = 2;          % number of distinct run types
  case {75 76 79 80 81 82 83 85 86 87}
    nreps = 6;              % number of run repetitions
    ndistinct = 2;          % number of distinct run types
  case {48 49 77 78}
    nreps = 4;              % number of run repetitions
    ndistinct = 1;          % number of distinct run types
  otherwise  % dummy generic fallthrough
    nreps = 1;
    ndistinct = 1;
  end
    % resampling scheme for initial GLM model
  wantresampleglminitial = -[upsamplematrix(copymatrix(ones(nreps,nreps),logical(eye(nreps)),-1),ndistinct,2,[],'nearest')];
    % sub-select the runs?
  switch x
  case {54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 111 112 113 114 115 116 118}
    runix = 1:12;
  case {73}
    runix = 1:4;
  case {90 91}
    runix = 4:13;  % 1 is resting; 2-3 is localizer
  case {92 93 94}
    runix = 3:12;  % 1-2 is localizer
  case {97}
    runix = [];
  case {95 98 99}
    runix = 5:14;  % 1-4 is retinotopy
  case {96}
    runix = 1:10;
  otherwise
    runix = {1 ':'};
  end
    % function for loading the preprocessed data
  datafun = @() cellfun(@(x) squish(single(getfield(load_untouch_nii(x),'img')),3)', ...
                        subscript(matchfiles([datadir '/preprocess/run*.nii']),runix),'UniformOutput',0);
  datafunB = @() cellfun(@(x) single(getfield(load_untouch_nii(x),'img')), ...
                         subscript(matchfiles([datadir '/preprocess/run*.nii']),runix),'UniformOutput',0);
  datafunBRPP1 = @() cellfun(@(x) single(getfield(load_untouch_nii(x),'img')), ...  % i.e. remove 1:8 and pre-process
                         subscript(matchfiles([datadir '/preprocessRPP1/run*.nii']),runix),'UniformOutput',0);
  datafunBRPP2 = @() cellfun(@(x) single(getfield(load_untouch_nii(x),'img')), ...  % i.e. remove 1:12 and pre-process
                         subscript(matchfiles([datadir '/preprocessRPP2/run*.nii']),runix),'UniformOutput',0);

  if ~exist('numlh','var')
    numlh = [];
  end
  if ~exist('numrh','var')
    numrh = [];
  end

% DEPRECATED:
%   datafunBRAW = @() cellfun(@(x) single(getfield(load_untouch_nii(x),'img')), ...  % DEPRECATED
%                          subscript(matchfiles([datadir '/preprocessNONE/run*.nii']),runix),'UniformOutput',0);
  datafunV = @() cellfun(@(x) single(loadbinary(x,'int16',[numlh+numrh 0])), ...
                         subscript(matchfiles([datadir '/preprocessVERTICES/run*.nii']),runix),'UniformOutput',0);

  % retinotopy data (do it explicitly)
  if ismember(fmrisetupnum,[94 95 97 98 99 111 112 113 114 115 116 118])
    switch fmrisetupnum
    case 94
      retrunix = 13:16;
    case {95 98 99}
      retrunix = 1:4;
    case 97
      retrunix = 1:10;
    case {111 112 113 114 115 116 118}
      retrunix = 12+2+(1:2);
    end
    datafunRET = @() cellfun(@(x) single(loadbinary(x,'int16',[numlh+numrh 0])), ...
                           subscript(matchfiles([datadir '/preprocessVERTICES/run*.nii']),retrunix),'UniformOutput',0);
  end
  
  % special localizer files
  switch fmrisetupnum
  case {90 91 92 93}
    mainmat =        [outputdir '/GLMdenoiseVERTICES.mat'];
    localizermat =   [outputdir '/GLMlocalizer.mat'];
    localizerSMmat = [outputdir '/GLMlocalizerSM.mat'];
    retinotopymat  = [];
    retinotopymat1 = [];
    retinotopymat2 = [];
  case {94}
    mainmat =         [outputdir '/GLMdenoiseVERTICES.mat'];
    localizermat =    [outputdir '/GLMlocalizer.mat'];
    localizerSMmat =  [outputdir '/GLMlocalizerSM.mat'];
    retinotopymat =   [outputdir '/retinotopyFINAL.mat'];
    retinotopymat1 =  [outputdir '/retinotopyTEST.mat'];
    retinotopymat2 =  [outputdir '/retinotopyRETEST.mat'];
  case {95 98 99}
    mainmat =         [outputdir '/GLMdenoiseVERTICES.mat'];
    localizermat =    [];
    localizerSMmat =  [];
    retinotopymat =   [outputdir '/retinotopyFINAL.mat'];
    retinotopymat1 =  [outputdir '/retinotopyTEST.mat'];
    retinotopymat2 =  [outputdir '/retinotopyRETEST.mat'];
  case {96 101 102 103 104}
    mainmat =         [outputdir '/GLMdenoiseVERTICES.mat'];
    localizermat =    [];
    localizerSMmat =  [];
    retinotopymat  =  [];
    retinotopymat1 =  [];
    retinotopymat2 =  [];
  case {97}
    mainmat =         [];
    localizermat =    [];
    localizerSMmat =  [];
    retinotopymat =   [outputdir '/retinotopyFINAL.mat'];
    retinotopymat1 =  [outputdir '/retinotopyTEST.mat'];
    retinotopymat2 =  [outputdir '/retinotopyRETEST.mat'];
  case {100}
    mainmat =        [];
    localizermat =   [outputdir '/GLMlocalizer.mat'];
    localizerSMmat = [outputdir '/GLMlocalizerSM.mat'];
    retinotopymat  = [];
    retinotopymat1 = [];
    retinotopymat2 = [];
  case {111 112 113 114 115 116 118}   % USE THIS NOW!
    mainmat =         [outputdir '/GLMdenoiseVERTICESALT.mat'];
    localizermat =    [outputdir '/GLMlocalizer.mat'];
    localizerSMmat =  [outputdir '/GLMlocalizerSM.mat'];
    retinotopymat =   [outputdir '/retinotopyFINAL.mat'];
    retinotopymat1 =  [outputdir '/retinotopyTEST.mat'];
    retinotopymat2 =  [outputdir '/retinotopyRETEST.mat'];
  end
  
  % special pointer files
  switch fmrisetupnum
  case 91
    expMpointer = '/home/knk/ext/datasets/20140505S017/';
    expLpointer = '/home/knk/ext/datasets/20140505S017/';
    expCpointer = '/home/knk/ext/datasets/20140623S017/';
    expDpointer = '/home/knk/ext/datasets/20140721S017/';
    expRpointer = '/home/knk/ext/datasets/20140623S017/';
  case 92
    expMpointer = '/home/knk/ext/datasets/20140512S018/';
    expLpointer = '/home/knk/ext/datasets/20140512S018/';
    expCpointer = '/home/knk/ext/datasets/20140605S018/';
    expDpointer = '/home/knk/ext/datasets/20140810S018/';
    expRpointer = '/home/knk/ext/datasets/20140605S018/';
  case 93
    expMpointer = '/home/knk/ext/datasets/20140602S019/';
    expLpointer = '/home/knk/ext/datasets/20140602S019/';
    expCpointer = '/home/knk/ext/datasets/20140707S019/';
    expDpointer = '/home/knk/ext/datasets/20140727S019/';
    expRpointer = '/home/knk/ext/datasets/20140707S019/';
  case 94
    expMpointer = '/home/knk/ext/datasets/20140605S015/';
    expLpointer = '/home/knk/ext/datasets/20140605S015/';
    expCpointer = '/home/knk/ext/datasets/20140608S015/';
    expDpointer = '/home/knk/ext/datasets/20140814S015/';
    expRpointer = '/home/knk/ext/datasets/20140605S015/';
  case {111 112 113 114 115 116 118}
    expMpointer = [];
    expLpointer = outputdir;
    expCpointer = [];
    expDpointer = outputdir;
    expRpointer = outputdir;
  end
  
  switch x
  case {31 32}
    wantblankstim = 1;     % whether to explicitly model one blank event
  otherwise
    wantblankstim = 0;     % whether to explicitly model one blank event
  end
  switch x
  case {28 29 30 33 35 36 38}
    infofile = '/home/knk/ext/info/multiclassinfo_monster.mat';   % where is the stimulus info file
  case {31 32}
    infofile = '/home/knk/ext/info/multiclassinfo_monsterB.mat';   % where is the stimulus info file
  case {34}
    infofile = '/home/knk/ext/info/multiclassinfo_subadd.mat';   % where is the stimulus info file
  case {39 72 73}
    infofile = '/home/knk/ext/info/multiclassinfo_monstersub.mat';   % where is the stimulus info file
  case {37}
    infofile = '/home/knk/ext/info/multiclassinfo_monstertest.mat';   % where is the stimulus info file
  case {40}
    infofile = '/home/knk/ext/info/multiclassinfo_monstertestB.mat';   % where is the stimulus info file
  case {41}
    infofile = '/home/knk/ext/info/multiclassinfo_category.mat';   % where is the stimulus info file
  case {42 43 44 45}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC3.mat';   % where is the stimulus info file
  case {46 47 50 51}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC4.mat';   % where is the stimulus info file
  case {52}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC5.mat';   % where is the stimulus info file
  case {53}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC6.mat';   % where is the stimulus info file
  case {54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 84}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC7.mat';   % where is the stimulus info file
  case {70 71 74 105 106 107 108 109 110}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC8.mat';   % where is the stimulus info file
  case {119 120 121 122}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC10.mat';   % where is the stimulus info file
  case {75 76 79 80 81 82 83 85 86 87}
    infofile = '/home/knk/ext/info/multiclassinfo_categoryC9.mat';   % where is the stimulus info file
  case {48 49 77 78}
    infofile = '/home/knk/ext/info/multiclassinfo_monstertestBALT.mat';   % where is the stimulus info file
  case {88 97}
    infofile = [];
  case {89}
    infofile = '/home/knk/ext/info/multiclassinfo_readingALT.mat';   % where is the stimulus info file
  case {90 91 92 93 94 95 96 98 99}
    infofile = '/home/knk/ext/info/multiclassinfo_readingBalt.mat';   % where is the stimulus info file
  case {101 102 103 104 ...
        111 112 113 114 115 116 118}
    infofile = '/home/knk/ext/info/multiclassinfo_readingD.mat';   % where is the stimulus info file
  end
    % get the design matrix for the GLM
  switch x
  case {88}
    files0 = matchfiles([datadir '/Stimuli/*experimentrun*.mat']);
    stimulus = {};
    for kk=1:length(files0)
      stimulus(kk) = processglmdesign(files0{kk},files0{kk},numtrtrial,ignorenum,wantblankstim);
    end
  case {105 106 107 119 120 121 122}  % specially handled
    stimulusfiles = matchfiles([datadir '/Stimuli/*run*.mat']);
    stimulus = {};
    for kk=1:length(stimulusfiles)
      tt1 = load(stimulusfiles{kk});
      stimulus{kk} = upsamplematrix(tt1.designmatrix,numtrtrial,1);
    end
  otherwise
    stimulusfiles = matchfiles([datadir '/Stimuli/*run*.mat']);
    ix = cellfun(@(x)isempty(regexp(x,'MASTER')),stimulusfiles);
    stimulusfiles = stimulusfiles(ix);  % KILL MASTER FILES
    ix = cellfun(@(x)isempty(regexp(x,'expYL')) & isempty(regexp(x,'exp105')) & isempty(regexp(x,'exp106')),stimulusfiles);
    stimulusfiles = stimulusfiles(ix);  % KILL YL AND RET FILES
    cellfun(@disp,stimulusfiles);
    if ~isempty(stimulusfiles)
      stimulus = processglmdesign(stimulusfiles,infofile,numtrtrial,ignorenum,wantblankstim);
    end
  end
    % deal with special case of stimulus handling
  switch x
  case {70 71 74 101 102 103 104 108 109 110 111 112 113 114 115 116 118}
    numtime0 = size(stimulus{1},1);
    numcond0 = size(stimulus{1},2);
    for rr=1:nreps
      for ss=1:ndistinct
        stimulus{(rr-1)*ndistinct+ss} = placematrix(zeros(numtime0,numcond0*ndistinct),full(stimulus{(rr-1)*ndistinct+ss}),[1 1+(ss-1)*numcond0]);
      end
    end
  otherwise
  end
    % resampling scheme for GLM boot
  wantresampleglmboot = {-30 sum(100*clock) repmat(1:ndistinct,[1 nreps])};
  bootgroups = repmat(1:ndistinct,[1 nreps]);
    % spline-based HRF model
  hrfmodel = {[.5 1 1 .5 zeros(1,6)] [repmat(-Inf,[1 10]); repmat(Inf,[1 10])] @(pp) spline([0 2.5:2.5:20 30 40 50]/tr,[0 pp 0],0:floor(50/tr))' 1};
    % function that loads the PC regressors  [this is obsolete, so bracket with an exist statement]
  if exist('pcnum','var')
    pcfun = @() cellfun(@(x) double(x(:,1:pcnum)),loadmulti([outputdir '/pcanalysis/results.mat'],'pcregressors'),'UniformOutput',0);
  end
    % function that estimates the peak of the HRF (using interpolation).
    % this peak value is divided from the HRF in order to normalize it.
  switch x
  case {28 29 30 31 32 33 34 35 36}
    hrfnormfun = @(x) calcpeak(x(1+(ceil(4/tr):floor(9/tr))),[],'cubic',[],signforce(sum(x(1+(0:floor(15/tr))))));  % OLD
  otherwise
    hrfnormfun = @(x) calcpeak(x(1+(ceil(2/tr):floor(10/tr))),[],'cubic',[],signforce(sum(x(1+(ceil(2/tr):floor(10/tr))))));  % NEW
  end
    % function for loading individual voxels' preprocessed data
  dataindfun = @(vxs) niiload([datadir '/preprocess/run*.nii'],vxs,'double');

  % we changed this mid-way. hack this in for the .mat file summary.
  switch x
  case {30 36}
    hrfnormfunHACK = @(x) calcpeak(x(1+(ceil(2/tr):floor(10/tr))),[],'cubic',[],signforce(sum(x(1+(ceil(2/tr):floor(10/tr))))));
  otherwise
    hrfnormfunHACK = [];
  end
  
  % bad runs to omit when doing GLM boot
  switch x
  case {31}
    badruns = [3 4 5];
  otherwise
    badruns = [];
  end
  
    % do we have to flip the stimuli?
  switch x
  case {28 29 30}
    stimflips = [1 0];
  otherwise
    stimflips = [0 0];
  end
  
  switch x
  case {28 29 30 33 35 36 38}
      % function that loads in all the PRF contrast images (69 x 150^2)
    prfstimfun = @() squish(flipdims(normalizerange(processmulti(@imresize, ...
                      subscript(catcell(3,loadmulti('/home/knk/ext/stimuli.final/workspaces/workspace_monster.mat','conimages')), ...
                                {':' ':' 1:69}), ...
                      [150 150],'cubic'),0,1,0,1),stimflips),2)';
      % resolution of these images
    prfstimres = 150;
      % the location of the borders
    prfstimborders = (loadmulti('/home/knk/ext/stimuli.final/workspaces/workspace_monster.mat','borders') - 0.5)/256 * prfstimres + 0.5;
    prfstimbordersWN = prfstimborders([1 6 8 9 10 12 17]);
  
      % function that loads in the pre-processed stimuli (156 x channels x 9)
    if isequal(stimflips,[1 0])
        % OLD: gabordivnew
      generalstimfun = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/flipud/gaborcanonical.mat','images'));
      generalstimfunB = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/flipud/gabormap.mat','images'));
      generalstimfunBboot = @() single(subscript(loadmulti('/home/knk/ext/datasets/stimulusprep/flipud/gabormap.mat','images'),{1:99 ':' ':'}));
      generalstimfunC = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/flipud/gabormapLC.mat','images'));
      generalstimfunD = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/flipud/gabormapOV.mat','images'));
      generalstimfunE = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/flipud/gabormapDC.mat','images'));
    elseif isequal(stimflips,[0 0])
        % OLD: gabordivnew
      generalstimfun = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/regular/gaborcanonical.mat','images'));
      generalstimfunB = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/regular/gabormap.mat','images'));
      generalstimfunBboot = @() single(subscript(loadmulti('/home/knk/ext/datasets/stimulusprep/regular/gabormap.mat','images'),{1:99 ':' ':'}));
      generalstimfunC = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/regular/gabormapLC.mat','images'));
      generalstimfunD = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/regular/gabormapOV.mat','images'));
      generalstimfunE = @() single(loadmulti('/home/knk/ext/datasets/stimulusprep/regular/gabormapDC.mat','images'));
    else
      die;
    end
    generalstimres = 90;  % on Jan 22, 2012, changed to 90

      % functions that load in the beta weights for the PRF modeling
    betafile = [outputdir '/glmboot.mat'];
    betafileC = [outputdir '/glmroiaverage.mat'];
    prfdatafun_full = @(vxs) subscript(loadmulti(betafile,'betamn'),{ismember(loadmulti(betafile,'vxs'),vxs) 1:69});
    prfdatafun_boot = @(vxs) subscript(loadmulti(betafile,'betas'),{ismember(loadmulti(betafile,'vxs'),vxs) 1:69 ':'});
    generaldatafun_full = @(vxs) subscript(loadmulti(betafile,'betamn'),{ismember(loadmulti(betafile,'vxs'),vxs) ':'});
    generaldatasefun_full = @(vxs) subscript(loadmulti(betafile,'betase'),{ismember(loadmulti(betafile,'vxs'),vxs) ':'});
    generaldatafun_boot = @(vxs) subscript(loadmulti(betafile,'betas'),{ismember(loadmulti(betafile,'vxs'),vxs) ':' ':'});
    generaldatafun_bootsub = @(vxs) subscript(loadmulti(betafile,'betas'),{ismember(loadmulti(betafile,'vxs'),vxs) 1:99 ':'});
    roidatafun_full = @(vxs) real(subscript(loadmulti(betafileC,'betas'),{vxs ':'}));
    roidatasefun_full = @(vxs) imag(subscript(loadmulti(betafileC,'betas'),{vxs ':'}));

    switch x
    case {38}
        % functions that load in the beta weights for special average-across-datasets case
      betafileB = [outputdir '/glmsuperaverage.mat'];
      specialv1datafun_full = @(vxs) subscript(loadmulti(betafileB,'betas'),{vxs ':' ':'});
    end

      % helpful labels
    stimcbs = [69.5 77.5 89.5 99.5 106.5 111.5 115.5 139.5];  % removed 31.5 62.5 
    stimlocs = [(1+69)/2 (70+77)/2 (78+89)/2 (90+99)/2 (100+106)/2 (107+111)/2 (112+115)/2 (116+139)/2 (140+156)/2];
    stimlabels = {'PRF' 'OR' 'V1CON' 'CON' 'CLASS' 'SPARSE' 'SCALE' 'V1PRF' '2ND'};

      % cross-validation stuff
            % mat2str(permutedim(subscript(flatten(repmat(1:5,[ceil(156/5) 1])'),1:156)))
            % mat2str(permutedim(subscript(flatten(repmat(1:10,[ceil(156/10) 1])'),1:156)))
    generalresample5 = [3 4 2 1 3 4 2 4 4 1 4 5 2 2 3 2 2 3 3 1 1 3 2 2 1 5 3 4 1 5 1 2 5 5 4 5 1 2 5 1 4 3 3 2 2 2 3 3 5 3 3 5 2 3 3 1 5 1 1 1 4 4 4 5 1 1 4 5 2 3 3 5 2 5 5 1 2 4 2 3 4 5 5 1 3 1 4 1 5 5 5 1 2 2 4 1 2 3 4 4 1 3 1 5 1 3 3 4 1 4 2 3 5 3 4 2 1 5 2 5 4 4 1 4 3 1 5 5 4 4 2 2 1 3 2 1 4 3 5 2 4 5 4 3 2 3 3 2 4 1 5 5 1 2 4 5];
    generalresample = [10 1 9 2 8 4 8 1 10 7 7 5 4 1 5 5 10 1 6 5 6 10 9 1 2 3 6 7 3 7 3 5 4 1 6 7 7 3 2 4 1 1 8 5 10 3 7 1 8 4 3 9 8 2 4 8 2 8 10 6 4 6 9 6 8 9 8 9 10 4 7 4 1 1 10 4 6 2 6 3 5 8 3 2 6 9 5 8 3 6 9 9 2 4 3 6 3 5 7 6 2 9 2 3 10 2 4 9 8 8 9 2 9 2 1 10 1 5 5 10 6 5 3 3 5 7 6 2 10 3 10 6 4 10 9 7 5 3 5 5 1 4 1 9 8 4 7 7 4 7 2 10 8 7 1 2];
    generalresamplePF = [zeros(1,69) ones(1,156-69)];
%     M =  [-ones(1,20) ones(1,79);
%           ones(1,20) -ones(1,20) ones(1,59);
%           ones(1,40) -ones(1,20) ones(1,39);
%           ones(1,60) -ones(1,20) ones(1,19);
%           ones(1,80) -ones(1,19)];
%     M = [M zeros(5,156-99)];
%     M = -M;
%     ix = randperm(99);
%     M(:,1:99) = M(:,ix);
%     mat2str(M)
    generalresampleXV = [-1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 1 -1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 1 -1 1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 -1 1 -1 -1 -1 -1 -1 1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 1 -1 -1 -1 -1 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0;-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 1 1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 -1 -1 -1 -1 -1 1 -1 -1 1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 1 -1 -1 1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 1 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0;-1 -1 -1 -1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 1 1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 -1 -1 -1 1 -1 -1 1 -1 1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 -1 1 -1 -1 -1 1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0;1 -1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 1 1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 1 -1 -1 1 1 -1 -1 -1 -1 -1 1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0;-1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 -1 -1 -1 -1 1 -1 -1 -1 -1 1 -1 -1 -1 -1 -1 1 -1 -1 -1 1 -1 -1 -1 -1 1 -1 -1 -1 1 -1 1 -1 -1 -1 1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 1 1 -1 -1 1 -1 1 -1 -1 1 -1 1 -1 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0 -0];
    stimordering = zeros(1,length(generalresample5));  % this tells us what order stimuli show up in the model results
    dummycnt = 0;
    for ddd=1:max(generalresample5)
      nnn = count(generalresample5==ddd);
      stimordering(generalresample5==ddd) = dummycnt+(1:nnn);
      dummycnt = dummycnt + nnn;
    end
    itemp = [];
    for ccc=1:size(generalresampleXV,1)
      itemp = [itemp find(generalresampleXV(ccc,:)==1)];
    end
    stimorderingXV = calcposition(itemp,1:99);
    
      % display stuff
    stimcont = [31 31 7 8 4 4 4 10 7 5 4 11 11 2 17];
    stimcontrng = {};
    for ddd=1:length(stimcont)
      stimcontrng{ddd} = sum(stimcont(1:ddd-1)) + (1:stimcont(ddd));
    end
    
      % flipping issues
    stimrflip = 1:156;
    switch x
    case {28 29 30}
      % for example, the 32th stimuli shown to MP is actually the 62th real stimulus
      %   so, by after applying stimrflip, things are sane except that the special cut is actually located a little below
      stimrflip([62:-1:32 77:-1:71 137:-1:127  141 140  144 143  146 145  149 148  152 151  154 153  156 155]) = [32:62 71:77 127:137  140 141  143 144  145 146  148 149  151 152  153 154  155 156];
    end

% COMMENTED THIS OUT.  WHY RELY?    
%       % parameter values [NEED TO UPDATE]
%     ees = [.01 .05 .1 .2 .3 .4 .5 .7 1];
%     sss = [0.01 0.02 0.05 0.1 0.2 0.5 1 2 4 8 16];
%     v2sds = [0.4 0.5 0.6 0.7 0.8 0.9 1 1.5 2 3];
%     cs = [0 0.5 0.7 0.8 0.85 0.9 0.95 1];
%     ns = [0.1 0.3 0.4 0.5 0.6 0.7 1 1.25 1.5 1.75 2 2.5 3];
    
      % the special horizontal line [make relative to the prfstimres setup in matrix units]
    switch x
    case {28 29 30}
      summationline = normalizerange(152.803008813305,0.5,prfstimres+0.5,0.5,256.5);
    otherwise
      summationline = normalizerange(152.803008813305,prfstimres+0.5,0.5,0.5,256.5);  % the default way actually flips!
    end
    
  case {37 40 41 42 43 44 45 46 47 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 74 75 76 79 80 81 82 83 84 85 86 87 105 106 107 108 109 110}

    switch x
    case {44 45}

        % function that loads in all the PRF contrast images (52 x 80^2)
      prfstimfun = @() squish(flipdims(normalizerange(processmulti(@imresize, ...
                        subscript(catcell(3,loadmulti('/home/knk/ext/stimuli.final/workspaces/workspace_categoryC3.mat','conimages')), ...
                                  {':' ':' 1:52}), ...
                        [80 80],'cubic'),0,1,0,1),stimflips),2)';
        % resolution of these images
      prfstimres = 80;
        % functions that load in the beta weights for the PRF modeling
      betafile = [outputdir '/initialglmboot.mat'];
      prfdatafun_full_face = @(vxs) subscript(squish(loadmulti(betafile,'mn'),3),{vxs 1:52});
      prfdatafun_full_hand = @(vxs) subscript(squish(loadmulti(betafile,'mn'),3),{vxs 53:104});

    case {46 47 50 51}

        % function that loads in all the PRF contrast images (49 x 80^2)
      prfstimfun = @() loadmulti('/home/knk/ext/stimulipreprocess/C4con.mat','stim');
      prfstimfunALL = @() repmat(feval(prfstimfun),[2 1]);
        % resolution of these images
      prfstimres = 80;
        % functions that load in the beta weights for the PRF modeling
      binfilemd = [outputdir '/GLMdenoisemodelmd.bin'];
      binfilese = [outputdir '/GLMdenoisemodelse.bin'];
      binfiles = [outputdir '/GLMdenoisemodels.bin'];
      prfdatafun_full_face = @(vxs) double(subscript(loadbinary(binfilemd,'single',[98 prod(xyzsize)],-vxs),{1:49 ':'})');
      prfdatafun_full_hand = @(vxs) double(subscript(loadbinary(binfilemd,'single',[98 prod(xyzsize)],-vxs),{49+(1:49) ':'})');
      prfdatafun_full_all = @(vxs) double(subscript(loadbinary(binfilemd,'single',[98 prod(xyzsize)],-vxs),{':' ':'})');
      prfdatasefun_full_face = @(vxs) double(subscript(loadbinary(binfilese,'single',[98 prod(xyzsize)],-vxs),{1:49 ':'})');
      prfdatasefun_full_hand = @(vxs) double(subscript(loadbinary(binfilese,'single',[98 prod(xyzsize)],-vxs),{49+(1:49) ':'})');
      prfdatasefun_full_all = @(vxs) double(subscript(loadbinary(binfilese,'single',[98 prod(xyzsize)],-vxs),{':' ':'})');
      prfdatafun_boot_face = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[98 100 prod(xyzsize)],-vxs),{1:49 ':' ':'}),[3 1 2]));
      prfdatafun_boot_hand = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[98 100 prod(xyzsize)],-vxs),{49+(1:49) ':' ':'}),[3 1 2]));
      prfdatafun_boot_all = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[98 100 prod(xyzsize)],-vxs),{':' ':' ':'}),[3 1 2]));

    case {52}

        % function that loads in all the PRF contrast images (49*3 x 80^2)
      prfstimfunALL = @() loadmulti('/home/knk/ext/stimulipreprocess/C5con.mat','stim');
      prfstimfunALLalt = @() repmat(subscript(loadmulti('/home/knk/ext/stimulipreprocess/C5con.mat','stim'),{1:49 ':'}),[3 1]);
        % resolution of these images
      prfstimres = 80;
        % functions that load in the beta weights for the PRF modeling
      binfilemd = [outputdir '/GLMdenoisemodelmd.bin'];
      binfilese = [outputdir '/GLMdenoisemodelse.bin'];
      binfiles = [outputdir '/GLMdenoisemodels.bin'];
      prfdatafun_full_size1 = @(vxs) double(subscript(loadbinary(binfilemd,'single',[49*3 prod(xyzsize)],-vxs),{1:49 ':'})');
      prfdatafun_full_size2 = @(vxs) double(subscript(loadbinary(binfilemd,'single',[49*3 prod(xyzsize)],-vxs),{49+(1:49) ':'})');
      prfdatafun_full_size3 = @(vxs) double(subscript(loadbinary(binfilemd,'single',[49*3 prod(xyzsize)],-vxs),{49*2+(1:49) ':'})');
      prfdatafun_full_all = @(vxs) double(subscript(loadbinary(binfilemd,'single',[49*3 prod(xyzsize)],-vxs),{':' ':'})');
      prfdatasefun_full_size1 = @(vxs) double(subscript(loadbinary(binfilese,'single',[49*3 prod(xyzsize)],-vxs),{1:49 ':'})');
      prfdatasefun_full_size2 = @(vxs) double(subscript(loadbinary(binfilese,'single',[49*3 prod(xyzsize)],-vxs),{49+(1:49) ':'})');
      prfdatasefun_full_size3 = @(vxs) double(subscript(loadbinary(binfilese,'single',[49*3 prod(xyzsize)],-vxs),{49*2+(1:49) ':'})');
      prfdatasefun_full_all = @(vxs) double(subscript(loadbinary(binfilese,'single',[49*3 prod(xyzsize)],-vxs),{':' ':'})');
      prfdatafun_boot_size1 = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[49*3 100 prod(xyzsize)],-vxs),{1:49 ':' ':'}),[3 1 2]));
      prfdatafun_boot_size2 = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[49*3 100 prod(xyzsize)],-vxs),{49+(1:49) ':' ':'}),[3 1 2]));
      prfdatafun_boot_size3 = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[49*3 100 prod(xyzsize)],-vxs),{49*2+(1:49) ':' ':'}),[3 1 2]));
      prfdatafun_boot_all = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[49*3 100 prod(xyzsize)],-vxs),{':' ':' ':'}),[3 1 2]));

    case {53}

        % function that loads in all the PRF contrast images (165 x 80^2)
      prfstimfunALL = @() loadmulti('/home/knk/ext/stimulipreprocess/C6con.mat','stim');
      prfstimfunALLalt = @() subscript(loadmulti('/home/knk/ext/stimulipreprocess/C6con.mat','stim'),{1:49 ':'});
        % resolution of these images
      prfstimres = 80;
        % functions that load in the beta weights for the PRF modeling
      binfilemd = [outputdir '/GLMdenoisemodelmd.bin'];
      binfilese = [outputdir '/GLMdenoisemodelse.bin'];
      binfiles = [outputdir '/GLMdenoisemodels.bin'];
      prfdatafun_full_all = @(vxs) double(subscript(loadbinary(binfilemd,'single',[165 prod(xyzsize)],-vxs),{':' ':'})');
      prfdatasefun_full_all = @(vxs) double(subscript(loadbinary(binfilese,'single',[165 prod(xyzsize)],-vxs),{':' ':'})');
      prfdatafun_boot_all = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[165 100 prod(xyzsize)],-vxs),{':' ':' ':'}),[3 1 2]));
    
    case {54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 74 75 76 79 80 81 82 83 84 85 86 87 105 106 107 108 109 110}  % FILL ME IN
    
      %%%% FILL IN [from 53]
        % function that loads in contrast images (stim x 80^2)
      prfstimfun_all = @() loadmulti('/home/knk/ext/stimulipreprocess/C7con.mat','stim');
      if ismember(x,[71 70 74 105 106 107 108 109 110])
        prfstimfun_all = @() repmat(loadmulti('/home/knk/ext/stimulipreprocess/C8con.mat','stim'),[3 1]);
      end
      if ismember(x,[75 76 79 80 81 82 83 85 86 87])
        fprintf('FIX ME prfstimfun_all');
      end
      prfstimres = 80;
        % functions that load in beta weights
      binfilemd = [outputdir '/GLMdenoisemodelmd.bin'];
      if ismember(fmrisetupnum,[80 75 76])
        binfilemdALT = [outputdirALT '/GLMdenoisemodelmd.bin'];
      end
      binfilese = [outputdir '/GLMdenoisemodelse.bin'];
      binfiles = [outputdir '/GLMdenoisemodels.bin'];
      prfdatafun_full_all = @(vxs) double(subscript(loadbinary(binfilemd,'single',[numstim prod(xyzsize)],-vxs),{':' ':'})');
      prfdatasefun_full_all = @(vxs) double(subscript(loadbinary(binfilese,'single',[numstim prod(xyzsize)],-vxs),{':' ':'})');
      prfdatafun_boot_all = @(vxs) double(permute(subscript(loadbinary(binfiles,'single',[numstim 100 prod(xyzsize)],-vxs),{':' ':' ':'}),[3 1 2]));

    end

      % functions that load in the beta weights for the PRF modeling
    betafile = [outputdir '/glmboot.mat'];
    generaldatafun_full = @(vxs) subscript(loadmulti(betafile,'betamn'),{ismember(loadmulti(betafile,'vxs'),vxs) ':'});
    generaldatasefun_full = @(vxs) subscript(loadmulti(betafile,'betase'),{ismember(loadmulti(betafile,'vxs'),vxs) ':'});
    generaldatafun_boot = @(vxs) subscript(loadmulti(betafile,'betas'),{ismember(loadmulti(betafile,'vxs'),vxs) ':' ':'});

      % helpful labels
    switch x

    case {37}
      stimcbs = [5.5 17.5 29.5 34.5 39.5 45.5 54.5 59.5];
      stimlocs = [(1+5)/2 (6+17)/2 (18+29)/2 (30+34)/2 (35+39)/2 (40+45)/2 (46+54)/2 (55+59)/2 (60+64)/2];
      stimlabels = {'GAIN' 'OBJ' 'NAT' 'PHSCR' 'NOISE' 'TRAD' 'ARRAY' 'ANG' 'CONNOR'};
    case {40 41 42 43 44 45 46 47 50 51}

    end

  case {39 72 73}

    prfstimres = 150;
    stimrflip = 1:9;
    summationline = normalizerange(152.803008813305,prfstimres+0.5,0.5,0.5,256.5);  % the default way actually flips!

  end

  switch x
  case 101
    taskreorderD = {24*2+(1:24)  24+(1:24)    1:24};
  case 102
    taskreorderD = {1:24         24*2+(1:24)  24+(1:24)};
  case 103
    taskreorderD = {24+(1:24)    1:24         24*2+(1:24)};
  case 104
    taskreorderD = {24+(1:24)    24*2+(1:24)  1:24};
  case 111   % NOTE THESE REFLECT THE BLANK TRIAL VERSION....
    taskreorderD = {25*2+(1:24)  (1:24)      25+(1:24)};
  case 112
    taskreorderD = {(1:24)      25+(1:24)     25*2+(1:24)  };
  case 113
    taskreorderD = {25*2+(1:24)  25+(1:24)     (1:24)      };
  case 114
    taskreorderD = { (1:24)    25*2+(1:24)      25+(1:24)};
  case 115
    taskreorderD = {25+(1:24)   (1:24)        25*2+(1:24)      };
  case 116
    taskreorderD = {25+(1:24)   25*2+(1:24)   (1:24)      };
  case 118
    taskreorderD = {25*2+(1:24)  (1:24)      25+(1:24)};
  end

otherwise
  fprintf('no fmrisetup\n');

end

% MASTER COLOR DEFINITION
masterroicolors =                  {'E67373' '14CCCC' '12B3B3' '15CC15' '12B312' 'BF4195' 'AC73E6' '5F4080'};
masterroilabels =                  {'V1'     'V2d'    'V2v'    'V3d'    'V3v'    'hV4'    'VO1'    'VO2'   };
masterroicolors = [masterroicolors {'CC0000' '990000' '660000' '330000' '1A0000'} ...
                                   {'5C89E6' '476BB3' '334C80' '1E2D4D' '0F1626'} ...
                                   {'5BE566' '47B350'}];
masterroilabels = [masterroilabels {'FACE1'  'FACE2'  'FACE3'  'FACE4'  'FACE5'} ...
                                   {'WORD1'  'WORD2'  'WORD3'  'WORD4'  'WORD5'} ...
                                   {'WEIRD1' 'WEIRD2'}];
nummasterroi = length(masterroilabels);

% construct master roi colormap [UPDATE masterroicolormap.m]
masterroicolormap = [0 0 0];  % first color is black
for x=1:length(masterroicolors)
  masterroicolormap = [masterroicolormap; rgbconv(masterroicolors{x})];
end

% THIS WAS THE OLD WAY:
% % finalize the ROI assignments
% if exist('subjectid','var')
%   finalroilabels =    [masterroilabels(1:8) {'OFA' 'FFA1' 'FFA2' 'VWFA1' 'VWFA1b' 'VWFA2'}];
%   finalroiindices = {};
%   finalroiindices{1} = {1 2 3 4 5 6 7 8};  % LH
%   finalroiindices{2} = {1 2 3 4 5 6 7 8};  % RH
%   switch subjectid
%   case 'S015'
%     finalroiindices{1} = [finalroiindices{1} {[9 10]  11 12         14 15 16}];
%     finalroiindices{2} = [finalroiindices{2} {9       10 11         [] [] []}];
%   case 'S016'
%     finalroiindices{1} = [finalroiindices{1} {9       10 11         14 [] 15}];
%     finalroiindices{2} = [finalroiindices{2} {10      11 12         14 [] []}];
%   case 'S017'
%     finalroiindices{1} = [finalroiindices{1} {10      11 12         14 15 16}];
%     finalroiindices{2} = [finalroiindices{2} {9       10 11         14 [] []}];
%   case 'S018'
%     finalroiindices{1} = [finalroiindices{1} {9       10 11         15 16 17}];
%     finalroiindices{2} = [finalroiindices{2} {9       10 11         14 [] []}];
%   case 'S019'
%     finalroiindices{1} = [finalroiindices{1} {[9 10]  11 [12 13]    14 [] 15}];
%     finalroiindices{2} = [finalroiindices{2} {9       10 [11 12]    14 [] []}];
%   end
% end

% ROI information
finalisretino = [ones(1,6) zeros(1,12) zeros(1,4)];
finalroilabels = { 'V1'      'V2'      'V3'       'hV4'       'VO1'       'VO2' ...
                   'LH_OFA'  'LH_FFA1' 'LH_FFA2'  'LH_VWFA1'  'LH_VWFA1b' 'LH_VWFA2' ...
                   'RH_OFA'  'RH_FFA1' 'RH_FFA2'  'RH_VWFA1'  'RH_VWFA1b' 'RH_VWFA2' ...
                   'LH_FFA'  'LH_VWFA' 'RH_FFA'   'RH_VWFA'};

% finalize the ROI assignments
if exist('subjectid','var')
  finalroiindices = {[1 -1] [2 3 -2 -3] [4 5 -4 -5] [6 -6] [7 -7] [8 -8]};
  switch subjectid
  case 'S015'
    finalroiindices = [finalroiindices {[9 10]  11  12         14 15 16 ...
                                        -9     -10 -11         [] [] [] ...
                                        [11 12] [14 15 16] [-9 -10 -11] []}];
  case 'S016'
    finalroiindices = [finalroiindices {9       10  11         14 [] 15 ...
                                       -10     -11 -12        -14 [] [] ...
                                       [10 11] [14 15] [-11 -12] [-14]}];
  case 'S017'
    finalroiindices = [finalroiindices {10      11  12         14 15 16 ...
                                        -9     -10 -11        -14 [] [] ...
                                        [11 12] [14 15 16] [-10 -11] [-14]}];
  case 'S018'
    finalroiindices = [finalroiindices {9       10  11         15 16 17 ...
                                       -9      -10 -11        -14 [] [] ...
                                       [10 11] [15 16 17] [-10 -11] [-14]}];
  case 'S019'
    finalroiindices = [finalroiindices {[9 10]  11  [12 13]    14 []  15 ...
                                        -9     -10 -[11 12]   -14 [] -15 ...
                                        [11 12 13] [14 15] [-10 -11 -12] [-14 -15]}];
  case 'S020'
    finalroiindices = [finalroiindices {9  10  11  14 []  15 ...
                                        [] []  -9 -14 [] -15 ...
                                        [10 11] [14 15] [-9] [-14 -15]}];
  case 'S021'
    finalroiindices = [finalroiindices {[]  9  10 15 16 17 ...
                                       -9 -10 -11 [] [] [] ...
                                       [9 10] [15 16 17] [-10 -11] []}];
  case 'S022'
    finalroiindices = [finalroiindices {[]  9  10 14 [] 15 ...
                                       -9 -10 -11 [] [] [] ...
                                       [9 10] [14 15] [-10 -11] []}];
  case 'S023'
    finalroiindices = [finalroiindices {9  10  11  14 15 16 ...
                                       -9 -10 -11 -14 [] [] ...
                                       [10 11] [14 15 16] [-10 -11] [-14]}];
  case 'S024'
    finalroiindices = [finalroiindices {9  10  11 [] [] [] ...
                                       -9 -10 -11 [] [] [] ...
                                       [10 11] [] [-10 -11] []}];
  case 'S025'
    finalroiindices = [finalroiindices {9  10  []  15 [] [] ...
                                        [] -9 -10 -14 [] [] ...
                                        [10] [15] [-9 -10] [-14]}];
  case 'S027'
    finalroiindices = [finalroiindices {9 10 11  14  [] 15 ...
                                       [] -9 -10 -14 [] [] ...
                                       [10 11] [14 15] [-9 -10] [-14]}];
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SOME EXPERIMENT LEVEL STUFF

% define
stimlabels = {'WORD' ...
              '5WORD' ...
              'PSEUDO' ...
              'CONSONANT' ...
              'WINGDINGS' ...
              'GREEK' ...
              'CHINESE' ...
              'POLYGON' ...
              'SYMBOLS' ...
              'ANGLES' ...
              '180ROT' ...
              'PCOH0' ...
              'PCOH25' ...
              'PCOH50' ...
              'PCOH75' ...
              'PCOH100' ...
              'ACOH0' ...
              'ACOH25' ...
              'ACOH50' ...
              'ACOH75' ...
              'ACOH100' ...
              'OR0' ...
              'OR45' ...
              'OR90' ...
              'OR135' ...
              'SF1' ...
              'SF2' ...
              'SF3' ...
              'SF4' ...
              'SF5' ...
              'GRATING' ...
              'NOISE' ...
              'CHECKER' ...
              'FACE'};  % 1 x 34 with the word labels
stimindices = [1:15 1 16:19 1 20:23 24:28 29:32];  % artificially inflates
stimlabelsLOC = {'WORD' 'SCRAMBLE' 'FACE' 'OBJECT'};
stimindicesLOC = 1:4;
stimlabelsC = {'5WORD' ...
               'CHECKER' ...
               'FACE' ...
               '5WORD' ...
               'FACEO' ...
               '180ROT' ...
               'PCOH0' ...
               'PCOH25' ...
               'PCOH50' ...
               'PCOH75' ...
               'PCOH100' ...
               'ACOH0' ...
               'ACOH25' ...
               'ACOH50' ...
               'ACOH75' ...
               'ACOH100' ...
               'OR0' ...
               'OR45' ...
               'OR90' ...
               'OR135' ...
               'SF1' ...
               'SF2' ...
               'SF3' ...
               'SF4' ...
               'SF5' ...
               'WCON3' ...
               'WCON5' ...
               'WCON8' ...
               'WCON100' ...
               'FCON4' ...
               'FCON6' ...
               'FCON10' ...
               'FCON100' ...
               'NCON4' ...
               'NCON6' ...
               'NCON10' ...
               'NCON100'};  % 1 x 37 with the word labels
stimindicesC = [1:10 5 11:14 5 15:26 4 27:29 5 30:32 7];  % artificially inflates
stimlabelsD = {'5WORD' ...
               'CHECKER' ...
               'FACE' ...
               '5WORD' ...
               'FACEO' ...
               'W\_PCOH0' ...
               'W\_PCOH25' ...
               'W\_PCOH50' ...
               'W\_PCOH75' ...
               'W\_PCOH100' ...
               'F\_PCOH0' ...
               'F\_PCOH25' ...
               'F\_PCOH50' ...
               'F\_PCOH75' ...
               'F\_PCOH100' ...
               'WCON3' ...
               'WCON5' ...
               'WCON8' ...
               'WCON100' ...
               'FCON4' ...
               'FCON6' ...
               'FCON10' ...
               'FCON100' ...
               'NCON4' ...
               'NCON6' ...
               'NCON10' ...
               'NCON100' ...
               'POLYGON' ...
               'HOUSE' ...
               'BLANK'};  % 1 x 30 with the word labels
stimindicesD = [1:9 4 10:13 5 14:16 4 17:19 5 20:22 10 23:25];  % artificially inflates to 30 conditions

% notes on stimindicesD:
% - 4 5 included in the first batch
% - 4 5 inserted for ph coh
% - 4 5 inserted for con
% - 10 inserted for con
% - 25 as the blank at the end

% concatenate
stimlabelsALL = [stimlabels stimlabelsLOC stimlabelsC repmat(stimlabelsD,[1 3])];

% define some ranges (relative to the above, with gaps (34 + 1 + 4 + 1 + 37 = 77))
stimgroupranges = {[1 11]  [12 16] [17 21] [22 25] [26 30] [31 34] ...
                   [36 39] ...
                   [41 43] [44 45] [46 46] [47 51] [52 56] [57 60] [61 65] [66 69] [70 73] [74 77]};
stimgrouplabels = {'WORDY' 'PHASE' 'AMP'   'OR'    'SF'    'CLASS' ...
                   'LOCALIZER' ...
                   'CALIB' 'BASE'  'R'     'PHASE' 'AMP'   'OR'    'SF'    'WCON'  'FCON'  'NCON'};
stimgroupTranges = {[1 3]   [4 5]   [6 10]   [11 15]  [16 19] [20 23]  [24 27]   [28 30]};
stimgroupTlabels = {'CALIB' 'BASE'  'W\_PH'  'F\_PH'  'WCON'  'FCON'   'NCON'    'OTHER'};

% define some ranges (relative to the above) [34 + 4 + 37 + 75] [6 1 10]
stimgranges = {[1 11]  [12 16] [17 21] [22 25] [26 30] [31 34] ...
               [35 38] ...
               [39 41] [42 43] [44 44] [45 49] [50 54] [55 58] [59 63] [64 67] [68 71] [72 75]};
stimglabels = {'WORDY' 'PHASE' 'AMP'   'OR'    'SF'    'CLASS' ...
               'LOCALIZER' ...
               'CALIB' 'BASE'  'R'     'PHASE' 'AMP'   'OR'    'SF'    'WCON'  'FCON'  'NCON'};
stimgTranges = {[1 3]   [4 5]   [6 10]   [11 15]  [16 19] [20 23]  [24 27]   [28 30]};
stimgTlabels = {'CAL' 'BASE'  'WPH'  'FPH'  'WCN'  'FCN'   'NCN'    'OTHER'};
stimonlytaskranges = {};
stimonlytasklabels = {};
for x=1:3
  stimgranges = [stimgranges cellfun(@(y) y+75+(x-1)*30,stimgTranges,'UniformOutput',0)];
  stimglabels = [stimglabels stimgTlabels];
  stimonlytaskranges = [stimonlytaskranges cellfun(@(y) y+(x-1)*30,stimgTranges,'UniformOutput',0)];
  stimonlytasklabels = [stimonlytasklabels stimgTlabels];
end
stimgTpullB = {  6:10   11:15  [30 16:19] [30 20:23] [30 24:27] [28 2 29]};
stimgTrangesB = {[1 5]  [6 10]  [11 15]   [16 20]    [21 25]    [26 28]};
stimgTlabelsB = {'WPH'  'FPH'  'WCN'      'FCN'      'NCN'      'OTHER'};
stimtaskrangeB = {};
stimtasklabelB = {};
for x=1:3
  stimtaskrangeB = [stimtaskrangeB cellfun(@(y) y+(x-1)*28,stimgTrangesB,'UniformOutput',0)];
  stimtasklabelB = [stimtasklabelB stimgTlabelsB];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SOME FREESURFER LABELING STUFF

fslabels = {
    'unknown'
    'bankssts'
    'caudalanteriorcingulate'
    'caudalmiddlefrontal'  % #4
    'corpuscallosum'
    'cuneus'
    'entorhinal'
    'fusiform'
    'inferiorparietal'
    'inferiortemporal'
    'isthmuscingulate'
    'lateraloccipital'
    'lateralorbitofrontal'
    'lingual'
    'medialorbitofrontal'
    'middletemporal'
    'parahippocampal'
    'paracentral'
    'parsopercularis'
    'parsorbitalis'
    'parstriangularis'
    'pericalcarine'
    'postcentral'
    'posteriorcingulate'
    'precentral'  % #25
    'precuneus'
    'rostralanteriorcingulate'
    'rostralmiddlefrontal'
    'superiorfrontal'
    'superiorparietal'
    'superiortemporal'
    'supramarginal'
    'frontalpole'
    'temporalpole'
    'transversetemporal'
    'insula'
}';

fscolortable = [
          25           5          25           0     1639705
          25         100          40           0     2647065
         125         100         160           0    10511485
         100          25           0           0        6500
         120          70          50           0     3294840
         220          20         100           0     6558940
         220          20          10           0      660700
         180         220         140           0     9231540
         220          60         220           0    14433500
         180          40         120           0     7874740
         140          20         140           0     9180300
          20          30         140           0     9182740
          35          75          50           0     3296035
         225         140         140           0     9211105
         200          35          75           0     4924360
         160         100          50           0     3302560
          20         220          60           0     3988500
          60         220          60           0     3988540
         220         180         140           0     9221340
          20         100          50           0     3302420
         220          60          20           0     1326300
         120         100          60           0     3957880
         220          20          20           0     1316060
         220         180         220           0    14464220
          60          20         220           0    14423100
         160         140         180           0    11832480
          80          20         140           0     9180240
          75          50         125           0     8204875
          20         220         160           0    10542100
          20         180         140           0     9221140
         140         220         220           0    14474380
          80         160          20           0     1351760
         100           0         100           0     6553700
          70          20         170           0    11146310
         150         150         200           0    13145750
         255         192          32           0     2146559
];

% some extra stuff
fslhwhite = '~/ext/anatomicals/fsaverage/lhwhite.mat';
fslhcurv = -restrictrange(loadmulti(fslhwhite,'curvature'),-.5,.5)>0;
fslhflat = '~/ext/anatomicals/fsaverage/lhflat.mat';
fsrhwhite = '~/ext/anatomicals/fsaverage/rhwhite.mat';
fsrhcurv = -restrictrange(loadmulti(fsrhwhite,'curvature'),-.5,.5)>0;
fsrhflat = '~/ext/anatomicals/fsaverage/rhflat.mat';
vsdpref = viewsurfacedata_preferences;
fscamlookup = @(suffix) vsdpref.camerapresets{find(cellfun(@(x)isequal(x,['fsaverage' suffix]),vsdpref.camerapresets(:,1))),2};
fsextralabels = {'LH_IPS' 'RH_IPS' 'IPS' 'LH_VOT' 'RH_VOT' 'VOT'};
fsnumf = 327680;  % faces
fsnumv = 163842;  % vertices

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assign all variables to the base workspace
assigntobaseworkspace;








%%%% NOTES ON ROI STUFF:

% /biac4/wandell/biac2/wandell6/data/frk/prf/fp20110912/mrvSession/Gray/ROIs
% �RIPS1.mat
% �RIPS2.mat
% �RIPS3.mat
% RIPS_Combined.mat
% RLO1.mat
% RLO2.mat
% ROI1.mat
% RTO1.mat
% RV123.mat
% �RV1.mat
% �RV2d.mat
% �RV2v.mat
% RV3AB.mat
% �RV3d.mat
% �RV3v.mat
% �RV4.mat
% �RVO1.mat
% RVO2.mat
% RVO_Combined.mat
% wm_left_2cm_from_occpole.mat
% wm_left_5cm_from_occpole.mat
% wm_right_2cm_from_occpole.mat
% wm_right_5cm_from_occpole.mat









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % function fmrisetup(x)
% %
% % 28: MP2011
% 
% % ddir is where the raw data live
% % magsize is the size of data as expected from the .mag files
% % grecons is which version of grecons to use
% % firstgoodrun indicates the index of the start of the good runs (relative to all the .mag files we reconstruct)
% % odir is where analysis files go
% % numstimrep is number of repetitions of stimulus in a run.  [] means 1.
% % stimmatrange is a vector of indices indicating which stimulus .mat files to use when constructing the stimulus.
% %   [] means use all.
% % wantremoveblankstim is whether, based on what is found for the first stimulus case, 
% %   to remove columns that are all blank of the first case, and apply to all other cases.  [] means 0.
% % datarange is a vector of indices indicating which motion-corrected directories to use.  [] means use all.
% % dtype is a string (like 'MotionCorrected')
% % infofile contributes 'trialpattern'
% % asst is a mapping from classorder (as in the stimulus .mat files) to beta weight column.
% %   it should be the case that union([],asst) is 1:N for some N.
% % stimulussplit is like in splitmatrix, referring to the stimulus time dimension (before the ignorenum stuff...)
% % ignorenum is... ???number of initial data points in each run to ignore???  for the purposes of stimulus construction
% % tr is TR in seconds
% % trupsample is the new TR to use (cubic interpolation).  [] means do not do anything.
% % numtrtrial is number of TRs to expect per trial
% % OBSOLETE: hrfbasis is time x basis
% % xyzsize is matrix size for functional data
% % inplanefactor is the matrix size upsampling factors for the in-plane anatomical data
% % vxsize is mm size for functional data
% % hrfrange is a vector of indices into the time dimension indicating which to sum over
% % hrfnormfun is a function that normalizes an HRF
% % wantresamplexval is for subxval
% % OBSOLETE: wantresamplexval2 is for dctinitial
% % deltabasis is time x basis
% % deltaxval is for deltainitial
% % betatrain is index of betas to use for traindata when compiling the summary file
% % betatest is index of betas to use for testdata when compiling the summary file
% % highresvol is path to the high-res anatomical
% % anatlen is mm size for high-res anatomical
% % roifile is path to generated roi file (for that subject)
% % dataix is which stim and data points to pull out
% % realcons is percent contrast in sorted order
% % consix is indices into the beta weights.  the first two should be the 100% contrast cases.
% % betafile_xvalmulti is a cell vector of where to find the allxval.mat file
% 
% %%%%%%%%%%%%%%%%%%%%%%%% pre-declarations
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%
% 
% switch x
% case 1
%   ddir = '/home/knk/multiclass/JW20110331/';
%   magsize = [70 70 0 20];
%   grecons = '/home/knk/matlab/fmriutil/grecons15_rev95';  % but the current was rev100
%   firstgoodrun = 1;
%   %OBSOLETE stabletodo = []; stabledeg = 3; stablenum = 16/(4/3)-5;
%   odir = '/home/knk/ext/datasets/JW20110331';
%   numstimrep = [];
%   stimmatrange = [1:10];
%   wantremoveblankstim = [];
%   datarange = [1:10];
%   dtype = 'MotionCorrected';
%   infofile = '/home/knk/info/multiclassinfo_wnB8.mat';
%   asst = []; asst([1:69]) = 1:69;
%   stimulussplit = 0;
%   ignorenum = 4;
%   tr = 1.605242;
%   trupsample = [];
%   numtrtrial = 5;
%   % OBSOLETE: hrfbasis = unitlength([zeros(1,17); constructdctmatrix(35,0:16)],1);
%   xyzsize = [70 70 20]; inplanefactor = [256/70 256/70 1]; vxsize = 1.8;
%   episize = [.7 .7 .7];
%   hrfrange = 1:10;  % up to 15 s
%   hrfnormfun = @(x) signforce(sum(x(hrfrange))) * vectorlength(x);
%   wantresamplexval = -[-1 -1  1  1  2  2  3  3  4  4;    % NOTICE INDIVIDUAL RUNS
%                         1  1 -1 -1  2  2  3  3  4  4;
%                         1  1  2  2 -1 -1  3  3  4  4;
%                         1  1  2  2  3  3 -1 -1  4  4;
%                         1  1  2  2  3  3  4  4 -1 -1];
%   bootgroups = repmat([1 2],[1 5]);
%   deltabasis = unitlength([zeros(1,floor(50/tr)); eye(floor(50/tr))],1);
%   deltaxval = -[1 1 2 2 -1 -1 3 3 4 4];
%   % OBSOLETE: wantresamplexval2 = -[1 1 2 2 3 3 -1 -1 4 4 5 5];
%   betatrain = [1  3  5  7  9];
%   betatest =  [2  4  6  8 10];
%   pcrnum = 4;
%   highresvol = '/biac2/wandell2/data/anatomy/winawer/Anatomy20110308/t1.nii.gz';  % the class file is t1_class.nii.gz
%   highresclass = '/biac2/wandell2/data/anatomy/winawer/Anatomy20110308/t1_class.nii.gz';
%   highresdim = [258 309 258];
%   anatlen = 0.7;
%   roifile = [odir '/roifunctionalspace.mat'];
%   roigroups = {    [6 19]  [7 8 20 21]  [10 11 23 24] [9 22]  [14 27] [12 25]  [13 26] [2 15]  [3 16]  [4 17]  [5 18]};% [1]};
%   roigrouplabels = {'V1'    'V2'        'V3'          'V3AB'  'hV4'   'VO1'    'VO2'   'LO1'   'LO2'   'TO1'    'TO2'};% '?'};
%   dataix = ':';
%   stimfun = @() subscript(feval(stimfun_wn),{dataix ':'});  % notice the dependency
%   stimfunall = @() subscript(feval(stimfun_wn),{':' ':'});
%   stimres = stimres_wn;
%   stimborders = stimborders_wn;
%   %%%stimobjlocs = stimobjlocs_wnC3;
%   stimdeg = 12.290;
%   %realcons = [1 2 4 7 12 21 36 64 127]/127 * 100;
%   consix = [16 31+16];
%   %objsix = 38+8+(1:26);
%   %discgaps = linspace((300/14/2)^.5,300^.5,13).^2;
%   iscni = 1;
%   numtr = 221;
%   voloffset = [72 202 42];
%   epivoldim = [183 104 179];
% 
% otherwise
%   die;
% end
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% internal calculations
% 
%   fulldatafun = @() raw2dload(runfiles,'int16',numtr,[],'single');  % for PCR
%   datafun2 = @(vxs) raw2dload(runfiles(datarange),'int16',numtr,vxs,'double',1);
% 
%   runfiles2 = matchfiles([odir '/preprocessREG/run*.nii']);
%   fulldatafun2 = @() cellfun(@(x) squish(single(getfield(load_untouch_nii(x),'img')),3)',runfiles2,'UniformOutput',0);
% 
%   runfiles3 = matchfiles([odir '/preprocessREGMCMASK/run*.nii']);
%   fulldatafun3 = @() cellfun(@(x) squish(single(getfield(load_untouch_nii(x),'img')),3)',runfiles3,'UniformOutput',0);
% % 
% % prepare data files
% betafile_xval = [odir '/allxvalPCR.mat'];
% betafile_boot = [odir '/goodbootPCR.mat'];
% 
% % prepare data
%   % cross-validation case.  voxels x stim x [trainresamples,testresamples].
% betafun_xval = @(vxs) cat(3,subscript(loadmulti(betafile_xval,'traindata'), ...
%                                       {ismember(loadmulti(betafile_xval,'vxs'),vxs) dataix ':'}), ...
%                             subscript(loadmulti(betafile_xval,'testdata'), ...
%                                       {ismember(loadmulti(betafile_xval,'vxs'),vxs) dataix ':'}));
%   % combine mean of xval with mean of boot (where it exists) case.  voxels x stim x 1.
% betafun_full = @(vxs) ...
%   copymatrix(mean(subscript(loadmulti(betafile_xval,'traindata'), ...
%                             {ismember(loadmulti(betafile_xval,'vxs'),vxs) dataix ':'}),3), ...
%              ismember(intersect(loadmulti(betafile_xval,'vxs'),vxs), ...
%                       intersect(loadmulti(betafile_boot,'vxs'),vxs)),1, ...
%              mean(subscript(loadmulti(betafile_boot,'traindata'), ...
%                             {ismember(loadmulti(betafile_boot,'vxs'),vxs) dataix ':'}),3));
%   % boot case.  voxels x stim x resamples.
% betafun_boot = @(vxs) subscript(loadmulti(betafile_boot,'traindata'), ...
%                                 {ismember(loadmulti(betafile_boot,'vxs'),vxs) dataix ':'});
% 
% % multi version of the previous
% if exist('betafile_xvalmulti','var')
%   temp = {};
%   for p=1:length(betafile_xvalmulti)
%     temp{p} = @(vxs,str) subscript(loadmulti(betafile_xvalmulti{p},str), ...
%                                    {ismember(loadmulti(betafile_xvalmulti{p},'vxs'),vxs) dataix{p} ':'});
%   end
%   betafun_xvalmulti = @(vxs) cat(3,cat(2,feval(temp{1},vxs,'traindata'),feval(temp{2},vxs,'traindata')), ...
%                                    cat(2,feval(temp{1},vxs,'testdata'), feval(temp{2},vxs,'testdata')));
% end
% 




%     numstim = 156;          % total number of stimuli
%     numstim = 41;           % total number of stimuli
