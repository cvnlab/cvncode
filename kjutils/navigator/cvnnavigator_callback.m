function cvnnavigator_callback(varargin)

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
numlh=A.numlh;
numrh=A.numrh;


if(numel(varargin)>1 && isstruct(varargin{2}) && isfield(varargin{2},'Key'))
    event=varargin{2};
    keyhandled=false;
    bgidx=0;
    switch event.Key
        case 'b'
            bgidx=1;
            keyhandled=true;
        otherwise
    end

    if(bgidx > 0)
       if(isfield(A,'fig_epi') && ishandle(A.fig_epi))
            bgidx=orthogui(A.fig_epi,'getbackgroundidx');
            orthogui(A.fig_epi,'setbackgroundidx',bgidx+1);
        end
        if(isfield(A,'fig_anat') && ishandle(A.fig_anat))
            bgidx=orthogui(A.fig_anat,'getbackgroundidx');
            orthogui(A.fig_anat,'setbackgroundidx',bgidx+1);
        end
    end
    
    if(keyhandled)
        return;
    end
end

if(isequal(cbtype,'flatmap'))
    %click on flatmap
        
    ax=get(A.pflat(1),'parent');
    p=get(ax,'currentpoint');
    p=round(p(1,[2 1]));
    
    if(numel(varargin)>1 && isstruct(varargin{2}) && isfield(varargin{2},'Key'))
        p(2)=get(A.pflat(1),'xdata');
        p(1)=get(A.pflat(1),'ydata');
        event=varargin{2};
        dkey=[0 0];
        switch event.Key
            case 'rightarrow'
                dkey(2)=1;
            case 'leftarrow'
                dkey(2)=-1;
            case 'downarrow'
                dkey(1)=1;
            case 'uparrow'
                dkey(1)=-1;

        end
        p=p+dkey;
    else
        
    end
    
    if(p(2)>A.Lookup{1}.imgN)
        hemi=2;
        plookup=[p(1) p(2)-A.Lookup{1}.imgN];
    else
        plookup=p;
        hemi=1;
    end
    if(A.Lookup{hemi}.extrapmask(plookup(1),plookup(2)))
        return;
    end

    vertidx=A.Lookup{hemi}.imglookup(plookup(1),plookup(2));
    if(~isempty(A.Lookup{hemi}.input2surf))
        vertidx=A.Lookup{hemi}.input2surf(vertidx);
    end
    if(isequal(A.Lookup{hemi}.hemi,'rh'))
        vertidx=vertidx+numlh;
    end
elseif(isequal(cbtype,'patch'))
    %click on patch

    if(isequal(A.surfdisplay_hemi,'lh'))
        hemi=1;
    elseif(isequal(A.surfdisplay_hemi,'rh'))
        hemi=2;
    else
        error('Unknown surfdisplay_hemi: %s',A.surfdisplay_hemi);
    end
    idx=A.Lookup{hemi}.reverselookup(vertidx);
    [p1,p2]=ind2sub(size(A.Lookup{hemi}.imglookup),idx);
    p=[p1 p2];
elseif(isequal(cbtype,'orthogui'))
    %click on vol3d
    %return;
    [md,vertidx]=min((A.epiverts(:,1)-vertxyz(1)).^2 + ...
        (A.epiverts(:,2)-vertxyz(2)).^2 + ...
        (A.epiverts(:,3)-vertxyz(3)).^2);
    
    if(md>0.5)
        return;
    end


    if(vertidx>numlh)
        h='rh';
        vertlookup=vertidx-numlh;
    else
        h='lh';
        vertlookup=vertidx;
    end
    
    if(isequal(A.Lookup{1}.hemi,h))
        idx=A.Lookup{1}.reverselookup(vertlookup);
        [p1,p2]=ind2sub(size(A.Lookup{1}.imglookup),idx);
        p=[p1 p2];
    else
        idx=A.Lookup{2}.reverselookup(vertlookup);
        [p1,p2]=ind2sub(size(A.Lookup{2}.imglookup),idx);
        p=[p1 p2+A.Lookup{1}.imgN];
    end
    
    
end

if(isfield(A,'pflat') && all(ishandle(A.pflat)))
    set(A.pflat,'xdata',p(2),'ydata',p(1));
end

if(isfield(A,'hsurf') && all(ishandle(A.hsurf)))
    vsurf=get(A.hsurf,'vertices');
    if(isequal(A.surfdisplay_hemi,'lh') && vertidx<=numlh)
        vsurf=vsurf(vertidx,:);
    elseif(isequal(A.surfdisplay_hemi,'rh'))
        vsurf=vsurf(vertidx-numlh,:);
    end
    set(A.psurf,'xdata',vsurf(1),'ydata',vsurf(2),'zdata',vsurf(3));
end

if(isfield(A,'epiverts') && ~isequal(cbtype,'orthogui'))
    epicoord=A.epiverts(vertidx,:);
    if(isfield(A,'fig_epi') && ishandle(A.fig_epi))
        orthogui(A.fig_epi,'location_nocb',round(epicoord));
    end
    if(isfield(A,'fig_anat') && ishandle(A.fig_anat))
        orthogui(A.fig_anat,'location_nocb',round(epicoord));
    end
end

if(isfield(A,'callback') && ~isempty(A.callback))
    A.callback(vertidx);
end
