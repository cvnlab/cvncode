function cmap = GenerateColormap(p, colors, n)
% cmap = GenerateColormap(p, colors, n)
%
% p = Mx1 position each color should appear (0 -> 1)
% colors = Mx3 rgb colors to interpolate (low -> high)
% n = how big should the colormap be (default 100)
%
% eg: GenerateColormap([0 .5 1],[0 0 1; 0 1 0; 1 0 0], 100) creates a
% blue(low val)->green->red(high val) colormap

if(nargin < 3)
    n = 100;
end

if(isempty(p))
    p = linspace(0,1,size(colors,1));
end

p = p/max(p);

cmap = [interp1(p,colors(:,1),linspace(0,1,n));
    interp1(p,colors(:,2),linspace(0,1,n));
    interp1(p,colors(:,3),linspace(0,1,n))]';


