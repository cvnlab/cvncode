function suffix = common_suffix(str)

suffix = fliplr(common_prefix(cellfun(@fliplr,str,'uniformoutput',false)));