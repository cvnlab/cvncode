function [destvals, lookupidx, validmask, sourcesuffix] = cvnlookupvertex(surfdir_or_subject,hemi,sourcesuffix,destsuffix,sourcevals,badval)
%[destvals, lookupidx, validmask,sourcesuffix] = cvnlookupvertex(surfdir_or_subject,hemi,sourcesuffix,destsuffix,[sourcevals],[badval])
%
% Transfer values from one set of vertices to another.
%
% eg: rh.DENSE to rh.DENSETRUNCpt:
% >> truncvals=cvnlookupvertex('C0041','rh','DENSE','DENSETRUNCpt',densevals);
% 
% Lookup can be returned for repeat mappings:
% >> [~,lookup,valid]=cvnlookupvertex('C0041','rh','DENSE','DENSETRUNCpt')
% >> truncvals=densevals(lookup);
% >> truncvals(~valid)=nan;
%
% Inputs:
%   surfdir_or_subject: Either a directory where surfaces are found, or the
%                         freesurfer subject ID
%   hemi:               lh or rh
%   sourcesuffix:       DENSE|DENSETRUNCpt|orig|fsaverage|fsaverageDENSE|fsaverageDENSETRUNCpt
%                         ("orig"=<hemi>.sphere)
%                         N=#vertices in source surface
%   destsuffix:         DENSE|DENSETRUNCpt|orig|fsaverage|fsaverageDENSE|fsaverageDENSETRUNCpt
%                         ("orig"=<hemi>.sphere)
%                         M=#vertices in destination surface
%   sourcevals:         NxT values to be transferred to new surface
%                         (default=[], only compute lookupidx and validmask)
%                         (can also be a =struct('data',<L+R>xT,'numlh',L,'numrh',R)
%   badval:             Value to place in destvals for destination vertices 
%                         without matching source vertices (default=nan)
%
% Outputs:
%   destvals:           MxT mapped values on destination surface vertices (or valstruct)
%   lookupidx:          Mx1 indices used for transferring 
%   validmask:          Mx1 logical mask for dest vertices with no mapped
%                         source vertex (false=no value for a given dest vertex)
%   sourcesuffix:       Optional output for source suffix, for instance when
%                         it was automatically detected instead of specified.
%

% Update KJ 1-26-2015: Add automatic detection of source type (based on size(vals))
% Update KJ 11-2-2016: Add fsaverage options and valstruct input options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(~exist('sourcevals','var') || isempty(sourcevals))
    sourcevals=[];
end

if(~exist('badval','var') || isempty(badval))
    badval=nan;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% if input was valstruct with both hemis
if(isstruct(sourcevals) && isfield(sourcevals,'numlh'))
    hemis={'lh','rh'};
    
    hdestvals={};
    hlookupidx={};
    hvalidmask={};
    hsourcesuffix={};
    
    for h = 1:numel(hemis)
        if(isempty(sourcevals.data))
            vals=[];
        else
            if(isequal(hemis{h},'lh'))
                vals=sourcevals.data(1:sourcevals.numlh,:);
            else
                vals=sourcevals.data(sourcevals.numlh+(1:sourcevals.numrh),:);
            end
        end
        [hdestvals{h}, hlookupidx{h}, hvalidmask{h}, hsourcesuffix{h}]=cvnlookupvertex(surfdir_or_subject,hemis{h},sourcesuffix,destsuffix,vals,badval);
    end
    if(isempty(sourcevals.data))
        numlh=hdestvals{1};
        numrh=hdestvals{2};
        destvals=struct('data',[],'numlh',numlh,'numrh',numrh);
    else
        numlh=size(hdestvals{1},1);
        numrh=size(hdestvals{2},1);
        destvals=struct('data',cat(1,hdestvals{:}),'numlh',numlh,'numrh',numrh);
    end
    lookupidx=hlookupidx;
    validmask=cat(1,hvalidmask{:});
    sourcesuffix=hsourcesuffix{1};
    
    return;
end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fsaverage transformations to/from truncated meshes
if(regexpmatch(sourcesuffix,'^fsaverageDENSETRUNC.+'))
    sourcesuffix_fsavg=strrep(sourcesuffix,'fsaverage','');
    [destvals1,lookupidx1,validmask1,sourcesuffix1]=cvnlookupvertex('fsaverage',hemi,sourcesuffix_fsavg,'DENSE',sourcevals,badval);
    [destvals2,lookupidx2,validmask2,sourcesuffix2]=cvnlookupvertex(surfdir_or_subject,hemi,'fsaverageDENSE',destsuffix,destvals1,badval);
    destvals=destvals2;
    lookupidx=lookupidx1(lookupidx2);
    validmask=validmask1(lookupidx2(validmask2));
    %sourcesuffix=sourcesuffix1;
    return;
elseif(regexpmatch(destsuffix,'^fsaverageDENSETRUNC.+'))
    destsuffix_fsavg=strrep(destsuffix,'fsaverage','');
    [destvals1,lookupidx1,validmask1,sourcesuffix1]=cvnlookupvertex(surfdir_or_subject,hemi,sourcesuffix,'fsaverageDENSE',sourcevals,badval);
    [destvals2,lookupidx2,validmask2,sourcesuffix2]=cvnlookupvertex('fsaverage',hemi,'DENSE',destsuffix_fsavg,destvals1,badval);
    destvals=destvals2;
    lookupidx=lookupidx1(lookupidx2);
    validmask=validmask1(lookupidx2(validmask2));
    sourcesuffix=sourcesuffix1;
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fsaverage transformations to/from non-matching pairs ( eg: not
% fsaverage->orig or fsaverageDENSE->DENSE )
midsuffix='';
if(isequal(sourcesuffix,'fsaverage') && ~isequal(destsuffix,'orig'))
    midsuffix='orig';
elseif(isequal(destsuffix,'fsaverage') && ~isequal(sourcesuffix,'orig'))
    midsuffix='orig';
elseif(isequal(sourcesuffix,'fsaverageDENSE') && ~isequal(destsuffix,'DENSE'))
    midsuffix='DENSE';
elseif(isequal(destsuffix,'fsaverageDENSE') && ~isequal(sourcesuffix,'DENSE'))
    midsuffix='DENSE';
end

if(~isempty(midsuffix))
    [destvals1,lookupidx1,validmask1,sourcesuffix1]=cvnlookupvertex(surfdir_or_subject,hemi,sourcesuffix,midsuffix,sourcevals,badval);
    [destvals2,lookupidx2,validmask2,sourcesuffix2]=cvnlookupvertex(surfdir_or_subject,hemi,midsuffix,destsuffix,destvals1,badval);
    destvals=destvals2;
    lookupidx=lookupidx1(lookupidx2);
    validmask=validmask1(lookupidx2(validmask2));
    sourcesuffix=sourcesuffix1;
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
surfdir=[];
if(ischar(surfdir_or_subject) && sum(surfdir_or_subject=='/' | surfdir_or_subject=='\')==0)
    freesurfdir=cvnpath('freesurfer');
    surfdir=sprintf('%s/%s/surf',freesurfdir,surfdir_or_subject);
elseif(exist(surfdir_or_subject,'dir'))
    surfdir=surfdir_or_subject;
end
assert(exist(surfdir,'dir')>0);

%%%%%%%%%%%%
%%% If sourcesuffix not specified, find surface with the same number of 
%%% vertices as input values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(isempty(sourcesuffix))
    inputtypes={'orig','DENSE','DENSETRUNCpt'};
    Nvals=size(sourcevals,1);
    
    for i = 1:numel(inputtypes)
        if(isequal(inputtypes{i},'orig'))
            suff_file='';
        else
            suff_file=inputtypes{i};
        end
        inputsurf=sprintf('%s/%s.sphere%s',surfdir,hemi,suff_file);
        if(~exist(inputsurf,'file'))
            continue;
        end
        ntmp=freesurfer_read_surf_kj(inputsurf,'justcount',true);
        if(ntmp == Nvals)
            sourcesuffix=inputtypes{i};
            %fprintf('Input type assumed based on vertex count: %s\n',inputtypes{i});
            break;
        end
    end
    if(isempty(sourcesuffix))
        error('No input type specified.  No surface file found with %d vertices.',Nvals);
    end
end
%%
%%%%%%%%%%%%
sourcesuffix_file=sourcesuffix;
destsuffix_file=destsuffix;

sourcesurfdir=surfdir;
destsurfdir=surfdir;


switch sourcesuffix
    case 'orig'
        sourcesuffix_file='';
    case 'fsaverage'
        sourcesuffix_file='.reg';
        sourcesurfdir=sprintf('%s/%s/surf',freesurfdir,'fsaverage');
    case 'fsaverageDENSE'
        sourcesuffix_file='.regDENSE';
        sourcesurfdir=sprintf('%s/%s/surf',freesurfdir,'fsaverage');
end

switch destsuffix
    case 'orig'
        destsuffix_file='';
    case 'fsaverage'
        destsuffix_file='.reg';
        destsurfdir=sprintf('%s/%s/surf',freesurfdir,'fsaverage');
    case 'fsaverageDENSE'
        destsuffix_file='.regDENSE';
        destsurfdir=sprintf('%s/%s/surf',freesurfdir,'fsaverage');
end


sourcesurf=sprintf('%s/%s.sphere%s',sourcesurfdir,hemi,sourcesuffix_file);
destsurf=sprintf('%s/%s.sphere%s',destsurfdir,hemi,destsuffix_file);

sourceN=freesurfer_read_surf_kj(sourcesurf,'justcount',true);
destN=freesurfer_read_surf_kj(destsurf,'justcount',true);

validmask=true(destN,1);

if(isequal(destsuffix,sourcesuffix))
    if(isempty(sourcevals))
        destvals=sourceN;
    else
        destvals=sourcevals;
    end
    
    lookupidx=(1:destN)';
    return;
end
    
desttype=regexprep(destsuffix,'^DENSETRUNC.+','DENSETRUNC');
sourcetype=regexprep(sourcesuffix,'^DENSETRUNC.+','DENSETRUNC');



switch [sourcetype '-' desttype]

    case 'DENSETRUNC-DENSE'
        truncfile=sprintf('%s/%s.%s.mat',surfdir,hemi,sourcesuffix_file);
        assert(exist(truncfile,'file')>0);
        vertmap=load(truncfile); %this is DENSETRUNC=DENSE(validix)

        dest2source=vertmap.validix;
        lookupidx=ones(destN,1);
        lookupidx(dest2source)=1:numel(dest2source);

        validmask=false(destN,1);
        validmask(dest2source)=true;
        
    case 'orig-DENSE'
        
        densefile=sprintf('%s/%s.%s.mat',surfdir,hemi,'DENSE');
        assert(exist(densefile,'file')>0);
        vertmap=load(densefile); %this is DENSE=orig(validix)
        lookupidx=vertmap.validix;
        
    case 'DENSE-DENSETRUNC'
        truncfile=sprintf('%s/%s.%s.mat',surfdir,hemi,destsuffix_file);
        assert(exist(truncfile,'file')>0);
        vertmap=load(truncfile); %this is DENSETRUNC=DENSE(validix)
        lookupidx=vertmap.validix;

    case 'orig-DENSETRUNC'
        densefile=sprintf('%s/%s.%s.mat',surfdir,hemi,'DENSE');
        assert(exist(densefile,'file')>0);
        vertmap=load(densefile); %this is DENSE=orig(validix)
        orig2dense=vertmap.validix;

        truncfile=sprintf('%s/%s.%s.mat',surfdir,hemi,destsuffix_file);
        assert(exist(truncfile,'file')>0);
        vertmap=load(truncfile); %this is DENSETRUNC=DENSE(validix)
        lookupidx=orig2dense(vertmap.validix);
        
    case 'DENSE-orig'
        lookupidx=1:destN;

    case 'DENSETRUNC-orig'
        truncfile=sprintf('%s/%s.%s.mat',surfdir,hemi,sourcesuffix_file);
        assert(exist(truncfile,'file')>0);
        vertmap=load(truncfile); %this is DENSETRUNC=DENSE(validix)

        dest2source=vertmap.validix;

        origtrunc=find(dest2source<=destN);
        dest2source=dest2source(origtrunc);

        lookupidx=ones(destN,1);
        lookupidx(dest2source(origtrunc))=origtrunc;

        validmask=false(destN,1);
        validmask(dest2source)=true;
        
    %%
    %%%%%%%%%%%%%%%%%%%%%%%%%
    % fsaverage transfers
    case 'DENSE-fsaverageDENSE'
        avgfile=sprintf('%s/%s.DENSE_to_fsaverageDENSE.mat',sourcesurfdir,hemi);
        assert(exist(avgfile,'file')>0);
        vertmap=load(avgfile); %this is fsaverageDENSE=DENSE(validix)

        lookupidx=vertmap.validix;
        
    case 'fsaverageDENSE-DENSE'
        avgfile=sprintf('%s/%s.fsaverageDENSE_to_DENSE.mat',destsurfdir,hemi);
        assert(exist(avgfile,'file')>0);
        vertmap=load(avgfile); %this is DENSE=fsaverageDENSE(validix)
        lookupidx=vertmap.validix;
        
    case 'orig-fsaverage'
        avgfile=sprintf('%s/%s.orig_to_fsaverage.mat',sourcesurfdir,hemi);
        assert(exist(avgfile,'file')>0);
        vertmap=load(avgfile); %this is fsaverage=orig(validix)

        lookupidx=vertmap.validix;
        
    case 'fsaverage-orig'
        avgfile=sprintf('%s/%s.fsaverage_to_orig.mat',destsurfdir,hemi);
        assert(exist(avgfile,'file')>0);
        vertmap=load(avgfile); %this is orig=fsaverage(validix)
        lookupidx=vertmap.validix;
       
        
    otherwise

end

destvals=[];
if(isempty(sourcevals))
    destvals=sourceN;
else
    if(size(sourcevals,1)~=sourceN && size(sourcevals,2)==sourceN)
        sourcevals=sourcevals.';
    end
    destvals=sourcevals(lookupidx,:);
    if(~isempty(badval))
        destvals(~validmask,:)=badval;
    end
end
