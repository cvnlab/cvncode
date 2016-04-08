function tmpd = tempdir_unique
%tmpd = tempdir_unique
%
%Create and return a unique temporary directory.  First try mktemp -d,
%since that best ensures uniqueness at the system level.  If that does not
%work (eg: on Windows), create our own random alphanumeric string, test
%uniqueness, create that directory and return the path

[r,tmpd]=system('mktemp -d 2>/dev/null');
tmpd=regexprep(tmpd,'[\r\n]+$','');
if(~exist(tmpd,'dir') || r~=0)
    %if system does not have mktemp (eg: Windows), use our own algorithm
    %to generate a unique temporary dir
    tmplen=20;
    tmpstr=char([double('A'):double('Z') double('a'):double('z') double('0'):double('9')]);
    for i = 1:10
        tmpd=[tempdir 'tmp_' tmpstr(floor(rand(1,tmplen)*numel(tmpstr))+1)];
        if(~exist(tmpd,'dir'))
            mkdir(tmpd);
            break;
        end
    end
end
