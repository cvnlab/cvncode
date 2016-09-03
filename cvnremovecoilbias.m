function cvnremovecoilbias(subjectid,numlayers,layerprefix,fstruncate,ppdir,degs)

% function cvnremovecoilbias(subjectid,numlayers,layerprefix,fstruncate,ppdir,degs)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate> is like 'pt'
% <ppdir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocessSURF'
% <degs> is a vector of polynomial degrees
%
% Use homogenizevolumes.m to bias-correct the mean maps in mean.mat (located
% within <ppdir>). We make sure to consider only the valid vertices (valid.mat).
%
% Save the results to meanbiascorrected%02d.mat and polyfit%02d.mat.
% In these results, we make sure that the invalid vertices are set to NaN.

%%%%%%%%%%%%%%%%%%%%%%% PREPARE

% define
hemis = {'lh' 'rh'};

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% load in coordinates of layer vertices
layerverts = {};
for i=1:numlayers
  [surfL,surfR] = cvnreadsurface(subjectid,hemis,sprintf('layer%s%d',layerprefix,i),sprintf('DENSETRUNC%s',fstruncate));
  layerverts{i} = [surfL.vertices; surfR.vertices];
end

% load in mean intensities
M = load(sprintf('%s/mean.mat',ppdir));

% load in valid mask
V = load(sprintf('%s/valid.mat',ppdir));

%%%%%%%%%%%%%%%%%%%%%%% FIT THE POLYNOMIALS

% calc
validmask = squish(permute(V.data,[3 2 1]),2);  % use only the VALID vertices

% do it
for p = degs

  % homogenize the data
  tic
  fprintf('Starting homogenize polydeg %d\n',p);
  [newvals,brainmask,polymodel] = ...
    homogenizevolumes(squish(permute(single(M.data),[3 2 1]),2), ...
                      [99 1/4 p Inf],[],validmask,catcell(1,layerverts));  %%%%% NOTE HARD-CODED CONSTANTS!
  toc
  fprintf('Finished homogenize polydeg %d\n',p);
  
  % set invalid voxels to NaN
  newvals(~validmask) = NaN;
  polymodel(~validmask) = NaN;

  % save bias-corrected mean
  T = setfield(M,'data',permute(reshape(newvals,[],numlayers),[3 2 1]));
  save(sprintf('%s/meanbiascorrected%02d.mat',ppdir,p),'-struct','T','-v7.3');

  % save polynomial fit
  T = setfield(M,'data',permute(reshape(polymodel,[],numlayers),[3 2 1]));
  save(sprintf('%s/polyfit%02d.mat',ppdir,p),'-struct','T','-v7.3');
  
end
