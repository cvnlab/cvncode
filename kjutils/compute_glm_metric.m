function vals = compute_glm_metric(beta,se_or_mean,con1,con2,metricname,cdim,numsplit)
% vals = compute_glm_metric(beta,se_or_mean,con1,con2,metricname,cdim)
%
% Return beta or contrast metrics for GLMdenoise results
%
% Inputs
%   beta:       beta values for C all conditions and all N voxels or vertices
%                eg: XxYxZxC (4D voxels x condition), 
%                    VxC (2D vertices x conditions)
%                    VxLxC (3D vertices x layers x conditions)
%   se_or_mean: std err values for all C conditions
%                eg: XxYxZxC
%               If C=1, assume this is SE of the entire model (see
%               "secommon")
%           OR  meanepi used for calculating <betaraw>=<beta>*<mean>/100
%   con1:       indices of positive condition(s) in <beta>
%   con2:       indices of negative condition(s) in <beta> (default: all
%               conditions EXCEPT those in con1
%				(If con2=0, tstat does not perform a contrast)
%   metricname: beta, betadiff, poscon, atan, betanorm, betanormL1, 
%               secommon, tstat
%   cdim:       category or condition dimension in <beta>
%
% Outputs
%   vals:       Map of metric values for each voxel or vertex
%                   XxYxZ, Vx1, VxL, etc...
%
% Metric details:
%   beta:       beta(con1)
%   betadiff:   beta(con1)-beta(con2)
%   betaraw:    beta(con1)*meanepi
%   poscon:     (posrect(a)-posrect(b)) / (posrect(a) + posrect(b))
%                where a=beta(con1), b=beta(con2), posrect(a)=a>0?a:0
%   atan:       atan(beta(con1)),beta(con2)) (0 = perfect contrast)
%   betanorm:   beta(con1)./sqrt(sum(beta(all).^2,cdim))
%   betanormL1: beta(con1)./sum(abs(beta(all))
%   secommon:   sqrt(mean(SE(all).^2,cdim))
%   tstat:      (beta(con1)-beta(con2))./secommon

betasize=size(beta);
sesize=size(se_or_mean);

if(isempty(beta))
    betasize=sesize;
end

if(~exist('numsplit','var') || isempty(numsplit))
    numsplit=0;
end

% 
% if(~isequal(betasize,sesize))
%     [s,d]=setdiff(betasize,sesize);
%     dnew=[];
%     for i = 1:numel(betasize)
%         if(betasize(i)==sesize(i))
%             dnew(i)=i;
%     end
% end


numcond=betasize(cdim);
if(numsplit>0)
    numcond=numcond/numsplit;
end

pdim=1:numel(betasize);
pdim_inv=[];
if(cdim>1)
    pdim=[cdim setdiff(1:numel(betasize),cdim)];
    [~,pdim_inv]=sort(pdim);
    beta=permute(beta,pdim);
    if(~isempty(se_or_mean))
        se_or_mean=permute(se_or_mean,pdim);
    end
end

if(numel(betasize)>2)
    beta=reshape(beta,size(beta,1),[]);
end

if(~isempty(sesize) && numel(sesize)>2)
    se_or_mean=reshape(se_or_mean,size(se_or_mean,1),[]);
end

if(isempty(con1))
    con1=1:numcond;
end

if(isempty(con2))
    con2=setdiff(1:numcond,con1);
end

if(~isempty(se_or_mean) && size(se_or_mean,1) > 1)
	if(isequal(con2,0))
		con_all=con1;
    else
		con_all=unique([con1(:); con2(:)]);
	end
    secommon=sqrt(mean(se_or_mean(con_all,:).^2,1));
else
    secommon=se_or_mean;
end

switch metricname
    case 'beta'
        vals=mean(beta(con1,:),1);
    case 'betanorm'
        vals=mean(beta(con1,:),1)./sqrt(sum(beta.^2,1));
    case 'betaraw'
        vals=mean(beta(con1,:),1).*se_or_mean/100;
    case 'betanormL1'
        vals=mean(beta(con1,:),1)./sum(abs(beta),1);
    case 'betadiff'
        vals=mean(beta(con1,:),1)-mean(beta(con2,:),1);
    case 'tstat'
		if(isequal(con2,0))
			vals=mean(beta(con1,:),1)./secommon;
		else
        	vals=(mean(beta(con1,:),1)-mean(beta(con2,:),1))./secommon;
		end
    case 'poscon'
        b1=posrect(mean(beta(con1,:),1));
        b2=posrect(mean(beta(con2,:),1));
        cnum=b1-b2;
        cdenom=b1+b2;
        vals=cnum./cdenom;
        vals(cdenom==0)=0;
    case 'atan'
        %posrect?
        vals=mod(atan2(mean(beta(con1,:),1),mean(beta(con2,:),1)),2*pi);
    case 'secommon'
        vals=secommon;
end

if(numel(betasize)>2)
    vals=reshape(vals,[1 betasize(pdim(2:end))]);
end

if(~isempty(pdim_inv))
    vals=permute(vals,pdim_inv);
end

