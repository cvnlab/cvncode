function p = cvnpath(whichpath)
% p = cvnpath(whichpath)
% 
% Return the path specified in 'whichpath'
% Hardcode common paths here, then call this function elsewhere to maximize
% flexibility.
%
% eg: fsdir=sprintf('%s/%s',cvnpath('freesurfer'),subjectid) 
%       instead of hardcoding in every function

switch(lower(whichpath))
    case 'code'
        testpaths={
            '/home/generic/Dropbox/cvnlab/code'
            };
    case 'freesurfer'
        testpaths={
            '/stone/ext1/freesurfer/subjects'
            '/Users/kjamison/KJSync'
            };
    case 'fmridata'
        testpaths={
            '/stone/ext1/fmridata'
            };
    case 'anatomicals'
        testpaths={
            '/stone/ext1/anatomicals'
            };
end

p='';
for i = 1:numel(testpaths)
    if(exist(testpaths{i},'dir'))
        p=testpaths{i};
        break;
    end
end


if(isempty(p))
    warning('No path found for %s',whichpath);
end
