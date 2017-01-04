function valid = get_valid_func_vertices(betas,se,metricname,con1,con2,thresh)
%GET_VALID_FUNC_VERTICES returns binary mask of vertices that pass a given threshold for a particular metric

	metric = compute_glm_metric(betas,se,con1,con2,metricname,2);
	valid = metric > thresh;
	
end
