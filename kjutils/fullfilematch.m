function files = fullfilematch(filestrings,case_sensitive)
%function files = fullfilematch(filestrings,[case_sensitive=true])
%
%Find files with wildcard matching.  Returns a cell array of file paths.
%eg: 
%> files=fullfilematch('~/somedir*/*.mat')
%A = 
%
%    '~/somedir/run1.mat'
%    '~/somedirA/run2.mat'
%    '~/somedirB/run3.mat'

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

if(isequal(filesep,'\'))
    fsep='[/\\]'; 
else
    fsep=filesep;
end

filestrings0={};
for f = 1:numel(filestrings)
    filestr = filestrings{f};
    if(isdir(filestr))
        files_tmp = {filestr};
    else
        fparts=regexp(filestr,fsep,'split');

        if(~isempty(regexp(filestr(1),fsep))) %#ok<RGXP1>
            files_tmp={'/'};
        else
            files_tmp={''};
        end
        for p = 1:numel(fparts)-1
            if(isempty(fparts{p}))
                continue;
            end
            if(any(ismember(fparts{p},'*?')))
                files_tmp=fullfilematch(strcat(files_tmp,fparts{p}));
            else
                files_tmp=strcat(files_tmp,fparts{p});
            end
            files_tmp=strcat(files_tmp,'/');
        end
        files_tmp=files_tmp(cellfun(@isdir,files_tmp));
        files_tmp=strcat(files_tmp,fparts{end});
        
    end
    filestrings0=[filestrings0; files_tmp(:)];
end
filestrings=filestrings0;

files = {};
for f = 1:numel(filestrings)
    filestr = filestrings{f};
    if(isdir(filestr))
        files_tmp = {filestr};
    else
        [filedir,fpattern,fext] = fileparts(filestr);
        fpattern = strrep([fpattern fext],'*','.*');
        fpattern = strrep(fpattern,'?','.');
        fpattern = strrep(fpattern,'(','\(');
        fpattern = strrep(fpattern,')','\)');
        fpattern = ['^' fpattern '$'];
        
        %filestruct = dir(filestr);
        filestruct = dir(filedir);
        if(numel(filestruct) == 1 && filestruct(1).isdir)
            [filedir2,~,~] = fileparts(filedir);
            if(filedir2(end)~='/')
                filedir2=[filedir2 '/'];
            end
            filedir = strcat(filedir2,filestruct(1).name);
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
                if(filedir(end)~='/')
                    filedir=[filedir '/'];
                end
                files_tmp = strcat(filedir,filenames);
                files_tmp = files_tmp(:);
            end
        end
    end
    files = [files(:); files_tmp(:)];
end

files = unique(files);
