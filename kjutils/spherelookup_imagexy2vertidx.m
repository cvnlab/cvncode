function vertidx = spherelookup_imagexy2vertidx(imgxy,Lookup)
% helper function to map (x,y) image pixel coordinates to vertex indices
% Handles input2surf conversion when needed
% Can handle multiple hemispheres if Lookup is a cell

if(iscell(Lookup))

    numlh=0;
    numrh=0;
    for i = 1:numel(Lookup)
        if(isequal(Lookup{i}.hemi,'lh'))
            numlh=Lookup{i}.inputN;
        else
            numrh=Lookup{i}.inputN;
        end
    end
    
    x0=0;
    vertidx=zeros(size(imgxy,1),1);
    for i = 1:numel(Lookup)
        xmax=x0+Lookup{i}.imgN;
        hmask=imgxy(:,1)>x0 & imgxy(:,1)<=xmax;
        imgxy2=imgxy(hmask,:);
        imgxy2(:,1)=imgxy2(:,1)-x0;
        v=spherelookup_imagexy2vertidx(imgxy2,Lookup{i});
        if(isequal(Lookup{i}.hemi,'rh'))
            v=v+numlh;
        end
        
        vertidx(hmask)=v;
        
        x0=x0+Lookup{i}.imgN;
    end
    return;
end

% %%%%%%%%%%%%%
x=min(size(Lookup.imglookup,2),max(1,round(imgxy(:,1))));
y=min(size(Lookup.imglookup,1),max(1,round(imgxy(:,2))));
xyind=sub2ind(size(Lookup.imglookup),y,x);
vertidx=Lookup.imglookup(xyind);
if(~isempty(Lookup.input2surf))
    vertidx=Lookup.input2surf(vertidx);
end
