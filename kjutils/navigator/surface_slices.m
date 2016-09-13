function [slices, vidx] = surface_slices(volsize,vertices,faces,sorted_edges)

valid=vertices(:,1)>=1 & vertices(:,1)<=volsize(1) ...
    & vertices(:,2)>=1 & vertices(:,2)<=volsize(2) ...
    & vertices(:,3)>=1 & vertices(:,3)<=volsize(3);

if(~exist('sorted_edges','var') || isempty(sorted_edges))
    sorted_edges=[];
end

if(isempty(sorted_edges))
    faces=faces(all(valid(faces),2),:);
    edges=[faces(:,1) faces(:,2); faces(:,1) faces(:,3); faces(:,2) faces(:,3)];
    edges=unique(sort(edges,2),'rows');
else
    edges=sorted_edges;
end

otherdim={[2 3],[1 3],[1 2]};


slices=cell(1,3);
vidx=cell(1,3);
for d = 1:3
    %tic
    slices{d}=cell(1,volsize(d));
    vidx{d}=cell(1,volsize(d));
    vd1=vertices(edges(:,1),d);
    vd2=vertices(edges(:,2),d);
    vo1=vertices(edges(:,1),otherdim{d});
    vo2=vertices(edges(:,2),otherdim{d});
    for s = 1:volsize(d)
        %crossedges=vd1<=s & vd2>s;
        crossedges=sign(vd1-s)~=sign(vd2-s);
        d1=abs(vd1(crossedges)-s);
        d2=abs(vd2(crossedges)-s);
        
        %vt1=vd1-s;
        %vt2=vd2-s;
        %crossedges=sign(vt1)~=sign(vt2);
        %d1=abs(vt1(crossedges));
        %d2=abs(vt2(crossedges));
        dw=d1./(d1+d2);

        slices{d}{s}=bsxfun(@times,vo1(crossedges,:),1-dw)+bsxfun(@times,vo2(crossedges,:),dw);
        vidx{d}{s}=edges(crossedges,:);
    end
    %toc
end

