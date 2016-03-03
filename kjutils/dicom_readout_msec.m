function ro = dicom_readout_msec(dcmfile,mode)
% ro = dicom_readout_msec(dcmfile[, mode])
%
% Read the dicom header for dcmfile, extract the relevant parameters,
% and compute the "total readout duration", IN MILLISECONDS, to be used 
% for EPI distortion correction.  FSL expects a slightly different value
% from SPM, so use <mode> argument to specify whether this is to be used
% for FSL, SPM, or CVNLab internal (same as 'SPM')
%
% Inputs
%   dcmfile: full path to a dicom file from your EPI time series
%   mode: Determines whether to subtract a line before computing. 
%         'FSL' = (npe-1)*echospacing
%         'SPM', or 'CVN' (default) = npe*echospacing
%         
% Outputs
%   ro: total EPI readout time, in milliseconds
%
% Note: iPAT is "included" in echo spacing when computed directly from the 
%  dicom header bpppe, so don't separately account for that
%
% Note: Partial fourier does NOT affect distortion

if(~exist('mode','var') || isempty(mode))
    mode='CVN';
end

dcminf = dicominfo(dcmfile);

% Use EJA's CSA parser to get hidden fields (with actual names)
dcmcsa = dicom_parse_csa(dcminf.Private_0029_1010);

bpppe = dcmcsa.BandwidthPerPixelPhaseEncode;
acqtxt = dcmcsa.AcquisitionMatrixText;
acqmatch = regexp(acqtxt,'^([0-9]+)p\*([0-9]+)','tokens');
npe = str2num(acqmatch{1}{1});
%nro = str2num(acqmatch{1}{2});

es=1/(bpppe*npe);

switch upper(mode)
    case 'FSL'
        ro=1000*(npe-1)*es;
    case {'SPM','CVN'}
        ro=1000*npe*es;
end
