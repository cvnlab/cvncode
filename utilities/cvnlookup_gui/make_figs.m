function [rgbimg, L, S] = make_figs(sub, betas, se, viewmetric, cmap, con1, con2, metric_min, metric_max, L, S, HRF, bg, overlay_visibility)
% MAKE_FIGS creates the rgb image and lookup for the given inputs 
	% Get correct HRF string for results directory based on input
	if (~isempty(HRF))
		hrfstr = '_IC12';
	else
		hrfstr = '';
	end

	% Set the colormap
	cmap = eval([cmap, '(', num2str(100), ')']);

	% if cached values are passed in, use those. Otherwise, calculate from scratch
	if (isempty(S))
		% get number of vertices in inflated DENSETRUNCpt
		num_vertices_inflated = cvnreadsurface(sub,{'lh','rh'},'inflated','DENSETRUNCpt','justcount',true);
		numlh = num_vertices_inflated(1);
		numrh = num_vertices_inflated(2);

		% get ventral viewpoint
		viewpt = cvnlookupviewpoint(sub,{'rh','lh'},'ventral','inflated');

	else
		dumpstruct(S);
	end

	% setup image params
	metric = compute_glm_metric(betas,se,con1,con2,viewmetric,2);
	dataStruct = struct('data',metric,'numlh',numlh,'numrh',numrh);
	if overlay_visibility
		thresh = metric > metric_min;
	else
		thresh = zeros(length(metric),1);
	end
		
	clim = [metric_min metric_max];

	% draw image and create RGB
	[img, L, rgbimg] = cvnlookupimages(sub,dataStruct,{'rh','lh'},viewpt,L,'xyextent',[1 1],'surftype','inflated','imageres',1000,'overlayalpha',thresh,'cmap',cmap,'clim',clim, 'background', bg);
	if (isempty(S)) % first call to func
		S = fillstruct(numlh,numrh,viewpt);
	end
end %end fx
