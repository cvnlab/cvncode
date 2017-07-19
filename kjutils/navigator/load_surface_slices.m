function [surfslices,surfidx, vertidx] = load_surface_slices(subjectid,datadir,surfname,surfsuffix,varargin)
%[surfslices,surfidx] = load_surface_slices(subjectid,datadir,surfname,surfsuffix)


p = inputParser;
p.addParamValue('surfmask',[]);
p.addParamValue('surface',{});
p.addParamValue('reset',false);
p.addParamValue('savecache',true);

p.parse(varargin{:});
options = p.Results;

do_savecache=options.savecache;
resetcache=options.reset;
surfmask=options.surfmask;
surfacelist=options.surface;

if(~isempty(surfacelist) && numel(surfname) ~= numel(surfacelist))
    error('If you pass surface as argument, there must be a "surfname" for every surface');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(~isempty(datadir))
    epivolfile=sprintf('%s/freesurferalignment/T1alignedtoEPI.nii.gz',datadir);

    %%%%%%%%% dont need to read in whole file for this!
    epivol=loadvol(epivolfile);
    episize=size(epivol);


    alignfile=sprintf('%s/freesurferalignment/alignment.mat',datadir);
    load(alignfile);
else
    volfile=sprintf('%s/%s/mri/T1.nii.gz',cvnpath('freesurfer'),subjectid);
    epivol=loadvol(volfile);
    episize=size(epivol);
    
    tr=[];
end
if(~iscell(surfname))
    surfname={surfname};
end

surfslices_all={};
surfidx_all={};
cursurf=0;
vertidx_all={};

for s = 1:numel(surfname)

    surfslicedir=sprintf('%s/freesurferalignment/surfslices',datadir);

    fname=sprintf('surfslices_%s_%s_%s',subjectid,surfname{s},surfsuffix);

    surfslicefile=sprintf('%s/%s.mat',surfslicedir,fname);

    if(do_savecache && ~exist(surfslicedir,'dir'))
        mkdirquiet(surfslicedir);
    end

    if(~resetcache && exist(surfslicefile,'file'))
        M=load(surfslicefile);
        surfslices=M.surfslices;
        %surfidx=M.surfidx;
        vertidx=M.vertidx;
        numverts=M.numverts;
        clear M;
    else

        if(~isempty(surfacelist) && isstruct(surfacelist{s}))
            [surfLR, epiverts] = surface_verts_to_volume(...
                struct('vertices',surfacelist{s}.vertices,'faces',surfacelist{s}.faces),...
                tr);
        else
            [surfL,surfR]=cvnreadsurface(subjectid,{'lh','rh'},surfname{s},surfsuffix);
            [surfLR, epiverts] = surface_verts_to_volume_LR(surfL,surfR,tr);
        end

        [surfslices,vertidx]=surface_slices(episize,epiverts,surfLR.faces);
        %surfidx={};
        %for i = 1:3
        %    %surfidx{i}=cellfun(@(x)(all(x<=surfLR.numvertsL,2)+1),vertidx{i},'uniformoutput',false);
        %    surfidx{i}=cellfun(@(x)(ones(size(x))),vertidx{i},'uniformoutput',false);
        %end
        numverts=size(epiverts,1);
        if(do_savecache)
            %save(surfslicefile,'surfslices','surfidx','vertidx');

            save(surfslicefile,'surfslices','vertidx','numverts');
        end
    end
    
    surfidx={};
    for i = 1:3
        surfidx{i}=cellfun(@(x)(ones(size(x,1),1)),vertidx{i},'uniformoutput',false);
    end

    if(~isempty(surfmask) && size(surfmask,1)==numverts)
        for i = 1:3
            surfslices{i}=cellfun(@(x,y)x(any(surfmask(y)>0,2),:),surfslices{i},vertidx{i},'uniformoutput',false);
            surfidx{i}=cellfun(@(x,y)x(any(surfmask(y)>0,2),:),surfidx{i},vertidx{i},'uniformoutput',false);
            vertidx{i}=cellfun(@(x,y)x(any(surfmask(y)>0,2),:),vertidx{i},vertidx{i},'uniformoutput',false);
        end
    end
    
        
    if(isempty(surfslices_all))
        surfslices_all=surfslices;
    else
        for i = 1:3
            surfslices_all{i}=cellfun(@(x,y)([x; y]),surfslices_all{i},surfslices{i},'uniformoutput',false);
        end
    end
        
        
    if(isempty(surfidx_all))
        surfidx_all=surfidx;
    else
        for i = 1:3
            surfidx_all{i}=cellfun(@(x,y)([x; y+cursurf]),surfidx_all{i},surfidx{i},'uniformoutput',false);
        end
    end
    
    if(isempty(vertidx_all))
        vertidx_all=vertidx;
    else
        for i = 1:3
            vertidx_all{i}=cellfun(@(x,y)([x; y]),vertidx_all{i},vertidx{i},'uniformoutput',false);
        end
    end
    
    
    cursurf=cursurf+1;
end

surfslices=surfslices_all;
surfidx=surfidx_all;
vertidx=vertidx_all;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [surfLR, epiverts] = surface_verts_to_volume_LR(surfL,surfR,tr)


surfLR=struct('vertices',[surfL.vertices; surfR.vertices],...
    'faces',[surfL.faces; surfR.faces+size(surfL.vertices,1)]);

surfLR.numvertsL=size(surfL.vertices,1);
surfLR.numvertsR=size(surfR.vertices,1);
surfLR.numverts=surfLR.numvertsL+surfLR.numvertsR;
surfLR.vertidxL=reshape(1:surfLR.numvertsL,[],1);
surfLR.vertidxR=reshape((1:surfLR.numvertsR)+surfLR.numvertsL,[],1);

[surfLR, epiverts] = surface_verts_to_volume(surfLR,tr);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [surfLR, epiverts] = surface_verts_to_volume(surf,tr)


surfLR=surf;
surfLR.vertices=bsxfun(@plus,surfLR.vertices,[128 129 128]);  % NOTICE THIS!!!
if(~isfield(surf,'numvertsL'))
    surfLR.numvertsL=size(surfLR.vertices,1);
    surfLR.numvertsR=0;
    surfLR.numverts=surfLR.numvertsL+surfLR.numvertsR;
end
surfLR.vertidxL=reshape(1:surfLR.numvertsL,[],1);
surfLR.vertidxR=reshape((1:surfLR.numvertsR)+surfLR.numvertsL,[],1);
surfLR.neighbors=vertex_neighbours(surfLR);

if(~isempty(tr))
    epiverts4d = volumetoslices([surfLR.vertices ones(surfLR.numverts,1)].',tr);
    epiverts=epiverts4d(1:3,:)';
else
    epiverts=surfLR.vertices;
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function voldata = loadvol(niifile)
% load the T2 anatomy
vol = load_untouch_nii(gunziptemp(niifile));
voldata = double(vol.img);
voldata(isnan(voldata)) = 0;
