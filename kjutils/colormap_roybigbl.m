function cmap = colormap_roybigbl(n)
%cmap = colormap_roybigbl(n)
%
%A hot/cold colormap adapted from the ROYBIGBL colormap in HCP's wb_view
%tool.
%
%Negative (first half) = cyan->green->purple->blue->black (most neg-->zero)
%Positive (second half) = black->red->orange->yellow (zero-->most pos)

if(~exist('n','var') || isempty(n))
    n=64;
end

prgb=...
   [0            0     1      1
    0.0625       0     1      0
    0.1250       0     0.75   0
    0.1850       0.5   0.3    0
    0.2500       0.5   0      0.625
    0.3000       0.3   0      0.5
    0.3750       0     0      0.667
    0.5000       0     0      0
    0.8000       1     0      0
    0.8750       1     0.5    0
    1.0000       1     1      0];

cmap = GenerateColormap(prgb(:,1),prgb(:,2:4),n);
