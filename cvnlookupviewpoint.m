function [viewpt, fliphemi, viewhemi] = cvnlookupviewpoint(subject,hemi,viewname,surftype)
% [viewpt,fliphemi,viewhemi] = cvnlookupviewpoint(subject,hemi,viewname,surftype)
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
%   fliphemi:    true|false if recommend swapping LH/RH for display (eg:
%                   inflated ventral)
%   viewhemi:    if single hemi, viewhemi=hemi, otherwise 
%                   {'lh','rh'} (fliphemi=false) or {'rh','lh'} (fliphemi=true)
%
% Current viewpoints:
%  sphere: occip, ventral
%  inflated: occip, ventral, dorsal, medial, lateral, medial-ventral, parietal
%    (these should work for other non-sphere as well, eg: white, pial, etc)
%
% Note: subject input is not currently used, but may be useful in the future

% Update KJ 2017-07-25: Add viewhemi to simplify viewing fliphemi views
% Update KJ 2017-08-11: Set views to [0 0 0] for flat patches 

fliphemi=false;
viewhemi=hemi;

if(~isempty(regexp(surftype,'^sphere')))
    switch(viewname)
        case 'occip'
            viewpt_LR = {[10 -40 0],[-10 -40 0]};
        case 'ventral'
            viewpt_LR = {[10 -70 0],[-10 -70 0]};
        otherwise
    end
elseif(~isempty(regexp(surftype,'\.flat\.patch\.'))) %#ok<*RGXP1>
    viewpt_LR={[0 0 0],[0 0 0]};
    switch(viewname)
        case 'ventral'
            fliphemi=true;
        otherwise
    end
%elseif(~isempty(regexp(surftype,'inflated')))
elseif(isempty(regexp(surftype,'sphere')))
    switch(viewname)
        case 'dorsal'
            viewpt_LR={[0 90 90],[0 90 90]};
        case 'parietal'
            viewpt_LR={[0 45 0],[0 45 0]};
        case 'ventral'
            viewpt_LR={[0 -90 -90],[0 -90 -90]};
            fliphemi=true;
        case 'medial'
            viewpt_LR={[90 0 15],[-90 0 -15]};
        case 'lateral'
            viewpt_LR={[270 0 -15],[-270 0 15]};
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

if(numel(hemi)>1)
    viewhemi={'lh','rh'};
    if(fliphemi)
        viewhemi=viewhemi([2 1]);
    end
end

if(~inputcell)
    viewpt=viewpt{1};
    viewhemi=hemi{1};
end

if(nargout==1)
    varargout={viewpt};
elseif(nargout==2)
    varargout={viewpt,fliphemi};
elseif(nargout==3)
    varargout={viewpt,fliphemi,viewhemi};
end
