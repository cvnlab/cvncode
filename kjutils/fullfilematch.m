function files = fullfilematch(filestrings,case_sensitive,sorttype)
% function files = fullfilematch(filestrings,[case_sensitive=true],[sorttype=''])
%
% Find files with wildcard matching.
%
% Inputs:
%   filestrings: string or cell array of strings with path(s) to search for
%       - Paths can include ? or * wildcards anywhere in string
%   case_sensitive (optional): Use case sensitive search? default=true
%   sorttype (optional): '' = alphabetical (default)
%                        't' = newest->oldest
%                        'tr' = 'oldest->newest'
%                        
% Outputs:
%   files: cell array of UNIQUE matching filenames
%
% Example: 
% > F=fullfilematch('~/somedir*/*.mat')
% F = 
%    '~/somedir/run1.mat'
%    '~/somedir/run2.mat'
%    '~/somedir/run3.mat'
%    '~/somedirA/run1.mat'
%    '~/somedirB/run1.mat'

% KJ Update 10/18/2016: Overhaul to allow wildcards in middle of path, and
%   to add sorting options (for use with cvnlab code)

if(nargin < 2 || ~exist('case_sensitive','var') || isempty(case_sensitive))
    case_sensitive = true;
end

if(nargin < 3 || ~exist('sorttype','var') || isempty(sorttype))
    sorttype = '';
end

if(ischar(case_sensitive))
    if(strcmpi(case_sensitive,'ignorecase'))
        case_sensitive = false;
    else
        case_sensitive = true;
    end
end

if(isempty(filestrings))
    files = [];
    return;
end

if(~iscell(filestrings))
    filestrings = {filestrings};
end

%make sure we can handle '\' filesep for Windows
if(isequal(filesep,'\'))
    fsep='[/\\]'; 
else
    fsep=filesep;
end


%% handle wildcards in the middle of path
%  eg: expand {'/data/experiment*/*.mat'} 
%   -> {'/data/experiment1/*.mat' 
%       '/data/experiment2/*.mat' 
%       '/data/experiment3/*.mat'}
filestrings0={};

for f = 1:numel(filestrings)
    filestr = filestrings{f};
    if(isdir(filestr) || ~any(ismember(filestr,'*?')))
        files_tmp = {filestr};
    else
        fparts=regexp(filestr,fsep,'split');

        if(~isempty(regexp(filestr(1),fsep))) %#ok<RGXP1>
            files_tmp={'/'};
        else
            files_tmp={''};
        end
        %loop through DIRECTORIES in path.  whenever we encounter a 
        % wildcard, call fullfilematch on the parent directory to find 
        % matching subdirectories, possibly returning multiple new
        % directories for the next level of the path (this is OK since
        % both fullfilematch() and strcat() can accept strings or cell
        % arrays of strings)
        
        for p = 1:numel(fparts)-1
            if(isempty(fparts{p}))
                continue;
            end
            if(any(ismember(fparts{p},'*?')))
                files_tmp=fullfilematch(strcat(files_tmp,fparts{p}),case_sensitive);
            else
                files_tmp=strcat(files_tmp,fparts{p});
            end
            if(isempty(files_tmp))
                break;
            end
            files_tmp=strcat(files_tmp,'/');
        end
        if(~isempty(files_tmp))
            %prune final list to only include directories, then tack on the 
            % filename part (which may include wildcards) to all, before
            % continuing on to the file-name wildcard search
            files_tmp=files_tmp(cellfun(@isdir,files_tmp));
            files_tmp=strcat(files_tmp,fparts{end});
        end
    end
    filestrings0=[filestrings0; files_tmp(:)];
end
% new filestrings is a cell array that may include many more entries than 
% the input if there were directory wildcards
filestrings=filestrings0;

%% main filename wildcard matching for each filestring
%   (only operates on the last path element., ie: the file name)
%  eg: expand {'/data/experiment/*.mat'}
%   -> {'/data/experiment/run1.mat'
%       '/data/experiment/run2.mat'}

files = {};
filedates = {};
for f = 1:numel(filestrings)
    [files_tmp,filedates_tmp] = aux_fullfilematch(filestrings{f},case_sensitive);
    files=[files(:); files_tmp(:)];
    filedates=[filedates(:); filedates_tmp(:)];
end

% remove duplicate filenames
[~,iu] = unique(files);
files=files(iu);
filedates=filedates(iu);

% sort by filename or by date
if strcmpi(sorttype,'t')
  [~,ii] = sort(cat(2,filedates{:}),2,'descend');
elseif strcmpi(sorttype,'tr')
  [~,ii] = sort(cat(2,filedates{:}));
elseif strcmpi(sorttype,'none')
    ii=1:numel(files);
else
  [~,ii] = sort(cat(2,files));
end

files = files(ii);

%% helper function that does the work to match individual filestrings
% returns filenames and dates to allow date-sorting in main function
function [files,filedates] = aux_fullfilematch(filestr,case_sensitive)
if(isdir(filestr))
    files = {filestr};
    filestruct=dir(filestr);
    %pretty sure '.' is always first, but just in case....
    i=find(strcmp({filestruct.name},'.'),1,'first');
    filedates=filestruct(i).datenum;
    return;
end
    
[filedir,fpattern,fext] = fileparts(filestr);
fpattern = strrep([fpattern fext],'*','.*');
fpattern = strrep(fpattern,'?','.');
fpattern = strrep(fpattern,'(','\(');
fpattern = strrep(fpattern,')','\)');
fpattern = ['^' fpattern '$'];

filestruct = dir(filedir);
if(numel(filestruct) == 1 && filestruct(1).isdir)
    [filedir2,~,~] = fileparts(filedir);
    if(filedir2(end)~='/')
        filedir2=[filedir2 '/'];
    end
    filedir = strcat(filedir2,filestruct(1).name);
    if(~isdir(filedir))
        files=[];
        filedates=[];
        return;
    end
    filestruct = dir(filedir);
end

if(isempty(filestruct))
    files = [];
    filedates=[];
    return;
end

filenames = {filestruct.name};
filedates = {filestruct.datenum};

notdots=~cellfun(@(x)(all(x=='.')),filenames);
filenames = filenames(notdots);
filedates = filedates(notdots);

if(case_sensitive)
    fmatch=~cellfun(@isempty,regexpi(filenames,fpattern,'matchcase'));
else
    fmatch=~cellfun(@isempty,regexpi(filenames,fpattern));
end
filenames = filenames(fmatch);
filedates = filedates(fmatch);

if(isempty(filenames))
    files = [];
    filedates=[];
    return;
end

if(filedir(end)~='/')
    filedir=[filedir '/'];
end
files_tmp = strcat(filedir,filenames);
files_tmp = files_tmp(:);

files=files_tmp(:);
filedates=filedates(:);
