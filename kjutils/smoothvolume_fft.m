function Vsmooth = smoothvolume_fft(V, sigma, voxres)
% Vsmooth = smoothvolumes_fft(V, sigma, voxres)
% 
% Reproduce behavior of "fslmaths -s <sigma>", though with faster FFT
%
if(~exist('voxres','var') || isempty(voxres))
    voxres=1;
end

%sd_mm=1; %sigma_mm, this is the same as "fslmaths -s <sd_mm>"
fwhm_mm=2; %(same as "fslmaths -s .85")
sd_mm=fwhm_mm/(2*sqrt(2*log(2)));

ksz=(ceil(4*sigma/voxres)*2+1)*[1 1 1];
g=makegaussian3d(ksz,[.5 .5 .5],[1 1 1]*sigma/voxres./(ksz-1)); %do funny thing since sd is a fraction of ksz
g=g/sum(g(:));

Vsmooth=convolution3D_FFTdomain(V,g);
Vsmooth(~isfinite(Vsmooth))=0;
Vsmooth(abs(Vsmooth)<max(abs(Vsmooth(:)))*1e-8)=0; %just clean up the effectively 0 values



