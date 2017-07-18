function [R,Rimg] = drawroipoly(img,L)
R=[];

if(~iscell(L))
    L={L};
end

numlh=0;
numrh=0;
for h = 1:numel(L)
    if(isequal(L{h}.hemi,'lh'))
        numlh=L{h}.vertsN;
    elseif(isequal(L{h}.hemi,'rh'))
        numrh=L{h}.vertsN;
    end
end
if(isempty(img))
    img=findobj(gca,'type','image');
end

if(ishandle(img))
    if(~isequal(get(img,'type'),'image'))
        img=findobj(img,'type','image');
    end
    rgbimg=get(img,'cdata');
else
    rgbimg=img;
    figure;
    imshow(rgbimg);
end

imgroi=[];
%press Escape to erase and start again
%double click on final vertex to close polygon
%right click on first vertex, and click "Create mask" to view the result
%Keep going until user closes the window
while(ishandle(img))
    [r,rx,ry]=roipoly();
    if(isempty(r))
        continue;
    end
    %r=im(:,:,1)==0;
    if(any(rx>L{1}.imgN))
        h=2;
        r=r(:,L{1}.imgN+1:end);
    else
        h=1;
        r=r(:,1:L{1}.imgN);
    end
    R=spherelookup_image2vert(r,L{h})>0;
    
    imgroi=spherelookup_vert2image(R,L{h},0);
    if(numel(L)>1)
        if(h==1)
            imgroi=[imgroi 0*imgroi];
        else
            imgroi=[0*imgroi imgroi];
        end
    end
    
    %quick way to merge rgbimg background with roi mask
    tmprgb=bsxfun(@times,rgbimg,.75*imgroi + .25);
    set(img,'cdata',tmprgb);
    
end

if(~isempty(L{h}.input2surf))
    vertidx=L{h}.input2surf(R);
end
if(isequal(L{h}.hemi,'rh'))
    vertidx=vertidx+numlh;
end
    
R=zeros(numlh+numrh,1);
R(vertidx)=1;

Rimg=imgroi;