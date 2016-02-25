function surfvals = cvnsurfsmooth(subject,surfvals,fwhm,hemi,surftype,surfsuffix)
% surfvals = cvnsurfsmooth(subject,surfvals,fwhm,hemi,surftype,surfsuffix)
%
% Smooth vertex data along the surface using iterative vertex-neighbor
% averaging.
%
% Inputs:
%   subject:    
%   surfvals:   VxT values at each of V vertices
%   fwhm:       FWHM in mm for 2D gaussian smoothing kernel
%   hemi:       'lh','rh',{'lh','rh'}
%   surftype:   'white', 'layerA1','layerA2',...
%   surfsuffix: 'DENSETRUNCpt','DENSE','orig',...
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
% smoothedvals=cvnsurfsmooth('C0041',valstruct,3,{'lh','rh'},'layerA1','DENSETRUNCpt');

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
            hemi{h},surftype,surfsuffix);
    end
    return;
end

surf=cvnreadsurface(subject,hemi,surftype,surfsuffix);
iter=mesh_fwhm2iter_cvn(surf.faces,surf.vertices,fwhm);
surfvals=mesh_diffuse_fast(surfvals,surf.faces,iter);
