function [z,btx,bty]=logposrectratio(x,y,avgmetric,nboot)
%[z]=logposrectratio(x,y,avgmetric,nboot)
%computes the log posrect function of x over y of bootstrapped versions of x
%and y.
%
%bootstrap is performed by sampling with replacement the second dimension of
%x and y and performing the average of the bootstrap sample. If size(x,2)
%== to size(y,2) sampling with replacement is performed with the same
%bootstrap sample.
%
%inputs:
%<x> and <y> are matrices whose dimensions are respectively n,m and n,k;
%where n refers to different cases and m and k to the number of
%measurements.
%
%<avgmetric> is a string indicating the type of metric used for averaging
%across the bootstrapped sample (e.g. 'mean'). if it's empty the default
%is 'mean'.
%
%<nboot> is a scalar indicating the number of bootstrap. if it's empty the
%default is 1000.
%
%output:
%<z> is an n (i.e. cases) by nboot matrix containing the log ratio of
%positively rectified btx and bty, where btx and bty are boostrapped
%version of x and y.
%
%NOTE: when computing the ratio, this function handles 4 different cases:
%1. btx(j,i)>0 && bty(j,i)>0, z(j,i) is the log ratio between the 2 values
%2. btx(j,i)>0 && bty(j,i)<=0, z(j,i) is set to 1000
%3. btx(j,i)<=0 && bty(j,i)>0, z(j,i) is set to -1000
%4. btx(j,i)<=0 && bty(j,i)<=0, z(j,i) is set to 0 (i.e. log (1))
%
%example: 
%x=rand(10,20);
%y=rand(10,30);
%[z,btx,bty]=logposrectratio(x,y,'median',10000);

if ~exist('avgmetric','var') || isempty(avgmetric)
    avgmetric='mean';
end
if ~exist('nboot','var') || isempty(nboot)
    nboot=1000;
end

btx=zeros(size(x,1),nboot);
bty=zeros(size(y,1),nboot);

dim=real(size(x,2)==size(y,2));
switch dim
    case 0 % different bt samples
        for bti=1:nboot;
            btsamplex=randsample(1:size(x,2),size(x,2),'true');
            btsampley=randsample(1:size(y,2),size(y,2),'true');
            btx(:,bti)=eval(['squeeze(',avgmetric,'(x(:,btsamplex),2))']);
            bty(:,bti)=eval(['squeeze(',avgmetric,'(y(:,btsampley),2))']);
        end
    case 1 % same bt samples
        for bti=1:nboot;
            btsamplex=randsample(1:size(x,2),size(x,2),'true');
            btx(:,bti)=eval(['squeeze(',avgmetric,'(x(:,btsamplex),2))']);
            bty(:,bti)=eval(['squeeze(',avgmetric,'(y(:,btsamplex),2))']);
        end
end

%computing posrect ratio
tmpratio=posrect(btx)./posrect(bty);

%find cases in which x>0 && y=0
l1=isinf(tmpratio);
%find cases in which x=0 and y=0
l2=isnan(tmpratio);
%find cases in which x=0 && y>0
l3=tmpratio==0;

%computing log of ratio
z=log(tmpratio);
%replacing log ratio for cases in which x>0 && y=0 with 1000
z(l1)=1000;
%replacing log ratio for cases in which x=0 && y=0 with 0 (i.e. log(1))
z(l2)=0;
%replacing log ratio for cases in which x=0 && y>0 with -1000
z(l3)=-1000;
