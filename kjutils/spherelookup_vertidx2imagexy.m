function imagexy = spherelookup_vertidx2imagexy(vertidx,Lookup)
% helper function to map vertex indices to (x,y) image pixel coordinates 
% Handles input2surf conversion when needed
% Can handle multiple hemispheres if Lookup is a cell

if(iscell(Lookup))
    lh=0;
    rh=0;
    for i = 1:numel(Lookup)
        if(isequal(Lookup{i}.hemi,'lh'))
            lh=i;
        else
            rh=i;
        end
    end
    numlh=Lookup{lh}.inputN;
    numrh=Lookup{rh}.inputN;
                
    lhmask=vertidx<=numlh;
    rhmask=~lhmask;
    
    lhidx=vertidx(lhmask);
    rhidx=vertidx(rhmask)-numlh;
    lhxy=spherelookup_vertidx2imagexy(lhidx,Lookup{lh});
    rhxy=spherelookup_vertidx2imagexy(rhidx,Lookup{rh});
    if(lh==1)
        rhxy(:,1)=rhxy(:,1)+Lookup{1}.imgN;
    else
        lhxy(:,1)=lhxy(:,1)+Lookup{1}.imgN;
    end
    
    imagexy=zeros(numel(vertidx),2);
    imagexy(lhmask,:)=lhxy;
    imagexy(rhmask,:)=rhxy;
    return;
end


if(~isempty(Lookup.input2surf))
	%intersect() implicitly performs unique(), so do this
	%explicitly and maintain 1-to-1 vertex->imgagexy mapping
    [vu,~,v0]=unique(vertidx);
    [~,ia,ib]=intersect(Lookup.input2surf,vu);
    idx=ia(ib);
    idx=idx(v0);
else
    idx=vertidx;
end
idx=Lookup.reverselookup(idx);
[p1,p2]=ind2sub(size(Lookup.imglookup),idx);
%imagexy=[p1 p2]; %this would be [row, column]
imagexy=[p2 p1]; 