function [result,metricfiles] = cvnreadsurfacemetric(subject, hemi, metricname, surftype, surfsuffix, varargin)
% result = cvnreadsurfacemetric(subject, hemi, metricname, surftype, surfsuffix, 'param',value,...)
%
% Read a surface metric file (eg: curv, sulc, sapv) for given hemispheres,
%   surface type, etc...
%
% Inputs:
%   subject:            Freesurfer subject
%   hemi:               'lh','rh', or {'lh','rh'} (default={'lh','rh'})
%   metricname          'curv', 'sulc', 'sapv', ....
%   surftype:           '',sphere|inflated|white|pial|layerA1 ...
%   surfsuffix:         DENSE|DENSETRUNCpt|orig ("orig"=<hemi>.sphere)
%
% Outputs:
%   result:             Vx1 metric values or struct('data',<L+R>x1,'numlh',L,'numrh',R);
%
% Optional inputs:  'paramname','value',...
%   surfdir:         optional directory to search (default =
%                       <freesurfer>/<subj>/surf)
%
% Examples:
% >>  curv = cvnreadsurfacemetric('C0051', {'lh','rh'}, 'curv', '', 'DENSETRUNCpt')
% curv = 
%      data: [867225x1 double]
%     numlh: 399735
%     numrh: 467490
%
% >>  sapv1 = cvnreadsurfacemetric('C0051', {'lh','rh'}, 'sapv', 'layerA1', 'DENSETRUNCpt')
% sapv1 = 
%      data: [867225x1 double]
%     numlh: 399735
%     numrh: 467490

%%%%%%%%%%%%%%%%%%%%
%default options
options=struct(...
    'surfdir',[],...
    'verbose',false);

%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
%parse options
input_opts=mergestruct(varargin{:});
fn=fieldnames(input_opts);
for f = 1:numel(fn)
    opt=input_opts.(fn{f});
    if(~(isnumeric(opt) && isempty(opt)))
        options.(fn{f})=input_opts.(fn{f});
    end
end
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
surfdir=[];
if(~isempty(options.surfdir) && exist(options.surfdir,'dir'))
    surfdir=options.surfdir;
else
    freesurfdir=cvnpath('freesurfer');
    surfdir=sprintf('%s/%s/surf',freesurfdir,subject);
end

assert(exist(surfdir,'dir')>0,'Missing surf directory: %s',surfdir);

if(isempty(hemi))
    hemi={'lh','rh'};
elseif(ischar(hemi))
    hemi={hemi};
end

hemi=lower(hemi);
if(isequal(hemi,{'rh','lh'}))
    hemi={'lh','rh'};
end

if(strcmpi(surfsuffix,'orig'))
    suffix_file='';
else
    suffix_file=surfsuffix;
end

surftype_file='';
if(~isempty(surftype))
    surftype_file=sprintf('_%s_',surftype);
end

iscurvfile=zeros(numel(hemi),1);
metricpattern_all={sprintf('%s/%%s.%s%s%s',surfdir,metricname,surftype_file,suffix_file)
    sprintf('%s/%%s.%s%s%s.mgz',surfdir,metricname,surftype_file,suffix_file)
    sprintf('%s/%%s%s%s.%s',surfdir,surftype_file,suffix_file,metricname)};

metricpattern=[];

for m = 1:numel(metricpattern_all)
    iscurvfile(:)=false;
    for h = 1:numel(hemi)
        surffile=sprintf(metricpattern_all{m},hemi{h});
        iscurvfile(h)=exist(surffile,'file')>0;
    end
    if(all(iscurvfile))
        metricpattern=metricpattern_all{m};
        break;
    end
end

result=[];
metricfiles={};

if(isempty(metricpattern))
    if(~isempty(surftype))
        %if no file was found, try with blank surftype (many such as curv,
        % sulc, don't have a specific surftype)
        [result,metricfiles] = cvnreadsurfacemetric(subject, hemi, metricname, '', surfsuffix, varargin{:},'verbose',false);
        return;
    end
    
    if(options.verbose)
        wstr=repmat('\n%s',1,numel(metricpattern_all));
        warning(['No metric file found: ' wstr],metricpattern_all{:});
    end
    return;
else
    hvert={};
    hresult={};
    for h = 1:numel(hemi)
        metricfile=sprintf(metricpattern,hemi{h});
        [~,~,ext]=fileparts(metricfile);
        if(strcmpi(ext,'.mgz'))
            val=load_mgh(metricfile);
        else
            [val,~]=read_curv(metricfile);
        end
        hvert{h}=numel(val);
        hresult{h}=val(:);
        metricfiles{h}=metricfile;
    end
    if(isequal(hemi,{'lh','rh'}))
        result=struct('data',cat(1,hresult{:}),'numlh',hvert{1},'numrh',hvert{2});
    else
        result=cat(1,hresult{:});
    end
end
