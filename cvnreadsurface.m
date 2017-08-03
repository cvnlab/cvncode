function varargout = cvnreadsurface(subject, hemi, surftype, surfsuffix, varargin)
% surface_or_count = cvnreadsurface(subject, hemi, surftype, surfsuffix, 'param',value,...)
%
% Read a freesurfer surface (verts,faces) from file, or just the vertex count
%
% Inputs:
%   subject:            Freesurfer subject
%   hemi:               'lh','rh', or {'lh','rh'}
%   surftype:           sphere|inflated|white|pial|layerA1 ...
%   surfsuffix:         DENSE|DENSETRUNCpt|orig ("orig"=<hemi>.sphere)
%
% Outputs:
%   surface_or_count:   a struct for each hemisphere, containing
%                       Nx3 'vertices' and Fx3 'faces'
%
% Optional inputs:  'paramname','value',...
%   justcount:          true or false.  If true, return vertex count only  (default=false)
%
% Examples:
%   >> leftN=cvnreadsurface('C0041', 'lh', 'sphere', 'DENSETRUNCpt','justcount',true)
%   leftN =
%       412008
%
%   >> [leftN rightN]=cvnreadsurface('C0041', {'lh','rh'}, 'sphere', 'DENSETRUNCpt','justcount',true)
%   leftN =
%       412008
%   rightN =
%       469547
%
%   >> surfL=cvnreadsurface('C0041', 'lh', 'sphere', 'DENSETRUNCpt')
%  surfL = 
%      vertices: [412008x3 double]
%         faces: [821933x3 double]
%
%  >> [surfL surfR]=cvnreadsurface('C0041', {'lh','rh'}, 'sphere', 'DENSETRUNCpt')
%  surfL = 
%      vertices: [412008x3 double]
%         faces: [821933x3 double]
%  surfR = 
%      vertices: [469547x3 double]
%         faces: [937086x3 double]
%

% Update KJ 2017-08-03: Allow patch surface types

%%%%%%%%%%%%%%%%%%%%
%default options
options=struct(...
    'justcount',false,...
    'surfdir',[]);

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

assert(exist(surfdir,'dir')>0);

if(isempty(hemi))
    hemi={'lh','rh'};
elseif(ischar(hemi))
    hemi={hemi};
end

if(strcmpi(surfsuffix,'orig'))
    suffix_file='';
else
    suffix_file=surfsuffix;
end

result={};

for h = 1:numel(hemi)

    
    patchfile=[];
    if(regexpmatch(surftype,'\.patch\.'))
        suffix2=suffix_file;
        if(~isempty(suffix_file))
            suffix2=[suffix2 '.'];
        end

        patchfile=sprintf('%s/%s.%s%s',surfdir,hemi{h},suffix2,surftype);
        assert(exist(patchfile,'file')>0,'file not found: %s',patchfile);
        
        surffile=sprintf('%s/%s.%s%s',surfdir,hemi{h},'inflated',suffix_file);
    else
        surffile=sprintf('%s/%s.%s%s',surfdir,hemi{h},surftype,suffix_file);
    end
    
    assert(exist(surffile,'file')>0,'file not found: %s',surffile);
    
    
    if(options.justcount)
        vertsN = freesurfer_read_surf_kj(surffile,'justcount',true);
        result{h}=vertsN;
    else
        [verts,faces] = freesurfer_read_surf_kj(surffile);
        if(~isempty(patchfile))
            patch=fast_read_patch_kj(patchfile);
            patchmask=zeros(size(verts,1),1);
            patchmask(patch.vno)=1;
            verts(patch.vno,:)=[patch.x(:) patch.y(:) patch.z(:)];
            faces=faces(sum(patchmask(faces),2)==3,:);
        end
        result{h}=struct('vertices',verts,'faces',faces);
    end
end

if(numel(result) > 1 && nargout==1)
    varargout={result};
else
    varargout=result;
end

