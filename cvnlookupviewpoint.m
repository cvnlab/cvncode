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
%  inflated: occip, ventral, ventral-lateral, dorsal, medial, lateral, medial-ventral, parietal
%    (these should work for other non-sphere as well, eg: white, pial, etc)
%
% Note: subject input is not currently used, but may be useful in the future

% history:
% - 2017/12/02 - add occipA/B/C
% Update KJ 2017-08-11: Set views to [0 0 0] for flat patches 
% Update KJ 2017-07-25: Add viewhemi to simplify viewing fliphemi views

fliphemi=false;
viewhemi=hemi;

if(~isempty(regexp(surftype,'^sphere')))
    switch(viewname)
        case 'occip'
            viewpt_LR = {[10 -40 0],[-10 -40 0]};
        case 'ventral'
            viewpt_LR = {[10 -70 0],[-10 -70 0]};

        case 'occipA1'
            viewpt_LR = {[10      -40 0],[-10      -40 0]};
        case 'occipA2'
            viewpt_LR = {[10-45   -40 0],[-10+45   -40 0]};
        case 'occipA3'
            viewpt_LR = {[10-2*45 -40 0],[-10+2*45 -40 0]};
        case 'occipA4'
            viewpt_LR = {[10-3*45 -40 0],[-10+3*45 -40 0]};
        case 'occipA5'
            viewpt_LR = {[10-4*45 -40 0],[-10+4*45 -40 0]};
        case 'occipA6'
            viewpt_LR = {[10-5*45 -40 0],[-10+5*45 -40 0]};
        case 'occipA7'
            viewpt_LR = {[10-6*45 -40 0],[-10+6*45 -40 0]};
        case 'occipA8'
            viewpt_LR = {[10-7*45 -40 0],[-10+7*45 -40 0]};

        case 'occipB1'
            viewpt_LR = {[10 -40      0],  [-10 -40      0]};
        case 'occipB2'
            viewpt_LR = {[10 -40+45   0],  [-10 -40+45   0]};
        case 'occipB3'
            viewpt_LR = {[10 -40+2*45 0],  [-10 -40+2*45 0]};
        case 'occipB4'
            viewpt_LR = {[10 -40+3*45 180],[-10 -40+3*45 180]};
        case 'occipB5'
            viewpt_LR = {[10 -40+4*45 180],[-10 -40+4*45 180]};
        case 'occipB6'
            viewpt_LR = {[10 -40+5*45 180],[-10 -40+5*45 180]};
        case 'occipB7'
            viewpt_LR = {[10 -40+6*45 180],[-10 -40+6*45 180]};
        case 'occipB8'
            viewpt_LR = {[10 -40+7*45 0],  [-10 -40+7*45 0]};

        case 'occipC1'
            viewpt_LR = {[10-2*45 -40      0],[-10+2*45 -40      0]};
        case 'occipC2'
            viewpt_LR = {[10-2*45 -40+45   0],[-10+2*45 -40+45   0]};
        case 'occipC3'
            viewpt_LR = {[10-2*45 -40+2*45 0],[-10+2*45 -40+2*45 0]};
        case 'occipC4'
            viewpt_LR = {[10-2*45 -40+3*45 180],[-10+2*45 -40+3*45 180]};
        case 'occipC5'
            viewpt_LR = {[10-2*45 -40+4*45 180],[-10+2*45 -40+4*45 180]};
        case 'occipC6'
            viewpt_LR = {[10-2*45 -40+5*45 180],[-10+2*45 -40+5*45 180]};
        case 'occipC7'
            viewpt_LR = {[10-2*45 -40+6*45 180],[-10+2*45 -40+6*45 180]};
        case 'occipC8'
            viewpt_LR = {[10-2*45 -40+7*45 0],[-10+2*45 -40+7*45 0]};

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
        case 'ventral-lateral'
            viewpt_LR={[95 -66 270],[-95 -66 90]};
            fliphemi=true;
        case 'lateral-auditory'
            viewpt_LR={[-120 -5 0],[120 -5 0]};
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
