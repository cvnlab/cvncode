function [conditions_all, conditions_base] = get_conditions(experiment)
	switch experiment
		case 'floc'
			conditions_all={'characters','bodies','faces','places','objects','word','number','body','limb','adult','child','corridor','house','car','instrument'};
			conditions_base={'word','number','body','limb','adult','child','corridor','house','car','instrument'};
		case 'C11'
			conditions_all = {'Right','Left','R30','R60','R90','R120','L30','L60','L90','L120','Front','Back'};
			conditions_base = {'R30','R60','R90','R120','L30','L60','L90','L120','Front','Back'};
		otherwise
			error('Experiment not recognized. Add it to the list!');
	end
end
