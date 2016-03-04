function smoothdata = mesh_smooth_workbench(surf,surfdata,fwhm,wb_command)
% smoothdata = mesh_smooth_workbench(surf,surfdata,fwhm,wb_command)
%
% Smooth values on a triangle mesh using the Connectome Workbench geodesic
% algorithm.  This function is just a wrapper for:
%   wb_command -metric-smoothing ... -method GEO_GAUSS_AREA
%
% Inputs:
%   surf:       Surface struct containing 'faces' and 'vertices'
%               fields
%
%   surfdata:   VxT values at each of V vertices in mesh 
%   fwhm:       FWHM in mm for 2D gaussian smoothing kernel
%   wb_command: Path to HCP Connectome Workbench wb_command
%
% Outputs:
%   smoothdata: VxT smoothed values
% 
% Note: wb_command -metric-smoothing has SIGNIFICANT overhead.  Every time
%   you want to smooth a dataset, it will take ~30 seconds to build its
%   geodesic distance info.  Fortunately, you can smooth multiple surface
%   maps at a time, so you will usually want the 'surfdata' input to be a
%   VxT matrix combining all of your maps to smooth them in one call.
%
% Examples:
% surfL=cvnreadsurface('C0041','lh','layerA1','DENSETRUNCpt');
% prfdir=sprintf('%s/C0041/PRF_results/mgz',cvnpath('freesurfer'));
% vertvals=load_mgh(sprintf('%s/lh.lh_ang_mean.mgz',prfdir));
% smoothvals=mesh_diffuse_workbench(surfL, vertvals, 10);

% KJ 2016/02/29
% TODO: Simulate FWHM and compute possible correction factor (quick
%   simulations suggest it isn't exact, probably due to kernel "zig-zagging"
%   along mesh edges instead of direct 


if(~exist('wb_command','var') || isempty('wb_command'))
    wb_command=sprintf('%s/wb_command',cvnpath('workbench'));
end

tmpfiles={};

ts=timestamp;

if(isstruct(surf))
    surffile=sprintf('%s/tmpcvn_surf_%s.gii',tempdir,ts);
    Gsurf=gifti(surf);
    system(sprintf('rm -f %s',surffile));
    
    save(Gsurf,surffile,'ExternalFileBinary');
    tmpfiles{end+1}=surffile;
elseif(ischar(surf) && exist(surf,'file'))
    [~,~,ext]=fileparts(surf);
    if(strcmpi(ext,'.gii'))
        surffile=surf;
    else
        error('input surf file must be gii');
    end
    
else
    error('unknown input type for surf');
end


metricfile1=sprintf('%s/tmpcvn_metric1_%s.func.gii',tempdir,ts);
metricfile2=sprintf('%s/tmpcvn_metric2_%s.func.gii',tempdir,ts);
system(sprintf('rm -f %s %s',metricfile1,metricfile2));


tmpfiles=[tmpfiles metricfile1 metricfile2];

Gdata=gifti(surfdata);
save(Gdata,metricfile1,'ExternalFileBinary');

kernel_sigma=fwhm/sqrt(log(256.0));
extraargs='';
cmd=sprintf('%s -metric-smoothing %s %s %.6f %s -method GEO_GAUSS_AREA %s',...
    wb_command,surffile,metricfile1,kernel_sigma,metricfile2,extraargs);


[status,output]=system(cmd);

if(exist(metricfile2,'file'))
    Gnew=gifti(metricfile2);
    smoothdata=cast(Gnew.cdata,'like',surfdata);
else
    smoothdata=[];
end
if(~isempty(tmpfiles))
    delete(tmpfiles{:});
end
