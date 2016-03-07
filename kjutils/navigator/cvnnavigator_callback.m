function test_vol_and_surf_clickfun(varargin)

cbtype='';
vertxyz=[];
vertidx=[];
h=[];
if(ischar(varargin{1}) && isequal(varargin{1},'orthogui'))
    vertxyz=varargin{2};
    cbtype='orthogui';
elseif(ishandle(varargin{1}))
    h=varargin{1};
    cbtype='flatmap';
else
    vertidx=varargin{1};
    cbtype='patch';
end
figflat=findobj(0,'tag','figflat');
if(isempty(figflat))
    return;
end

A=getappdata(figflat,'appdata');
dumpstruct(A);

if(isequal(cbtype,'flatmap'))
    %click on flatmap
    p=get(h,'currentpoint');
    p=round(p(1,[2 1]));
    
    if(p(2)>lookup{1}.imgN)
        hemi=2;
        plookup=[p(1) p(2)-lookup{1}.imgN];
    else
        plookup=p;
        hemi=1;
    end
    if(lookup{hemi}.extrapmask(plookup(1),plookup(2)))
        return;
    end

    vertidx=lookup{hemi}.imglookup(plookup(1),plookup(2));
    if(isequal(lookup{hemi}.hemi,'rh'))
        vertidx=vertidx+surfLR.numvertsL;
    end
elseif(isequal(cbtype,'patch'))
    %click on patch
    if(isequal(surfdisplay_hemi,lookup{1}.hemi))
        hemi=1;
    else
        hemi=2;
    end

    idx=lookup{hemi}.reverselookup(vertidx);
    [p1,p2]=ind2sub(size(lookup{hemi}.imglookup),idx);
    if(hemi==2)
        p2=p2+lookup{1}.imgN;
    end
    p=[p1 p2];
elseif(isequal(cbtype,'orthogui'))
    %click on vol3d
    %return;
    [md,vertidx]=min((epiverts(:,1)-vertxyz(1)).^2 + ...
        (epiverts(:,2)-vertxyz(2)).^2 + ...
        (epiverts(:,3)-vertxyz(3)).^2);
    
    if(md>0.5)
        return;
    end

    if(vertidx>surfLR.numvertsL)
        hemi=1;
        vertlookup=vertidx-surfLR.numvertsL;
        idx=lookup{hemi}.reverselookup(vertlookup);
        [p1,p2]=ind2sub(size(lookup{hemi}.imglookup),idx);
        p=[p1 p2];
    else
        hemi=2;
        vertlookup=vertidx;
        idx=lookup{hemi}.reverselookup(vertlookup);
        [p1,p2]=ind2sub(size(lookup{hemi}.imglookup),idx);
        p=[p1 p2+lookup{1}.imgN];
    end
    
    
end

set(pflat,'xdata',p(2),'ydata',p(1),'marker','o');


vsurf=get(hsurf,'vertices');
if(isequal(surfdisplay_hemi,lookup{hemi}.hemi))
    if(isequal(surfdisplay_hemi,'rh'))
        vsurf=vsurf(vertidx-surfLR.numvertsL,:);
    else
        vsurf=vsurf(vertidx,:);
    end
    
    set(psurf,'xdata',vsurf(1),'ydata',vsurf(2),'zdata',vsurf(3));
end



if(~isequal(cbtype,'orthogui'))
    epicoord=epiverts(vertidx,:);
    orthogui(fig_epi,'location_nocb',round(epicoord));
    orthogui(fig_anat,'location_nocb',round(epicoord));
end
