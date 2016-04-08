function rgb=colorspec2rgb(varargin)
%function rgb=ColorSpec(colornames)
%
%returns RGB values for a given ColorSpec name
% Inputs can be one of the following short names: 
%   y, m, c, r, g, b, w, k
% or one of the following long names:
%   yellow, magenta, cyan, red, green, blue, white, black
%
% Numerical inputs will be returned as-is (assumed to be RGB already)
%
% Examples:
% >> rgb=ColorSpec('r')
% rgb =
%      1     0     0
%
% >> rgb=ColorSpec('r','black')
% rgb =
%      1     0     0
%      0     0     0
%
% >> rgb=ColorSpec({'r','black'})
% rgb =
%      1     0     0
%      0     0     0

% KJ 2016-03-25: Use correct 'y' color

colorname={};
for i = 1:nargin
    v=varargin{i};
    if(iscell(v))
        colorname=[colorname v{:}];
    else
        colorname=[colorname v];
    end
end

rgb=[];
for i = 1:numel(colorname)
    if(isnumeric(colorname{i}))
        if(numel(colorname{i})~=3)
            error('numeric colorspec values must be 1x3');
        end
        rgb1=colorname{i};
        if(any(rgb1>1))
            rgb1=double(rgb1)/255;
        end
        rgb=[rgb; rgb1];
        continue;
    end
    switch lower(colorname{i})
        case {'y','yellow'}
            rgb1=[1 1 0];
        case {'m','magenta'}
            rgb1=[1 0 1];
        case {'c','cyan'}
            rgb1=[0 1 1];
        case {'r','red'}
            rgb1=[1 0 0];
        case {'g','green'}
            rgb1=[0 1 0];
        case {'b','blue'}
            rgb1=[0 0 1];
        case {'w','white'}
            rgb1=[1 1 1];
        case {'k','black'}
            rgb1=[0 0 0];
        otherwise
            error('Unknown color name: %s',colorname{i});
    end
    rgb=[rgb; rgb1];
end
