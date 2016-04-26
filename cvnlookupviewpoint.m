function viewpt = cvnlookupviewpoint(subject,hemi,viewname,surftype)
% viewpt = cvnlookupviewpoint(subject,hemi,viewname,surftype)
%
% Return predefined viewpoints for spherical or nonspherical lookups
%
% Inputs
%   subject:     freesurfer subject name (eg: 'C0041')
%   hemi:        'lh','rh', or {'lh','rh'}
%   viewname:    name of predefined viewpoint
%   surftype:    'sphere', 'inflated', ...
%
% Outputs
%   viewpt:      [az el tilt] (in degrees) for use with lookup generation
%                or {[azL elL tiltL], [azR elR tiltR]} if hemi={'lh','rh'}
%
% Current viewpoints:
%  sphere: occip, ventral
%  inflated: occip, ventral, dorsal, medial, lateral, medial-ventral
%    (these should work for other non-sphere as well, eg: white, pial, etc)
%
% Note: subject input is not currently used, but may be useful in the future

if(isequal(surftype,'sphere'))
    switch(viewname)
        case 'occip'
            viewpt_LR = {[10 -40 0],[-10 -40 0]};
        case 'ventral'
            viewpt_LR = {[10 -70 0],[-10 -70 0]};
        otherwise
    end
    
elseif(~isempty(regexp(surftype,'inflated'))) %#ok<RGXP1>
    switch(viewname)
        case 'dorsal'
            viewpt_LR={[0 90 90],[0 90 90]};
        case 'ventral'
            viewpt_LR={[0 -90 -90],[0 -90 -90]};
        case 'medial'
            viewpt_LR={[90 0 15],[-90 0 -15]};
        case 'lateral'
            viewpt_LR={[270 0 -15],[-270 0 -15]};
        case 'medial-ventral'
            viewpt_LR={[45 -45 15],[-45 -45 -15]};
        case 'occip'
            viewpt_LR={[10 -45 0],[-10 -45 0]};
        otherwise
    end
    
    
end

inputcell=iscell(hemi);
if(~inputcell)
    hemi={hemi};
end

viewpt={};
for i = 1:numel(hemi)
    if(strcmpi(hemi{i},'lh'))
        viewpt{i}=viewpt_LR{1};
    elseif(strcmpi(hemi{i},'rh'))
        viewpt{i}=viewpt_LR{2};
    end
end

if(~inputcell)
    viewpt=viewpt{1};
end
