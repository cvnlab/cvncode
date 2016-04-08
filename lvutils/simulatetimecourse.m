function [hrf,a,b,conva,convb]=simulatetimecourse(epochlength,ons1,ofs1,ons2,ofs2,ofstp1,ofstp2,amp1,amp2,noisescaler,hrfopt,flagnorm)
%[hrf,a,b,conva,convb]=simulatetimecourse(epochlength,ons1,ofs1,ons2,ofs2,ofstp1,ofstp2,amp1,amp2,noisescaler,hrfopt,flagnorm)
%
%Simulates and plots 2 timecourses of neural activity in millisecond with 
%added random noise and convolves it with a double gamma hrf. Hrf parameters 
%can be specified. It produces two figures:
%figure 1 shows the model hrf (normalised to peak at 1)
%figure 2 shows the simualted neural timecourse on the right plot and the
%time courses convolved with the modeled hrf on the right. The amplitude of
%the convolved timecourse is meaningless as it is by default normalised by
%the max of the largest timecourse (so that the max across timecourse is
%1). This function calls spm_Gpdf and vec2cell
%
%inputs
%<epochlength> length of epoch in ms
%
%<ons1> 2x1 row vector indicating the time of the first onsets. 
% ons1(1) refers to the onset of condition 1 and ons1(2) to condition 2
%
%<ons2> same as ons1, but it refers to second onset; if set to 0 or empty 
% there will be no second onset.
%
%<ofs1> 2x1 row vector indicating the first offsets of neural activity 
% ofs1(1) refers to the offset of condition 1 and ofs1(2) to condition 2
%
%<ofs2> same as ofs1, but it refers to second offsets; only relevant if ons2
% exists and is not empty or = 0;
%
%<ofstp1> 2x1 row vector indicating the number of timepoints you want 
% the linear decrease of the first offset to span for; ofstp1(1) refers to 
% the offset of condition 1 and ofstp1(2) to condition 2; if set to 0 the 
% simulted timecourse will have a sharp offset. It can be empty (default = [])
%
%<ofstp2> 2x1 same as ofstp2, but refering to the second offsets. 
% Only relevant if ons2 exists
%
%<noisescaler> scalar. must be > 0 use randn to generate noise and scales 
%it by this scalar. It can be empty; default = 100;
%
%<amp1> 2x1 row vector indicating amplitude scaler for first onset. 
% amp1(1) refers to amplitude of condition 1 and amp1(2) to condition 2.
% Amplitude scaler can be negative. It can be empty; default = 3
%
%<amp2> same as amp1; refers to the second onset. It is ignored if ons2
% is empty, set to 0 or non existent. 
%
%<hrfopts> 7x1 row vector indicating the HRF parameters. Optional;
%defaults:
%	hrfopts(1) - delay of response (relative to onset) = 6
%	hrfopts(2) - delay of undershoot (relative to onset) = 16
%	hrfopts(3) - dispersion of response = 1
%	hrfopts(4) - dispersion of undershoot = 1
%	hrfopts(5) - ratio of response to undershoot = 6
%	hrfopts(6) - onset (seconds) = 0
%	hrfopts(7) - length of kernel (seconds) = 32
%
% hrfopt can have an optional 8th entry specifying the fMRI_T; default = 16
%
%<normflag> if = 1 the convolved timecourses will be normalised
%independently so that they will both peak at 1. (Default 0)
%
%outputs
%<hrf> hrf
%
%<a> condition 1 simulated timecourse
%
%<b> condition 2 simulated timecourse
%
%<conva> condition 1 simulated timcourse convolved with hrf
%
%<convb> condition 2 simulated timcourse convolved with hrf
%
%example:
%epochlength=20000; % length of epoch in ms
%ons1(1)=1;activity onsets
%ons1(2)=1;
%[hrf,timecoursea,timecourseb,conva,convb]=simulatetimecourse(epochlength,ons1,[1000 12000])
%the command line above will produce 2 timecourses 20000 ms long. They will   
%both have a simulated neural activation onsetting at 1 ms, but the activation 
%of the first timecourse will last for 1000 ms, while that of the second
%timecourse will last for 12000 ms. Both timecourses will have a sharp
%offset
%
%NOTE that you dont have to feed all inputs; only the first 3 are required,
%however if you want to specify the linear decrease for the offset of 
%timecourse 1 (i.e. input 6), and you are not interested in second onsets 
%and offsets (i.e. inputs 4 and 5), you should feed empty vectors to the
%function- e.g.:
%
%[timecoursea,timecourseb,conva,convb,hrf]=simulatetimecourse(epochlength,ons1,[1000 12000],[],[],[100 0])
%this command will produce the same simualted neural activity as the first
%example, but this time the offset will be linearly decreasing over a 100 ms
%timewindow for timecourse 1, while the offset of timecourse 2 will be
%sharp



%hrf bit
if ~exist('hrfopt','var') || isempty(hrfopt)
hrfopt=[6 16 1 1 6 0 32];
end
if length(hrfopt)==7
fMRI_T=16;
else
    fMRI_T=hrfopt(8);
end
RT=.001; % resolution; milliseconds
dt    = RT/fMRI_T;
X     = [0:(hrfopt(7)/dt)] - hrfopt(6)/dt;
hrf   = spm_Gpdf(X,hrfopt(1)/hrfopt(3),dt/hrfopt(3)) - spm_Gpdf(X,hrfopt(2)/hrfopt(4),dt/hrfopt(4))/hrfopt(5);
hrf   = hrf([0:(hrfopt(7)/RT)]*fMRI_T + 1);
hrf   = hrf'./max(hrf);
figure,
plot(hrf)
ll=length(hrf)/(1/RT);
ll1=0:6:ll;
ll2=vec2cell(ll1);
set(gca,'Xtick',0:6000:length(hrf),'Xticklabels',ll2)
ax=axis;
axis([0 length(hrf) ax(3) ax(4)])
xlabel('seconds')
title('HRF')
%time course bit
if ~exist('flagnorm','var') || isempty(flagnorm)
    flagnorm=0;    
end
a=zeros(epochlength,1);
b=a;

% ofs1 
if ~exist ('amp1','var') || isempty(amp1)
    amp1=[3 3];
end
if exist ('ofstp1','var') && ~isempty(ofstp1)
    a(ons1(1):ofs1(1))=1*amp1(1);
    a(ofs1(1):ofs1(1)+ofstp1(1))=1*amp1(1):-1*amp1(1)/ofstp1(1):0;
    b(ons1(2):ofs1(2))=1*amp1(2);
    b(ofs1(2):ofs1(2)+ofstp1(2))=1*amp1(2):-1*amp1(2)/ofstp1(2):0;
else
    a(ons1(1):ofs1(1))=1*amp1(1);
    b(ons1(2):ofs1(2))=1*amp1(2);
end

% ofs2
if ~exist ('amp2','var') || isempty(amp2)
    amp2=[3 3];
end
if exist ('ofstp2','var') && ~isempty(ofstp2)
    if ons2(1)~=0
    a(ons2(1):ofs2(1))=1*amp2(1);
    a(ofs2(1):ofs2(1)+ofstp2(1))=1*amp2(1):-1*amp2(1)/ofstp2(1):0;
    end
    if ons2(2)~=0
    b(ons2(2):ofs2(2))=1*amp2(2);
    b(ofs2(2):ofs2(2)+ofstp2(2))=1*amp2(2):-1*amp2(2)/ofstp2(2):0;
    end
elseif exist ('ons2','var') && ~isempty(ons2)
    if ons2(1)~=0
    a(ons2(1):ofs2(1))=1*amp2(1);
    end
    if ons2(2)~=0
    b(ons2(2):ofs2(2))=1*amp2(2);
    end
end

% setting noise level
if ~exist('noisescaler','var') || isempty(noisescaler)
    noisescaler=100;
end
a=a+(randn(length(a),1)./noisescaler);
b=b+(randn(length(b),1)./noisescaler);

% plotting timecourses
figure
subplot(1,2,1)
plot(a); hold on
plot(b,'r')
ll=length(b)/(1/RT);
ll1=0:2:ll;
ll2=vec2cell(ll1);
set(gca,'Xtick',0:2000:length(b),'Xticklabels',ll2)
ax=axis;
axis([0 length(b) ax(3) ax(4)])
xlabel('seconds')
title ('simulated timecourses')

%
subplot(1,2,2)
conva=conv(a,hrf);
convb=conv(b,hrf);
if flagnorm==1
conva=conva./max(conva);
convb=convb./max(convb);
else
conva=conva./max(max([conva convb]));
convb=convb./max(max([conva convb]));
end
plot(conva); hold on
plot(convb,'r'); hold on
ll=length(convb)/(1/RT);
ll1=0:3:ll;
ll2=vec2cell(ll1);
set(gca,'Xtick',0:3000:length(convb),'Xticklabels',ll2)
ax=axis;
axis([0 length(convb) ax(3) ax(4)])
xlabel('seconds')
title ('simulated timecourses convolved with hrf')

