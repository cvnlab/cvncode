function cvnbasicfunctionalinspection(subjectid,numlayers,layerprefix,fstruncate,ppdir,outputdir)

% function cvnbasicfunctionalinspection(subjectid,numlayers,layerprefix,fstruncate,ppdir,outputdir)
%
% <subjectid> is like 'C0001'
% <numlayers> is like 6
% <layerprefix> is like 'A'
% <fstruncate> is like 'pt'
% <ppdir> is like '/home/stone-ext1/fmridata/20151008-ST001-kk,test/preprocessSURF'
% <outputdir> is like '/home/stone/generic/Dropbox/cvnlab/ppresults/C0041/functionalinspection/session/'
%
% Take the surface-based pre-processed results in <ppdir> and write out a bunch
% of figures to <outputdir>. These figures pertain to raw and bias-corrected
% signal intensities, the 'valid' vertices, the 'dark' (<.5) vertices, and tSNR.
% The figures explore dependence on layers and runs. Also, the results are 
% summarized using ROIs taken from Kastner2015Labels.
%
% todo:
% - maybe extend to HCP regions?

%%%%%%%%% setup

% constants
polydeg = 4;   % we just use this poly deg when inspecting the bias-correction results
numroi = 24;   % there are 24 Kastner ROIs

% make output directory
mkdirquiet(outputdir);

%%%%%%%%% load data

% load in valid mask
V = load(sprintf('%s/valid.mat',ppdir));

% load in homogenized
H = load(sprintf('%s/meanbiascorrected%02d.mat',ppdir,polydeg));

% load in mean intensities
M = load(sprintf('%s/mean.mat',ppdir));

% load in tSNR
tsnrfile = sprintf('%s/tsnr.mat',ppdir);
if exist(tsnrfile,'file')  % some sessions don't have this...  so we just make a blank figure in these cases...
  T = load(tsnrfile);
end

% define
hemis = {'lh' 'rh'};

% which runs to process?
files = matchfiles(sprintf('%s/run??.mat',ppdir));

% init
vals = NaN*zeros(length(files),length(hemis),numroi,numlayers,13);  % runs x hemis x roi x layers x quantities

% loop over runs
for pp=1:length(files)

  % load data
  a1 = load(files{pp});
  assert(a1.numlayers==numlayers);
  
  % loop over hemis
  for qq=1:length(hemis)
  
    % load ROIs
    [roimask,roidescription] = cvnroimask(subjectid,hemis{qq},'Kastner2015Labels',[],sprintf('DENSETRUNC%s',fstruncate));
    assert(length(roimask)==numroi);
    
    % figure out offset
    if isequal(hemis{qq},'lh')
      offset = 0;
    else
      offset = a1.numlh;
    end
    
    % loop over ROIs
    for rr=1:length(roimask)

      % loop over layers
      for ss=1:a1.numlayers
      
        % calc index
        ii = offset+find(roimask{rr});
      
        % get out?
        if isempty(ii)
          fprintf('empty case 1! pp=%d,qq=%d,rr=%d,ss=%d\n',pp,qq,rr,ss);
          continue;
        end

        % get the data
        data0 =   permute(double(a1.data(:,ss,ii)),[1 3 2]);   % TR x vertices
        valid0 =  permute(double( V.data(1,ss,ii)),[1 3 2]);   %  1 x vertices
        hom0 =    permute(double( H.data(1,ss,ii)),[1 3 2]);   %  1 x vertices
        mean0 =   permute(double( M.data(1,ss,ii)),[1 3 2]);   %  1 x vertices
        if exist(tsnrfile,'file')
          tsnr0 =   permute(double( T.data(1,ss,ii)),[1 3 2]);   %  1 x vertices
        else
          tsnr0 = NaN*zeros(1,length(mean0));
        end
        
        % calc index
        vv = find(valid0);   % NOTE: valid0 could be empty! but I think we won't crash

        % get the valid part
        data0 = data0(:,vv);    % TR x vertices
        hom0 =     hom0(vv);    %  1 x vertices
        mean0 =   mean0(vv);    %  1 x vertices
        tsnr0 =   tsnr0(vv);    %  1 x vertices

        % save some useful values
        temp = mean(data0,2);
        vals(pp,qq,rr,ss,1) = mean(temp,1);                     % for the ROI, mean intensity over time
        vals(pp,qq,rr,ss,2) = std(temp);                        % for the ROI, std over time
        vals(pp,qq,rr,ss,[3 4 5]) = prctile(mean0,[25 50 75]);  % IQR of the mean intensity across the ROI
        vals(pp,qq,rr,ss,6) = sum(hom0<.5)/length(hom0)*100;    % percent of the vertices that are dark
        vals(pp,qq,rr,ss,7) = sum(valid0)/length(valid0)*100;   % percent of the total vertices that are valid
        vals(pp,qq,rr,ss,[8 9 10]) = prctile(tsnr0,[25 50 75]); % IQR of the tSNR
        vals(pp,qq,rr,ss,[11 12 13]) = prctile(hom0,[25 50 75]);% IQR of the mean bias-corrected intensity across the ROI

% EXPERIMENTAL. REVIVE? IS THIS USEFUL?
%
%     % calc
%     outputdir = sprintf('%s/run%02d_%s',outputdir,pp,hemis{qq});
%
%         % do plots (only first run, first hemisphere)
%         if pp==1 && qq==1
% 
%           % show imagesc plots
%           figureprep([100 100 1200 900]);
%           subplot(2,1,1); hold on;
%           if ~isempty(data0)
%             imagesc(zeromean(data0,1)');  % zero-mean each vertex
%             axis([.5 size(data0,1)+.5 .5 size(data0,2)+.5]);
%             set(gca,'YDir','reverse');
%             cax = caxis; mx = max(abs(cax)); caxis([-mx mx]);
%             colormap(gray);
%     %        colorbar;
%           end
%           xlabel('TR');
%           ylabel('Vertices');
%           title(sprintf('Run %d, %s (%s), Layer %d, caxis +/- %.1f',pp,roidescription{rr},hemis{qq},ss,mx));
%         
%           % show mean time-series
%           subplot(2,1,2); hold on;
%           if ~isempty(data0)
%             plot(mean(data0,2)','r-');
%             ax = axis;
%             axis([.5 size(data0,1)+.5 ax(3:4)]);
%           end
%           xlabel('TR');
%           ylabel('Raw signal');
%           figurewrite(sprintf('ts_roi%03d_layer%d',rr,ss),[],[],outputdir);
%         
%         end
        
      end
    end
  end
end

%%%%%%%%% calc

roilabels = cellfun(@(x) regexprep(x,'\@.+',''),roidescription,'UniformOutput',0);

%%%%%%%%% histogram of darkness

% histogram of darkness (each vertex has a mean intensity; show only valid vertices)
darkness = double(M.data(logical(V.data)));
mn0 = median(darkness);
figureprep([100 100 500 400]); hold on;
hist(darkness(:),linspace(0,3*mn0,100));
ax = axis; axis([0 3*mn0 ax(3:4)]);
straightline(mn0,'v','r-');
xlabel('Signal intensity (raw)');
ylabel('Frequency');
title(sprintf('All valid vertices, mean intensity (median = %.1f)',mn0));
figurewrite('histdarknessraw',[],[],outputdir);

% histogram of darkness (each vertex has a mean intensity; show only valid vertices)
darkness = double(H.data(logical(V.data)));
mn0 = median(darkness);
figureprep([100 100 500 400]); hold on;
hist(darkness(:),linspace(0,3,100));
ax = axis; axis([0 3 ax(3:4)]);
straightline(mn0,'v','r-');
xlabel('Signal intensity (after bias-correction)');
ylabel('Frequency');
title(sprintf('All valid vertices, bias-corrected mean intensity (median = %.1f)',mn0));
figurewrite('histdarknessbiascorrected',[],[],outputdir);

%%%%%%%%% darkness breakdown by hemi and ROI

% prep
figureprep([100 100 1000 600]);

% just average across runs and layers and show hemis*ROIs
subplot(2,1,1); hold on;
temp = reshape(mean(mean(vals(:,:,:,:,1),1),4),[length(hemis) numroi]);  % average across runs and layers; hemi x roi
h = bar(flatten(temp'),1);
ax = axis; axis([0 length(hemis)*numroi+1 ax(3:4)]);
straightline(numroi+.5,'v','c-');
set(gca,'XTick',1:length(hemis)*numroi);
set(gca,'XTickLabel',[roilabels roilabels]);
ylabel('Signal intensity');
title('Signal intensity (averaged across runs and layers)');
xticklabel_rotate;
legend(h,{'0'},'Location','EastOutside');

% show the layer effects (on the median intensity within each ROI)
subplot(2,1,2); hold on;
cmap = jet(numlayers);
temp = permute(mean(vals(:,:,:,:,4),1),[3 2 4 1]);  % average across runs; roi x hemi x layers
h = [];
for pp=1:numlayers
  h(pp) = plot(squish(temp(:,:,pp),2),'.-','Color',cmap(pp,:));
end
ax = axis; axis([0 length(hemis)*numroi+1 ax(3:4)]);
straightline(numroi+.5,'v','k-');
set(gca,'XTick',1:length(hemis)*numroi);
set(gca,'XTickLabel',[roilabels roilabels]);
ylabel('Signal intensity');
title('Signal intensity as a function of layer (averaged across runs)');
xticklabel_rotate;
legend(h,mat2cellstr(1:6),'Location','EastOutside');

% write
figurewrite('darknessbreakdown',[],[],outputdir);

%%%%%%%%% inspect valid

figureprep([100 100 1500 300]); hold on;
temp = permute(squish(vals(1,:,:,:,7),2),[2 1 3]);  % just pull from the first run; roi x hemi x layer
bar(squish(temp,2),1);
ax = axis; axis([0 length(hemis)*numroi+1 0 100]);
straightline(numroi+.5,'v','c-');
set(gca,'XTick',1:length(hemis)*numroi);
set(gca,'XTickLabel',[roilabels roilabels]);
ylabel('Percentage that are valid');
title('Valid vertices as a function of layer');
xticklabel_rotate;
figurewrite('valid',[],[],outputdir);

%%%%%%%%% inspect dark (<.5)

figureprep([100 100 1500 300]); hold on;
temp = permute(squish(vals(1,:,:,:,6),2),[2 1 3]);  % just pull from the first run; roi x hemi x layer
bar(squish(temp,2),1);
ax = axis; axis([0 length(hemis)*numroi+1 0 ax(4)]);
straightline(numroi+.5,'v','c-');
set(gca,'XTick',1:length(hemis)*numroi);
set(gca,'XTickLabel',[roilabels roilabels]);
ylabel('Percentage that are dark (<.5)');
title('Dark vertices');
xticklabel_rotate;
figurewrite('dark',[],[],outputdir);

%%%%%%%%% inspect tsnr

figureprep([100 100 1500 300]); hold on;
temp = permute(squish(vals(1,:,:,:,9),2),[2 1 3]);  % just pull from the first run; roi x hemi x layer
bar(squish(temp,2),1);
ax = axis; axis([0 length(hemis)*numroi+1 0 ax(4)]);
straightline(numroi+.5,'v','c-');
set(gca,'XTick',1:length(hemis)*numroi);
set(gca,'XTickLabel',[roilabels roilabels]);
ylabel('tSNR (median across ROI)');
title('tSNR as a function of layer');
xticklabel_rotate;
figurewrite('tsnr',[],[],outputdir);

%%%%%%%%% inspect trends over runs (mean intensity)

figureprep([100 100 1500 300]); hold on;
temp = permute(mean(vals(:,:,:,:,1),4),[3 2 1]);  % average across layers; roi x hemi x run
bar(squish(temp,2),1);
ax = axis; axis([0 length(hemis)*numroi+1 0 ax(4)]);
straightline(numroi+.5,'v','c-');
set(gca,'XTick',1:length(hemis)*numroi);
set(gca,'XTickLabel',[roilabels roilabels]);
ylabel('Signal intensity');
title('Mean intensity in the ROI (then average across layers) as a function of runs');
xticklabel_rotate;
figurewrite('runtrendmean',[],[],outputdir);

%%%%%%%%% inspect trends over runs (std of the time-series)

figureprep([100 100 1500 300]); hold on;
temp = permute(mean(vals(:,:,:,:,2),4),[3 2 1]);  % average across layers; roi x hemi x run
bar(squish(temp,2),1);
ax = axis; axis([0 length(hemis)*numroi+1 0 ax(4)]);
straightline(numroi+.5,'v','c-');
set(gca,'XTick',1:length(hemis)*numroi);
set(gca,'XTickLabel',[roilabels roilabels]);
ylabel('Signal std dev');
title('Std dev of the ROI time-series (then average across layers) as a function of runs');
xticklabel_rotate;
figurewrite('runtrendstd',[],[],outputdir);

%%%%%%%%% scatter plot of mean intensity against tSNR

if exist(tsnrfile,'file')  

  todo = {{M 'Signal intensity' 'mean'} {H 'Bias-corrected intensity' 'homo'}};
  for zz=1:length(todo)
    X = todo{zz}{1};
    label0 = todo{zz}{2};
    file0 = todo{zz}{3};

    % set these the same for all layers
    xmx = prctile(flatten(double(X.data(logical(V.data)))),99.9);  % NOTE: only valid vertices
    ymx = prctile(flatten(double(T.data(logical(V.data)))),99.9);
    bxx = linspace(0,xmx,50);
    byy = linspace(0,ymx,50);

    % proceed
    for pp=1:numlayers
      figureprep([100 100 500 500]); hold on;
      vv = logical(V.data(1,pp,:));  % NOTE: only valid vertices
      xx = double(vflatten(X.data(1,pp,vv)));
      yy = double(vflatten(T.data(1,pp,vv)));
      zz = double(vflatten(H.data(1,pp,vv))) < 0.5;  % 1 means vein, 0 means not
      n1 = hist2d(xx(zz),yy(zz),bxx,byy);     % count for the veins
      n2 = hist2d(xx(~zz),yy(~zz),bxx,byy);   % count for the non-veins
      [n,x,y] = hist2d(xx,yy,bxx,byy);
      imagesc(x(1,:),y(:,1),log(n));
      %scattersparse(xx,yy,3000,0,16,'r');
      set(gca,'YDir','normal');
      axis([0 xmx 0 ymx]);
      caxis([0 log(max(n(:)))]);
      colormap(jet(256));
      straightline(median(xx),'v','r-');
      straightline(median(yy),'h','r-');
      xlabel(label0);
      ylabel('tSNR');
      title('2-D histogram (log of frequency)');
        % add some dots
      [ccx,ccy] = meshgrid(bxx,byy);
      basicallyempty = (n1+n2) < 10;
      ccx(basicallyempty) = NaN;
      ccy(basicallyempty) = NaN;
      scatter(ccx(:),ccy(:),16,cmaplookup(vflatten(n1./(n1+n2)),0,1,[],gray(256)),'filled');  % fraction that is vein
        % finish up
      figurewrite(sprintf('%svstsnr_layer%d',file0,pp),[],[],outputdir);
    end

  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ACTUALLY, I DON'T THINK WE CARE:
%
% %%%%%%%%% clear and save (in case we want to revisit the results later)
% 
% clear data0 darkness roimask a1 V H M T;
% save([outputdir '/record.mat']);
