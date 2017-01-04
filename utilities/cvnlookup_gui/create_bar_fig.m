function f = create_bar_fig(means, sems, names)
% INPUTS, where N = number of bars
%	means - Nx1 col vector of means to plot along x axis
%	sems - Nx1 col vector of error to plot on bars
%	names - Nx1 cell vector of names to plot in legend

	N = length(means);
	colors = lines(N);

	f = figure;
	ax = axes('parent',f);
	hold(ax,'on');

	for i=1:N
		b = bar(i,means(i),0.5,'facecolor',colors(i,:));
	end
	errorbar(1:N,means,sems,'k.');
	legend(names);
	ylabel('Beta');
	set(gca,'XTickLabel',{[]});
end
