function cvnmakelayers(subjectid,layerdepths,layerprefix,fstruncate)

% function cvnmakelayers(subjectid,layerdepths,layerprefix,fstruncate)
%
% <subjectid> is like 'C0041'
% <layerdepths> is a vector of fractional distances (each having at 
%   most two decimal places).  e.g. linspace(.1,.9,6).  
%   NOTE: layerdepth=0 is pial and layerdepth=1 is white!
% <layerprefix> is a string that will be added to filenames (e.g. 'A').
%   this causes files like 'lh.layerA1' to be made.
% <fstruncate> is the name of the truncation surface in fsaverage (e.g. 'pt', 
%   which refers to 'lh.pt' and 'rh.pt')
% 
% Create layer surfaces.
% Subdivide layer and other surfaces to form dense surfaces.
% Calculate transfer functions to go from/to fsaverage standard surfaces
%   and the single-subject dense surfaces.
% Truncate the dense surfaces based on the fsaverage <fstruncate> surface,
%   and write out new surfaces.
% Calculate thickness and curvature values for the single-subject dense surfaces.
%
% Turn on matlabpool before calling for a big speed-up.
%
% Example files that are created:
%  lh.layerA1
%  lh.layerA1DENSE
%  lh.layerA1DENSETRUNCpt
%  tfunDENSE.mat
%  lh.DENSETRUNCpt.mat
%  lh.curvatureDENSE.mgz
%  lh.curvatureDENSETRUNCpt.mgz

% calc
dir0 = sprintf('/stone/ext1/anatomicals/%s',subjectid);
fsdir    = sprintf('/software/freesurfer/subjects/%s',subjectid);
fsdirAVG = sprintf('/software/freesurfer/subjects/fsaverage');

% define
hemis = {'lh' 'rh'};

%%%%%%%%%% create layer surfaces

parfor ii=1:2*length(layerdepths)
  p = mod2(ii,length(layerdepths));
  q = ceil(ii/length(layerdepths));
  %use 1-depth so that depth 0 = pial and depth 1 = white
  % This way if you use linspace(.1,.9,6), A1 will be equivalent to canonical 
  % layer I (molecular layer) and layer A6 will be equivalent to canonical 
  % layer VI (innermost...)
  d=1-layerdepths(p);
  assert(0==unix(sprintf('mris_expand -thickness %s/surf/%s.white %.2f %s/surf/%s.layer%s%d',fsdir,hemis{q},d,fsdir,hemis{q},layerprefix,p)));
end

%%%%%%%%%% subdivide layer and other surfaces (creating dense surfaces)

% calc a list of surfaces
surfs = {'inflated' 'sphere' 'sphere.reg'};
for p=1:length(layerdepths)
  surfs{end+1} = sprintf('layer%s%d',layerprefix,p);  % e.g. 'layerA1'
end

% subdivide the surfaces
parfor ii=1:2*length(surfs)
  p = mod2(ii,length(surfs));
  q = ceil(ii/length(surfs));
  assert(0==unix(sprintf('mris_mesh_subdivide --surf %s/surf/%s.%s --out %s/surf/%s.%sDENSE --method linear --iter 1',fsdir,hemis{q},surfs{p},fsdir,hemis{q},surfs{p})));
end

%%%%%%%%%% calculate some transfer functions for the dense surfaces

% calc
[tfunFSSSlh,tfunFSSSrh,tfunSSFSlh,tfunSSFSrh] = ...
  cvncalctransferfunctions(sprintf('%s/surf/lh.sphere.reg',fsdirAVG), ...
                           sprintf('%s/surf/rh.sphere.reg',fsdirAVG), ...
                           sprintf('%s/surf/lh.sphere.regDENSE',fsdir), ...
                           sprintf('%s/surf/rh.sphere.regDENSE',fsdir));

% save
save(sprintf('%s/tfunDENSE.mat',dir0),'tfunFSSSlh','tfunFSSSrh','tfunSSFSlh','tfunSSFSrh');

%%%%%%%%%% truncate the dense surfaces based on the lh.<fstruncate> and rh.<fstruncate> fsaverage surfaces

% calc
fsnumlh = size(freesurfer_read_surf_kj(sprintf('%s/surf/%s.white',fsdirAVG,'lh')),1);
fsnumrh = size(freesurfer_read_surf_kj(sprintf('%s/surf/%s.white',fsdirAVG,'rh')),1);

% do it
for p=1:length(hemis)

  % calculate a vector of vertex values indicating which is included [fsaverage]
  surf = read_patch_asc(sprintf('%s/surf/%s.%s.patch.3d.asc',fsdirAVG,hemis{p},fstruncate));
  vals = zeros(1,fsnumlh+fsnumrh);
  if p==1
    vals(surf.vertices+1) = 1;
  else
    vals(fsnumlh+(surf.vertices+1)) = 1;
  end

  % transfer these values to the dense individual-subject surface and do a find.
  % this tells us indices of vertices in the dense surface that are valid
  if p==1
    validix = find(tfunFSSSlh(vals));
  else
    validix = find(tfunFSSSrh(vals));
  end

  % write out reduced surfaces
  for q=1:length(surfs)

    % read in the original dense surface
    [verticesA,facesA,tagblock] = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%sDENSE',fsdir,hemis{p},surfs{q}));
  
    % logical indicating which faces survive
    okfaces = all(ismember(facesA,validix),2);  % FACES x 1

    % calculate the new faces
    temp = facesA(okfaces,:);
    facesA = reshape(calcposition(validix,flatten(temp)),size(temp));
  
    % calculate the new vertices
    verticesA = verticesA(validix,:);
  
    % write out the truncated surface
    freesurfer_write_surf_kj(sprintf('%s/surf/%s.%sDENSETRUNC%s',fsdir,hemis{p},surfs{q},fstruncate),verticesA,facesA,tagblock);
    
  end

  % save the DENSE->DENSETRUNC indices (truncsize x 1)
  save(sprintf('%s/surf/%s.DENSETRUNC%s.mat',fsdir,hemis{p},fstruncate),'validix');
  
  % save the orig->DENSE indices (densesize x 1)
  numverts_orig = size(freesurfer_read_surf_kj(sprintf('%s/surf/%s.inflated',fsdir,hemis{p})),1);
  validix=cvntransfertodense(subjectid,1:numverts_orig,hemis{p},'nearest','inflated');
  save(sprintf('%s/surf/%s.DENSE.mat',fsdir,hemis{p}),'validix');
end

%%%%%%%%%% transfer thickness and curvature values from standard to dense

for p=1:length(hemis)

  % load
  a1 = load(sprintf('%s/%smidgray.mat',dir0,hemis{p}));
  a2 = load(sprintf('%s/surf/%s.DENSETRUNC%s.mat',fsdir,hemis{p},fstruncate));

  % transfer values
  thickness = cvntransfertodense(subjectid,a1.thickness,hemis{p},'nearest');
  curvature = cvntransfertodense(subjectid,a1.curvature,hemis{p},'nearest');
%  save(sprintf('%s/%smidgrayDENSE.mat',dir0,hemis{p}),'thickness','curvature');

  % write mgz
  cvnwritemgz(subjectid,'thicknessDENSE',thickness,hemis{p});
  cvnwritemgz(subjectid,'curvatureDENSE',curvature,hemis{p});

  % write mgz for truncated
  cvnwritemgz(subjectid,sprintf('thicknessDENSETRUNC%s',fstruncate),thickness(a2.validix),hemis{p});
  cvnwritemgz(subjectid,sprintf('curvatureDENSETRUNC%s',fstruncate),curvature(a2.validix),hemis{p});

  % write curv
  [verticesA,facesA] = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%sDENSE',fsdir,hemis{p},'inflated'));
  write_curv(sprintf('%s/surf/%sDENSE.curv',fsdir,hemis{p}),curvature,size(facesA,1));

  % write curv for truncated
  [verticesA,facesA] = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%sDENSETRUNC%s',fsdir,hemis{p},'inflated',fstruncate));
  write_curv(sprintf('%s/surf/%sDENSETRUNC%s.curv',fsdir,hemis{p},fstruncate),curvature(a2.validix),size(facesA,1));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SOME CHECKS

% cd /software/freesurfer/subjects/C0041/
% freeview -f surf/lh.layerA1:overlay=surf/lh.curv:edgethickness=0
% freeview -f surf/lh.layerA1DENSE:overlay=surf/lh.curvatureDENSE.mgz:edgethickness=0
% freeview -f surf/lh.inflated:overlay=surf/lh.curv:edgethickness=0
% freeview -f surf/lh.inflatedDENSE:overlay=surf/lh.curvatureDENSE.mgz:edgethickness=0
% freeview -f surf/lh.inflatedDENSETRUNCpt:overlay=surf/lh.curvatureDENSETRUNCpt.mgz:edgethickness=0
