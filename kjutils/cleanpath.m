function pth=cleanpath(newpath)
%pth = cleanpath(newpath)
%
%Take input path (colon-delimited) and remove "bad" directories
%   (eg: .git, .svn)
%
%Returns colon-delimited clean path
%If no input given, use existing matlab path
%
%Example: 
%>> ls mygitrepo
% mygitrepo/.git/
% mygitrepo/somefunction.m
% mygitrepo/subdir/otherfunction.m
%
%>> addpath(cleanpath(genpath('mygitrepo'))
%
%matlab path now contains:
%mygitrepo,mygitrepo/subdir, but NOT mygitrepo/.git

if(~exist('newpath','var'))
    newpath=path;
end

bad = {'/.','.svn' '.git' 'DNBdata' 'DNBresults' '@'};

pth = regexp(newpath,'(.+?):','match');

badpat=strjoin(regexptranslate('escape',bad),'|');
pth=pth(cellfun(@isempty,regexp(pth,badpat,'match')));

pth = cat(2,pth{:});
