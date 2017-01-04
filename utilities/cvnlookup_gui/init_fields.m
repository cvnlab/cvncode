function [betas, se, subject] = init_fields(resultsdir,hrfstr,regressor_range,layer)

	a1 = matfile(sprintf([resultsdir '/layer%s.mat'],layer));
	betas = a1.modelmd;
	reps_per_run = a1.reps_per_run;
	subject = a1.FSID;

	[betas, se] = compress_condition_split(betas,reps_per_run);
	betas = betas(:,regressor_range);
	se = se(:,regressor_range);
end

function [b,se] = compress_condition_split(betas,reps_per_run)
	% betas will be of form V x (num_conds * reps_per_run)
	[V,C_times_reps_per_run] = size(betas);
	
	C = C_times_reps_per_run / reps_per_run;

	for i=1:C
		start_idx = (i-1)*reps_per_run + 1;
		end_idx = start_idx + reps_per_run-1;

		subset = betas(:,start_idx:end_idx);
		b(:,i) = mean(subset,2);
		se(:,i) = std(subset,[],2)./sqrt(reps_per_run);
	end
end
