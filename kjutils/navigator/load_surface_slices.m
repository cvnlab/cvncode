function [surfslices,surfidx] = load_surface_slices(subjectid,datadir,surfname,surfsuffix)
%[surfslices,surfidx] = load_surface_slices(subjectid,datadir,surfname,surfsuffix)

do_savecache=false;

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

for s = 1:numel(surfname)

    surfslicedir=sprintf('%s/freesurferalignment/surfslices',datadir);

    fname=sprintf('surfslices_%s_%s_%s',subjectid,surfname{s},surfsuffix);

    surfslicefile=sprintf('%s/%s.mat',surfslicedir,fname);

    if(do_savecache && ~exist(surfslicedir,'dir'))
        mkdirquiet(surfslicedir);
    end

    if(exist(surfslicefile,'file'))
        M=load(surfslicefile);
        surfslices=M.surfslices;
        surfidx=M.surfidx;
        clear M;
    else

        [surfL,surfR]=cvnreadsurface(subjectid,{'lh','rh'},surfname{s},surfsuffix);
        [surfLR, epiverts] = surface_verts_to_volume(surfL,surfR,tr);

        [surfslices,vidx]=surface_slices(episize,epiverts,surfLR.faces);
        surfidx={};
        for i = 1:3
            surfidx{i}=cellfun(@(x)(all(x<=surfLR.numvertsL,2)+1),vidx{i},'uniformoutput',false);
        end
        if(do_savecache)
            save(surfslicefile,'surfslices','surfidx');
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
    
    cursurf=cursurf+2;
end

surfslices=surfslices_all;
surfidx=surfidx_all;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [surfLR, epiverts] = surface_verts_to_volume(surfL,surfR,tr)


surfLR=struct('vertices',[surfL.vertices; surfR.vertices],...
    'faces',[surfL.faces; surfR.faces+size(surfL.vertices,1)]);
surfLR.vertices=bsxfun(@plus,surfLR.vertices,[128 129 128]);  % NOTICE THIS!!!
surfLR.numvertsL=size(surfL.vertices,1);
surfLR.numvertsR=size(surfR.vertices,1);
surfLR.numverts=surfLR.numvertsL+surfLR.numvertsR;
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
