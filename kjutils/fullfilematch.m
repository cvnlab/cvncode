function files = fullfilematch(filestrings,case_sensitive)
%function files = fullfilematch(filestrings,[case_sensitive=true])
%
%Find files with wildcard matching.  Returns a cell array of file paths.
%eg: 
%> files=fullfilematch('~/somedir/*.mat')
%A = 
%
%    '~/somedir/run1.mat'
%    '~/somedir/run2.mat'
%    '~/somedir/run3.mat'

if(nargin < 2)
    case_sensitive = true;
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

files = {};
for f = 1:numel(filestrings)
    filestr = filestrings{f};
    if(isdir(filestr))
        files_tmp = {filestr};
    else
        [filedir,fpattern,fext] = fileparts(filestr);
        fpattern = strrep([fpattern fext],'*','.*');
        fpattern = strrep(fpattern,'(','\(');
        fpattern = strrep(fpattern,')','\)');
        fpattern = ['^' fpattern '$'];
        
        %filestruct = dir(filestr);
        filestruct = dir(filedir);
        if(numel(filestruct) == 1 && filestruct(1).isdir)
            [filedir2,~,~] = fileparts(filedir);
            filedir = strcat([filedir2 '/'],filestruct(1).name);
            if(~isdir(filedir))
                continue;
            end
            filestruct = dir(filedir);
        end
        
        if(isempty(filestruct))
            files_tmp = [];
        else
            filenames = {filestruct.name};
            filenames = filenames(~cellfun(@(x)(all(x=='.')),filenames));
            if(case_sensitive)
                filenames = filenames(~cellfun(@isempty,regexpi(filenames,fpattern,'matchcase')));
            else
                filenames = filenames(~cellfun(@isempty,regexpi(filenames,fpattern)));
            end
            if(isempty(filenames))
                files_tmp = [];
            else
                files_tmp = strcat([filedir '/'],filenames);
                files_tmp = files_tmp(:);
            end
        end
    end
    files = [files(:); files_tmp(:)];
end

files = unique(files);
