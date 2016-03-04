function surfvals = cvnsurfsmooth(subject,surfvals,fwhm,hemi,surftype,surfsuffix,algorithm)
% surfvals = cvnsurfsmooth(subject,surfvals,fwhm,hemi,surftype,surfsuffix,algorithm)
%
% Smooth vertex data along the surface using either iterative vertex-neighbor
% averaging (fast but distorted for many surface), or HCP Connectome
% Workbench's area-normalized algorithm (slow but much more accurate).
%
% Inputs:
%   subject:    
%   surfvals:   VxT values at each of V vertices
%   fwhm:       FWHM in mm for 2D gaussian smoothing kernel
%   hemi:       'lh','rh',{'lh','rh'}
%   surftype:   'white', 'layerA1','layerA2',...
%   surfsuffix: 'DENSETRUNCpt','DENSE','orig',...
%   algorithm:  'iterative (default), 'workbench'
%  
% Outputs:
%   surfvals:  VxT smoothed values
%
% Examples:
%
% prfdir=sprintf('%s/C0041/PRF_results/mgz',cvnpath('freesurfer'));
% vertvalsL=load_mgh(sprintf('%s/lh.lh_ang_mean.mgz',prfdir));
% smoothedvalsL=cvnsurfsmooth('C0041',vertvalsL,3,'lh','layerA1','DENSETRUNCpt');
%
% vertvalsL=load_mgh(sprintf('%s/lh.lh_ang_mean.mgz',prfdir));
% vertvalsR=load_mgh(sprintf('%s/rh.rh_ang_mean.mgz',prfdir));
% valstruct=struct('data',[vertvalsL; vertvalsR],...
%   'numlh',size(vertvalsL,1),'numrh',size(vertvalsR,1));
% smoothedvals=cvnsurfsmooth('C0041',valstruct,3,{'lh','rh'},'layerA1','DENSETRUNCpt','workbench');
%
% Note: 'workbench' mode has SIGNIFICANT overhead.  Every time
%   you want to smooth a dataset, it will take ~30 seconds (per hemisphere)
%   to compile its geodesic distance info.  Fortunately, you can smooth 
%   multiple surface maps at a time, so you will usually want the 'surfdata' 
%   input to be a VxT matrix combining all of your maps to smooth them 
%   in one call.

% KJ 2016-03-04 add 'workbench' option to wrap wb_command -metric-smoothing

if(~exist('algorithm','var') || isempty('algorithm'))
    algorithm='iterative';
end

if(isstruct(surfvals))
    if(~iscell(hemi))
        hemi={hemi};
    end
    
    for h = 1:numel(hemi)
        if(strcmpi(hemi{h},'lh'))
            vidx=1:surfvals.numlh;
        else
            vidx=(1:surfvals.numrh)+surfvals.numlh;
        end
        surfvals.data(vidx,:)=cvnsurfsmooth(subject,surfvals.data(vidx,:),...
            hemi{h},surftype,surfsuffix,algorithm);
    end
    return;
end


surf=cvnreadsurface(subject,hemi,surftype,surfsuffix);
switch lower(algorithm)
    case {'iter','iterative'}
        iter=mesh_fwhm2iter_cvn(surf.faces,surf.vertices,fwhm);
        surfvals=mesh_diffuse_fast(surfvals,surf.faces,iter);
    case 'workbench'
        wb_command=sprintf('%s/wb_command',cvnpath('workbench'));
        surfvals=mesh_diffuse_workbench(surf,surfvals,fwhm,wb_command);
end

