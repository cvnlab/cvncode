function [experiment, default_contrast] = data_dir_to_experiment(data_dir)

	date_start = regexp(data_dir,'[0-9]{8}');
	new_str = data_dir(date_start:end);
	parts = strsplit(new_str,'/');
	session = parts{1};

	switch session
		case '20160610-CVNS001-categoryC11'
			experiment = 'C11';
			default_contrast = 'RightVSLeft';
		case '20160815-KK_HRET'
			experiment = 'HRET';
			default_contrast = '';
		otherwise
			experiment = 'floc';
			default_contrast = 'facesVSall';
	end

end
