function xyline = roiline_calcline(xypoint)

% <xypoint> is pts x 2
%
% return <xyline> as points x 2 with pixels??

% rasterize line segments by interp1 with extra points (2*max), then prune
xyd=[0; sqrt(sum((xypoint(2:end,:)-xypoint(1:end-1,:)).^2,2))];
d=sum(xyd);
xyi=interp1(linspace(0,1,size(xypoint,1)),xypoint,linspace(0,1,2*d));
xyi=round(xyi);
xyi=xyi(any(xyi(2:end,:)~=xyi(1:end-1,:),2),:);

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
xyline=[xyi2(1:n,:); xyi(end,:)];

