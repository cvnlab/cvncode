function [compressed_betas, se] = compress_condition_split(betas,reps_per_run)
% COMPRESS_CONDITION_SPLIT compresses condition split results matrix
% INPUTS:
% 	betas - beta matrix of form V x (num_conds * reps_per_run), ...
%		where V is the number of vertices
%	reps_per_run - how many repetitions of each condition ...
%		occured in each run; i.e., the condition-split factor
% OUTPUTS:
%	compressed_betas - compressed betas, of form V x num_conds
%	se - standard error over repetitions, of form V x num_conds

	% get dimensions of input matrix
	[V, C_times_reps_per_run] = size(betas);
	
	% compute number of true (experimental) conditions
	C = C_times_reps_per_run / reps_per_run;

	% for each condition, collapse over repetitions
	for i=1:C
		% determine region of beta matrix pertaining to condition i
		start_idx = (i-1)*reps_per_run + 1;
		end_idx = start_idx + reps_per_run-1;
		subset = betas(:,start_idx:end_idx);

		% compute betas and SEM for condition
		compressed_betas(:,i) = mean(subset,2);
		se(:,i) = std(subset,[],2)./sqrt(reps_per_run);
	end
end
