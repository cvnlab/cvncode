function [pixelmask,xyline] = rasterline(xy,imgsize)
% generate binary pixel mask of line segments


xyline=[];
pixelmask=zeros(imgsize);
if(isempty(xy))
    return;
end

nanidx=find(any(isnan(xy),2));

if(size(xy,1)==1)
    xyi=round(xy);
    xyline=xyi;
    pixelmask(sub2ind(size(pixelmask),xyi(:,2),xyi(:,1)))=1;
    return;
end

if(nanidx(1)>1)
    nanidx=[0; nanidx];
end
if(nanidx(end)<size(xy,1))
    nanidx=[nanidx; size(xy,1)+1];
end

safetyfactor=10;

xyline={};
for ni = 1:numel(nanidx)-1
    xyseg=xy((nanidx(ni)+1):(nanidx(ni+1)-1),:);

    % rasterize line segments by interp1 with extra points (2*max), then prune
    xyd=[0; sqrt(sum((xyseg(2:end,:)-xyseg(1:end-1,:)).^2,2))];
    totald=sum(xyd);
    xyi=interp1(linspace(0,1,size(xyseg,1)),xyseg,linspace(0,1,safetyfactor*totald));
    xyi=round(xyi);
    xyi=xyi(any(xyi(2:end,:)~=xyi(1:end-1,:),2),:);
    if(isempty(xyi))
        return;
    end

    % prune again to remove "corners"
    xyi2=xyi;
    n=1;
    for i = 2:size(xyi,1)-1
        if(all(xyi2(n,:)==xyi(i,:) | xyi(i+1,:)==xyi(i,:)))
        else
            n=n+1;
            xyi2(n,:)=xyi(i,:);
        end
    end
    xyline_seg=[xyi2(1:n,:); xyi(end,:)];

    xyline{ni}=xyline;
    
    pixelmask(sub2ind(imgsize,xyline_seg(:,2),xyline_seg(:,1)))=1;
end

if(isempty(xyline))
    xyline=[];
elseif(numel(xyline)==1)
    xyline=xyline{1};
else
    xyline=cellfun(@(x)([x; nan nan]),xyline,'uniformoutput',false);
    xyline=cat(1,xyline{:});
end


