function niters = mesh_fwhm2iter_cvn(faces,verts,fwhm)
% niters = mesh_fwhm2iter_cvn(faces,verts,fwhm)
%
% Return the number of iterations of vertex-neighbor averaging to 
%   approximate a 2D gaussian kernel of the specified FWHM
%
% Inputs
%   faces:  Fx3 vertex indices for each triangular mesh face
%   verts:  Vx3 XYZ vertex coordinates
%   fwhm:   Desired FWHM (in same units as vert locations)
%
% Outputs
%   niters: Number of iterations to pass to mesh smoothing function.  This
%           result can be fractional, in which case the mesh smoothing 
%           function should perform a weighted average of the iterations
%           before and after.
%
% Based on cvnlab simulations with a regular hexagonal grid.

L = reshape(edgelengths(faces,verts),[],3);
s = sum(L,2)/2;
A = sqrt(s.*prod(bsxfun(@minus,s,L),2));
avgvtxarea = sum(A)/size(verts,1);

fwhm012=[0.9605 2.1116 2.5596];
avgvtxarea_orig=0.85956;
fwhm_orig=fwhm/sqrt(avgvtxarea/avgvtxarea_orig);

if(fwhm<fwhm012(1))
    niters=0;
elseif(fwhm<fwhm012(2))
    a=1.1312;
    b=0.0564;
    c=fwhm012(1)-fwhm_orig;
    niters=(-b+sqrt(b^2-4*a*c))/(2*a);
elseif(fwhm<fwhm012(3))
    a=0.2327;
    b=0.2118;
    c=fwhm012(2)-fwhm_orig;
    niters=1+(-b+sqrt(b^2-4*a*c))/(2*a);
else
    %fit natural grid interp: fwhm=1.542*sqrt(iter+.75)
    %fit linear grid interp: fwhm=1.541*sqrt(iter+.7175)
    %fit nearest grid interp: fwhm=1.542*sqrt(iter+.5878)
    niters=floor((fwhm_orig/1.542).^2 - 0.75);

    fwhm0 = 1.542*sqrt(niters + 0.75);
    fwhm1 = 1.542*sqrt(niters + 1 + 0.75);

    frac=(fwhm_orig-fwhm0)./(fwhm1-fwhm0);
    niters=niters+frac;
end
