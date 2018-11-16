function p = cvnpath(whichpath)
% p = cvnpath(whichpath)
% 
% Return the path specified in 'whichpath'
% Hardcode common paths here, then call this function elsewhere to maximize
% flexibility.
%
% Possibilities:
%   'code'        (common cvnlab code on Dropbox)
%   'ppresults'   (cvnlab pre-processing results on Dropbox)
%   'freesurfer'  (FreeSurfer subjects directory)
%   'fmridata'    (fmridata directory on stone)
%   'anatomicals' (anatomicals directory on stone)
%   'workbench'   (location of HCP wb_command)
%
% eg: fsdir=sprintf('%s/%s',cvnpath('freesurfer'),subjectid) 
%       instead of hardcoding in every function
%
% Note: If you have /stone/ext1 followed by /home/stone-ext1, this ensures
%   that you can access it from any machine, and if we ARE on stone, it
%   will use the faster local route /stone/ext1

switch(lower(whichpath))
    case 'code'
        testpaths={
            '/home/stone/generic/Dropbox/cvnlabsmall/code'
            };
    case 'commonmatlab'
        testpaths={
            '/home/stone/software/commonmatlabcode'
            };
    case 'ppresults'
        testpaths={
            '/home/stone/generic/Dropbox/cvnlabbig/ppresults'
            };
    case 'freesurfer'
        testpaths={
            getenv('SUBJECTS_DIR')
            '/stone/ext1/freesurfer/subjects'
            '/home/stone-ext1/freesurfer/subjects'
            };
    case 'fmridata'
        testpaths={
            '/stone/ext1/fmridata'
            '/home/stone-ext1/fmridata'
            };
    case 'anatomicals'
        testpaths={
            '/stone/ext1/anatomicals'
            '/home/stone-ext1/anatomicals'
            };
    case 'workbench'
        testpaths={
            '/home/stone/software/workbench_v1.1.1/bin_rh_linux64'
            '/Applications/workbench/bin_macosx64'
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
