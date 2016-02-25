function fwhm = mesh_iter2fwhm_cvn(faces,verts,niters)
% fwhm = mesh_iter2fwhm_cvn(faces,verts,niters)
%
% Return the FWHM of the 2D gaussian kernel approximated by a number of 
%   iterations of vertex-neighbor averaging
%
% Inputs
%   faces:  Fx3 vertex indices for each triangular mesh face
%   verts:  Vx3 XYZ vertex coordinates
%   niters: Number of iterations to pass to mesh smoothing function.
%
% Outputs
%   fwhm:   Desired FWHM (in same units as vert locations)
%
% Based on cvnlab simulations with a regular hexagonal grid.

L = reshape(edgelengths(faces,verts),[],3);
s = sum(L,2)/2;
A = sqrt(s.*prod(bsxfun(@minus,s,L),2));
avgvtxarea = sum(A)/size(verts,1);

avgvtxarea_orig=0.85956;
fwhm012=[0.9605 2.1116 2.5596];

if(niters==0)
    fwhm_orig=fwhm012(1);
elseif(niters<1)
    a=1.1312;
    b=0.0564;
    fwhm_orig=a*niters.^2+b*niters+fwhm012(1);
elseif(niters<2)
    a=0.2327;
    b=0.2118;
    fwhm_orig=a*niters.^2+b*niters+fwhm012(2);
else
    %fit natural grid interp: fwhm=1.542*sqrt(iter+.75)
    %fit linear grid interp: fwhm=1.541*sqrt(iter+.7175)
    %fit nearest grid interp: fwhm=1.542*sqrt(iter+.5878)
    fwhm_orig = 1.542*sqrt(niters + 0.75);
end

fwhm=fwhm_orig*sqrt(avgvtxarea/avgvtxarea_orig);
