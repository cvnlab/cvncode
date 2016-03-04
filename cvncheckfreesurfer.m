function cvncheckfreesurfer(subjectid,outputdir,skip,dims)

% function cvncheckfreesurfer(subjectid,outputdir,skip,dims)
%
% <subjectid> is like 'C0001'
% <outputdir> is like '/home/stone-ext1/anatomicals/C0001/checkfreesurfer'
% <skip> (optional) is number of slices to increment by. Default: 1.
% <dims> (optional) is a vector of slice dimensions to process. Default: [1 2 3].
%
% Write out diagnostic images of the FreeSurfer output.
% The images show slices through the T1 and contours of the white and 
% pial surfaces overlaid on these slices.

% internal constants
colors = {[0 .4  0] [0 1 0];
          [0 .4 .4] [0 1 1]};  % LH is green, RH is cyan; white is darker, pial is lighter
postfun = {@(x) flipdim(rotatematrix(x,1,2,1),2) ...  % post-process the image files
           @(x) flipdim(rotatematrix(x,1,2,1),2) ...
           @(x) flipdim(rotatematrix(x,1,2,1),2)};

% input
if ~exist('skip','var') || isempty(skip)
  skip = 1;
end
if ~exist('dims','var') || isempty(dims)
  dims = [1 2 3];
end

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% load T1 anatomy (can either be standard 1-mm isotropic 256 x 256 x 256, or something else!)
file0 = sprintf('%s/mri/T1.mgz',fsdir);
anat = fstoint(double(load_mgh(file0)));  % NOTICE the fstoint!
xyzsize = size(anat);
assert(xyzsize(1)==xyzsize(2) & xyzsize(2)==xyzsize(3));  % assume isotropic, equal matrix size
  %assert(isequal(xyzsize,[256 256 256]));

    % % load T2
    % file0 = sprintf('%s/mri/T2.mgz',fsdir);
    % t2exists = wantt2 && exist(file0,'file');
    % if t2exists
    %   anatt2 = fstoint(double(load_mgh(file0)));  % NOTICE the fstoint!
    % end

% load surfaces
prefixes = {'lh' 'rh'};
surfs = {'white' 'pial'};
vertices = {}; faces = {};
for p=1:length(prefixes)
  for q=1:length(surfs)
    [vertices{p,q},faces{p,q}] = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,prefixes{p},surfs{q}));
  end
end

% post-process surfaces for internal MATLAB use
for p=1:length(prefixes)
  for q=1:length(surfs)
    vertices{p,q} = bsxfun(@plus,vertices{p,q}',[128; 129; 128]);  % NOTICE THIS!!!
    vertices{p,q} = (vertices{p,q} - .5)/256 * xyzsize(1) + .5;  % DEAL WITH POTENTIALLY DIFFERENT RESOLUTION
    vertices{p,q}(4,:) = 1;  % now: 4 x V
    faces{p,q} = faces{p,q}(:,[1 3 2]);  % now: F x 3
  end
end

% calc neighbors
neighbors = {};
for p=1:length(prefixes)
  for q=1:length(surfs)
    neighbors{p,q} = facestoneighbors(faces{p,q},size(vertices{p,q},2));
  end
end

% figure out a reasonable contrast range for the T1
rng = prctile(anat(:),[1 99]);
    % if t2exists
    %   rngt2 = prctile(anatt2(:),[1 99]);
    % end

% process each slice orientation
for dim=dims
  fprintf('processing dim %d',dim);

  % process each slice
  for sl=1:skip:xyzsize(dim)
    statusdots(sl,xyzsize(dim));

    % prepare
    figureprep([100 100 900 900]);
    subplotresize(1,1); hold on;

    % get slice through the T1
    anatslice = squeeze(subscript(anat,indexall(3,dim,sl)));
            %     if t2exists
            %       anatslicet2 = squeeze(subscript(anatt2,indexall(3,dim,sl)));
            %     end

    % visualize the slice
    hh = imagesc(anatslice,rng);
    colormap(gray);
          % unnecessary:
          %     set(hh,'XData',resamplingindices(1,xyzsize(2),size(anatslice,2)));
          %     set(hh,'YData',resamplingindices(1,xyzsize(1),size(anatslice,1)));

    % deal with axis
    axis equal;
    axis([.5 size(anatslice,2)+.5 .5 size(anatslice,1)+.5]);
    set(gca,'YDir','reverse');

    % visualize the surface contours
    h = [];
    for p=1:length(prefixes)
      for q=1:length(surfs)
        isects = findfaceintersections(vertices{p,q},faces{p,q},dim,sl,neighbors{p,q});
        if isempty(isects)
          continue;
        end
        [faces0,vertices0,fvad0] = joinfaceintersections(vertices{p,q},isects);
        iix = find(all(abs(vertices0-sl)<1e-3,1));  % weird precision issue
        h = [h patch('Faces',faces0,'Vertices',fliplr(vertices0(:,setdiff(1:3,iix))), ...
              'FaceVertexAlphaData',fvad0,'FaceColor','none','LineWidth',1,'EdgeColor',colors{p,q},'EdgeAlpha',.5)];
      end
    end

    % init
    files = {};

    % write out volume with contours on top
    set(h,'EdgeAlpha',.5);
    set(hh,'CData',anatslice);
    caxis(rng);
    files = [files figurewrite(sprintf('slice%03d',sl),[],[],sprintf('%s/view%d_T1_surf',outputdir,dim),1)];

    % write out raw volume
    set(h,'EdgeAlpha',0);
    files = [files figurewrite(sprintf('slice%03d',sl),[],[],sprintf('%s/view%d_T1_vol',outputdir,dim),1)];
    
          %     % deal with T2
          %     if t2exists
          %       set(h,'EdgeAlpha',.5);
          %       set(hh,'CData',anatslicet2);
          %       caxis(rngt2);
          %       files = [files figurewrite(sprintf('slice%03d',sl),[],[],sprintf('%s/view%d_T2_surf',outputdir,dim),1)];
          %       set(h,'EdgeAlpha',0);
          %       files = [files figurewrite(sprintf('slice%03d',sl),[],[],sprintf('%s/view%d_T2_vol',outputdir,dim),1)];
          %     end
    
    % finally, close the figure!
    close;

    % perform post-processing
    processimages(files,postfun{dim});

  end
  fprintf('done.\n');

end
