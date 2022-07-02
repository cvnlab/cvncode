function cvncheckfreesurferalignment(subjectid,outputdir,meanfunctional,skip,dims,figuredir)

% function cvncheckfreesurferalignment(subjectid,outputdir,meanfunctional,skip,dims,figuredir)
%
% <subjectid> is like 'C0001'
% <outputdir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/freesurferalignment'
% <meanfunctional> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocess/mean.nii'
% <skip> (optional) is number of slices to increment by. Default: 1.
% <dims> (optional) is a vector of slice dimensions to process. Default: [1 2 3].
% <figuredir> (optional) is where to write figures to. Default: <outputdir>.
%
% Write out diagnostic images of the FreeSurfer output that reflect alignment to the
% EPI functional data. The images show the mean functional volume with contours of 
% the white and pial surfaces overlaid on these slices. We also create images that
% show slices through the T1 and T2 that reflect the alignment of the T1 and T2 to 
% the EPI.  The slices through the T1/T2 are matched exactly (field of view, resolution)
% to the mean functional volume.
%
% This function parallels cvncheckfreesurfer.m.
%
% history:
% - 2018/07/27 - substantial revamp of figure output; also add input <figuredir>
%
%
% THIS FUNCTION IS DEPRECATED due to the fstoint.m and vertex interpretation stuff.
% We keep it just for historical purposes.


fprintf('WARNING: THIS FUNCTION IS OBSOLETE!\n');


% internal constants
colors = {[0 .4  0] [0 1 0];
          [0 .4 .4] [0 1 1]};  % LH is green, RH is cyan; white is darker, pial is lighter

% input
if ~exist('skip','var') || isempty(skip)
  skip = 1;
end
if ~exist('dims','var') || isempty(dims)
  dims = [1 2 3];
end
if ~exist('figuredir','var') || isempty(figuredir)
  figuredir = outputdir;
end

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);

% load T1 anatomy (can either be standard 1-mm isotropic 256 x 256 x 256, or something else!)
file0 = sprintf('%s/mri/T1.nii.gz',fsdir);
t1vol = load_untouch_nii(file0);
t1volsize = t1vol.hdr.dime.pixdim(2:4);
t1vol = double(t1vol.img);
if t1vol.hdr.dime.scl_slope ~= 0
  t1vol = t1vol * t1vol.hdr.dime.scl_slope + t1vol.hdr.dime.scl_inter;
end
t1vol = fstoint(t1vol);  % NOTICE the fstoint!
t1vol(isnan(t1vol)) = 0;

% load T2 anatomy
file0 = sprintf('%s/mri/T2alignedtoT1.nii.gz',fsdir);
t2vol = load_untouch_nii(file0);
t2volsize = t2vol.hdr.dime.pixdim(2:4);
t2vol = double(t2vol.img);
if t2vol.hdr.dime.scl_slope ~= 0
  t2vol = t2vol * t2vol.hdr.dime.scl_slope + t2vol.hdr.dime.scl_inter;
end
t2vol = fstoint(t2vol);  % NOTICE the fstoint!
t2vol(isnan(t2vol)) = 0;

% calc
xyzsize = size(t1vol);
assert(isequal(size(t1vol),size(t2vol)));
assert(xyzsize(1)==xyzsize(2) & xyzsize(2)==xyzsize(3));  % assume isotropic, equal matrix size

% load transformation
load(sprintf('%s/alignment.mat',outputdir),'tr');

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
      %%%% this is not needed. i think it's because our internal space is true millimeters.
      %%%% vertices{p,q} = (vertices{p,q} - .5)/256 * xyzsize(1) + .5;
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

% take vertices to EPI space
for p=1:length(prefixes)
  for q=1:length(surfs)
    vertices{p,q} = volumetoslices(vertices{p,q},tr);
  end
end

% load the mean functional
epi = load_untouch_nii(meanfunctional);
episize = epi.hdr.dime.pixdim(2:4);
epi = double(epi.img);
if epi.hdr.dime.scl_slope ~= 0
  epi = epi * epi.hdr.dime.scl_slope + epi.hdr.dime.scl_inter;
end
epi(isnan(epi)) = 0;

% figure out a reasonable contrast range for the T1, T2, and EPI
rngt1 = prctile(t1vol(:),[1 99]);
rngt2 = prctile(t2vol(:),[1 99]);
rngepi = prctile(epi(:),[1 99]);

% get slices from the anatomy to match the EPI
t1match = extractslices(t1vol,t1volsize,epi,episize,tr);
t2match = extractslices(t2vol,t2volsize,epi,episize,tr);

% process each slice orientation
for dim=dims
  fprintf('processing dim %d',dim);

  % calc
  slicestodo = 1:skip:size(epi,dim);
  
  % pre-compute stuff
  t1matches = {};
  t2matches = {};
  epimatches = {};
  allvals = {};
  for sl=1:length(slicestodo)

    % get slices
    t1matches{sl} =  squeeze(subscript(t1match,indexall(3,dim,slicestodo(sl))));
    t2matches{sl} =  squeeze(subscript(t2match,indexall(3,dim,slicestodo(sl))));
    epimatches{sl} = squeeze(subscript(epi,    indexall(3,dim,slicestodo(sl))));

    % visualize the surface contours
    for p=1:length(prefixes)
      for q=1:length(surfs)
        isects = findfaceintersections(vertices{p,q},faces{p,q},dim,slicestodo(sl),neighbors{p,q});
        if isempty(isects)
          allvals{sl,p,q} = [];
          continue;
        end
        [faces0,vertices0,fvad0] = joinfaceintersections(vertices{p,q},isects);
        iix = find(all(abs(vertices0-slicestodo(sl))<1e-3,1));  % weird precision issue
        allvals{sl,p,q} = {faces0 vertices0 fvad0 iix};
      end
    end
  
  end
  
  % make one big figure
  figureprep([100 100 900*length(slicestodo) 900]);
  subplotresize(1,length(slicestodo));
  
  % each slice gets a different subplot
  hh = [];
  for sl=1:length(slicestodo)
    subplot(1,length(slicestodo),sl); hold on;

    % visualize the slice
    hh(sl) = imagesc(t1matches{sl},rngt1);
    colormap(gray);
          % unnecessary:
          %     set(hh,'XData',resamplingindices(1,xyzsize(2),size(anatmatch0,2)));
          %     set(hh,'YData',resamplingindices(1,xyzsize(1),size(anatmatch0,1)));

    % put the contours in
    h = [];
    for p=1:length(prefixes)
      for q=1:length(surfs)
        if isempty(allvals{sl,p,q})
          continue;
        end
        h = [h patch('Faces',allvals{sl,p,q}{1}, ...
                     'Vertices',fliplr(allvals{sl,p,q}{2}(:,setdiff(1:3,allvals{sl,p,q}{4}))), ...
                     'FaceVertexAlphaData',allvals{sl,p,q}{3}, ...
                     'FaceColor','none','LineWidth',1,'EdgeColor',colors{p,q},'EdgeAlpha',.5)];
      end
    end

    % deal with axis
    axis equal;
    axis([.5 size(t1matches{sl},2)+.5 .5 size(t1matches{sl},1)+.5]);
    set(gca,'YDir','reverse');
  end
  
  %%% T1:
  
  for sl=1:length(slicestodo)
    subplot(1,length(slicestodo),sl); hold on;
    set(hh(sl),'CData',t1matches{sl});
    caxis(rngt1);
  end
  figurewrite(sprintf('view%d_T1',dim),[],-1,sprintf('%s/',figuredir),1);

  %%% T2:
  
  for sl=1:length(slicestodo)
    subplot(1,length(slicestodo),sl); hold on;
    set(hh(sl),'CData',t2matches{sl});
    caxis(rngt2);
  end
  figurewrite(sprintf('view%d_T2',dim),[],-1,sprintf('%s/',figuredir),1);

  %%% EPI:
  
  for sl=1:length(slicestodo)
    subplot(1,length(slicestodo),sl); hold on;
    set(hh(sl),'CData',epimatches{sl});
    caxis(rngepi);
  end
  figurewrite(sprintf('view%d_EPI',dim),[],-1,sprintf('%s/',figuredir),1);

  %%% continue...

  % finally, close the figure!
  close;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% OLD WAY:
%
% function cvncheckfreesurferalignment(subjectid,outputdir,meanfunctional,skip,dims,figuredir)
% 
% % function cvncheckfreesurferalignment(subjectid,outputdir,meanfunctional,skip,dims,figuredir)
% %
% % <subjectid> is like 'C0001'
% % <outputdir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/freesurferalignment'
% % <meanfunctional> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocess/mean.nii'
% % <skip> (optional) is number of slices to increment by. Default: 1.
% % <dims> (optional) is a vector of slice dimensions to process. Default: [1 2 3].
% % <figuredir> (optional) is where to write figures to. Default: <outputdir>.
% %
% % Write out diagnostic images of the FreeSurfer output that reflect alignment to the
% % EPI functional data. The images show the mean functional volume with contours of 
% % the white and pial surfaces overlaid on these slices. We also create images that
% % show slices through the T1 and T2 that reflect the alignment of the T1 and T2 to 
% % the EPI.  The slices through the T1/T2 are matched exactly (field of view, resolution)
% % to the mean functional volume.
% %
% % This function parallels cvncheckfreesurfer.m.
% 
% % internal constants
% colors = {[0 .4  0] [0 1 0];
%           [0 .4 .4] [0 1 1]};  % LH is green, RH is cyan; white is darker, pial is lighter
% postfun = {@(x) rotatematrix(x,1,2,-1) ...  % post-process the image files
%            @(x) x ...
%            @(x) x};
% 
% % input
% if ~exist('skip','var') || isempty(skip)
%   skip = 1;
% end
% if ~exist('dims','var') || isempty(dims)
%   dims = [1 2 3];
% end
% if ~exist('figuredir','var') || isempty(figuredir)
%   figuredir = outputdir;
% end
% 
% % calc
% fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
% 
% % load T1 anatomy (can either be standard 1-mm isotropic 256 x 256 x 256, or something else!)
% file0 = sprintf('%s/mri/T1.nii.gz',fsdir);
% t1vol = load_untouch_nii(gunziptemp(file0));
% t1volsize = t1vol.hdr.dime.pixdim(2:4);
% t1vol = fstoint(double(t1vol.img));  % NOTICE the fstoint!
% t1vol(isnan(t1vol)) = 0;
% 
% % load T2 anatomy
% file0 = sprintf('%s/mri/T2alignedtoT1.nii.gz',fsdir);
% t2vol = load_untouch_nii(gunziptemp(file0));
% t2volsize = t2vol.hdr.dime.pixdim(2:4);
% t2vol = fstoint(double(t2vol.img));  % NOTICE the fstoint!
% t2vol(isnan(t2vol)) = 0;
% 
% % calc
% xyzsize = size(t1vol);
% assert(isequal(size(t1vol),size(t2vol)));
% assert(xyzsize(1)==xyzsize(2) & xyzsize(2)==xyzsize(3));  % assume isotropic, equal matrix size
% 
% % load transformation
% load(sprintf('%s/alignment.mat',outputdir),'tr');
% 
% % load surfaces
% prefixes = {'lh' 'rh'};
% surfs = {'white' 'pial'};
% vertices = {}; faces = {};
% for p=1:length(prefixes)
%   for q=1:length(surfs)
%     [vertices{p,q},faces{p,q}] = freesurfer_read_surf_kj(sprintf('%s/surf/%s.%s',fsdir,prefixes{p},surfs{q}));
%   end
% end
% 
% % post-process surfaces for internal MATLAB use
% for p=1:length(prefixes)
%   for q=1:length(surfs)
%     vertices{p,q} = bsxfun(@plus,vertices{p,q}',[128; 129; 128]);  % NOTICE THIS!!!
%       %%%% this is not needed. i think it's because our internal space is true millimeters.
%       %%%% vertices{p,q} = (vertices{p,q} - .5)/256 * xyzsize(1) + .5;
%     vertices{p,q}(4,:) = 1;  % now: 4 x V
%     faces{p,q} = faces{p,q}(:,[1 3 2]);  % now: F x 3
%   end
% end
% 
% % calc neighbors
% neighbors = {};
% for p=1:length(prefixes)
%   for q=1:length(surfs)
%     neighbors{p,q} = facestoneighbors(faces{p,q},size(vertices{p,q},2));
%   end
% end
% 
% % take vertices to EPI space
% for p=1:length(prefixes)
%   for q=1:length(surfs)
%     vertices{p,q} = volumetoslices(vertices{p,q},tr);
%   end
% end
% 
% % load the mean functional
% epi = load_untouch_nii(gunziptemp(meanfunctional));
% episize = epi.hdr.dime.pixdim(2:4);
% epi = double(epi.img);
% epi(isnan(epi)) = 0;
% 
% % figure out a reasonable contrast range for the T1, T2, and EPI
% rngt1 = prctile(t1vol(:),[1 99]);
% rngt2 = prctile(t2vol(:),[1 99]);
% rngepi = prctile(epi(:),[1 99]);
% 
% % get slices from the anatomy to match the EPI
% t1match = extractslices(t1vol,t1volsize,epi,episize,tr);
% t2match = extractslices(t2vol,t2volsize,epi,episize,tr);
% 
% % process each slice orientation
% for dim=dims
%   fprintf('processing dim %d',dim);
% 
%   for sl=1:skip:size(epi,dim)
%     statusdots(sl,size(epi,dim));
% 
%     % prepare
%     figureprep([100 100 900 900]);
%     subplotresize(1,1); hold on;
% 
%     % get slices
%     t1match0 = squeeze(subscript(t1match,indexall(3,dim,sl)));
%     t2match0 = squeeze(subscript(t2match,indexall(3,dim,sl)));
%     epi0 =     squeeze(subscript(epi,    indexall(3,dim,sl)));
% 
%     % visualize the slice
%     hh = imagesc(t1match0,rngt1);
%     colormap(gray);
%           % unnecessary:
%           %     set(hh,'XData',resamplingindices(1,xyzsize(2),size(anatmatch0,2)));
%           %     set(hh,'YData',resamplingindices(1,xyzsize(1),size(anatmatch0,1)));
% 
%     % deal with axis
%     axis equal;
%     axis([.5 size(t1match0,2)+.5 .5 size(t1match0,1)+.5]);
%     set(gca,'YDir','reverse');
% 
%     % visualize the surface contours
%     h = [];
%     for p=1:length(prefixes)
%       for q=1:length(surfs)
%         isects = findfaceintersections(vertices{p,q},faces{p,q},dim,sl,neighbors{p,q});
%         if isempty(isects)
%           continue;
%         end
%         [faces0,vertices0,fvad0] = joinfaceintersections(vertices{p,q},isects);
%         iix = find(all(abs(vertices0-sl)<1e-3,1));  % weird precision issue
%         h = [h patch('Faces',faces0,'Vertices',fliplr(vertices0(:,setdiff(1:3,iix))), ...
%               'FaceVertexAlphaData',fvad0,'FaceColor','none','LineWidth',1,'EdgeColor',colors{p,q},'EdgeAlpha',.5)];
%       end
%     end
% 
%     % init
%     files = {}; files2 = {};
% 
%     %%% T1:
% 
%     % write out volume with contours on top
%     set(h,'EdgeAlpha',.5);
%     set(hh,'CData',t1match0);
%     caxis(rngt1);
%     files = [files figurewrite(sprintf('slice%03d',sl),[],[1 72],sprintf('%s/png/view%d_T1_surf',figuredir,dim),1)];
%     files2 = [files2 figurewrite(sprintf('slice%03d',sl),[],0,sprintf('%s/eps/view%d_T1_surf',figuredir,dim),1)];
% 
%     % write out raw volume
%     set(h,'EdgeAlpha',0);
%     files = [files figurewrite(sprintf('slice%03d',sl),[],[1 72],sprintf('%s/png/view%d_T1_vol',figuredir,dim),1)];
%     files2 = [files2 figurewrite(sprintf('slice%03d',sl),[],0,sprintf('%s/eps/view%d_T1_vol',figuredir,dim),1)];
% 
%     %%% T2:
% 
%     % write out volume with contours on top
%     set(h,'EdgeAlpha',.5);
%     set(hh,'CData',t2match0);
%     caxis(rngt2);
%     files = [files figurewrite(sprintf('slice%03d',sl),[],[1 72],sprintf('%s/png/view%d_T2_surf',figuredir,dim),1)];
%     files2 = [files2 figurewrite(sprintf('slice%03d',sl),[],0,sprintf('%s/eps/view%d_T2_surf',figuredir,dim),1)];
% 
%     % write out raw volume
%     set(h,'EdgeAlpha',0);
%     files = [files figurewrite(sprintf('slice%03d',sl),[],[1 72],sprintf('%s/png/view%d_T2_vol',figuredir,dim),1)];
%     files2 = [files2 figurewrite(sprintf('slice%03d',sl),[],0,sprintf('%s/eps/view%d_T2_vol',figuredir,dim),1)];
% 
%     %%% EPI:
% 
%     % write out volume with contours on top
%     set(h,'EdgeAlpha',.5);
%     set(hh,'CData',epi0);
%     caxis(rngepi);
%     files = [files figurewrite(sprintf('slice%03d',sl),[],[1 72],sprintf('%s/png/view%d_EPI_surf',figuredir,dim),1)];
%     files2 = [files2 figurewrite(sprintf('slice%03d',sl),[],0,sprintf('%s/eps/view%d_EPI_surf',figuredir,dim),1)];
% 
%     % write out raw volume
%     set(h,'EdgeAlpha',0);
%     files = [files figurewrite(sprintf('slice%03d',sl),[],[1 72],sprintf('%s/png/view%d_EPI_vol',figuredir,dim),1)];
%     files2 = [files2 figurewrite(sprintf('slice%03d',sl),[],0,sprintf('%s/eps/view%d_EPI_vol',figuredir,dim),1)];
%   
%     %%% continue...
%  
%     % finally, close the figure!
%     close;
% 
%     % perform post-processing
%     processimages(files,postfun{dim});
% 
%   end
% end
