function convert_hcpsubj_to_cvnsubj(hcpdir,outputdir,grayres,outputsuffix)
% convert_hcpsubj_to_cvnsubj(hcpdir,outputdir,grayres,outputsuffix)
%
% Convert HCP *.surf.gii and *.shape.gii into surface and metric files
%
% Inputs:
%   hcpdir = HCP subject directory containing T1w/ and MNINonLinear/ with *.gii files
%   outputdir = new directory to place freesurfer-style outputs
%   grayres = 'native', '32k', '59k', '164k'
%           native|orig = native freesurfer resolution
%           32k = 2mm cifti (91282 grayordinates)
%           59k = 1.6mm cifti (170494 grayordinates)
%           164k = fsaverage resolution
%   outputsuffix = optional suffix to append to freesurfer-style output file names
%           default for 'native' or 'orig' = blank (ie: create "lh.white")
%           default for grayres = .32k, .59k (ie: create lh.white.32k)
%
% Examples:
% convert_hcpsubj_to_cvnsubj('~/Data/HCP3T/102311','~/Data/HCP3T_cvn/102311/surf','native')
% -> creates ~/Data/HCP3T_cvn/102311/surf/lh.white lh.curv, etc..
%
% convert_hcpsubj_to_cvnsubj('~/Data/HCP3T/102311','~/Data/HCP3T_cvn/102311/surf','32k')
% -> creates ~/Data/HCP3T_cvn/102311/surf/lh.white.32k lh.curv.32k, etc..
%
% convert_hcpsubj_to_cvnsubj('~/Data/HCP3T/102311','~/Data/HCP3T_cvn32k/102311/surf','32k','')
% -> creates ~/Data/HCP3T_cvn32k/102311/surf/lh.white lh.curv, etc.. (ie:
%    convert low-res 32k surfaces but no suffix)

switch(lower(grayres))
    case {'native','orig'}
        T1dir=sprintf('%s/T1w/Native',hcpdir);
        MNIdir=sprintf('%s/MNI/Native',hcpdir);
        suff1='.native';
        suff2='';

    otherwise
        T1dir=sprintf('%s/T1w/fsaverage_LR%s',hcpdir,grayres);
        MNIdir=sprintf('%s/MNINonLinear/fsaverage_LR%s',hcpdir,grayres);
        suff1=sprintf('.%s_fs_LR',grayres);
        suff2=sprintf('.%s',grayres);
        %suff2=suff1;
end

if(exist('outputsuffix','var'))
    suff2=outputsuffix;
end

mkdirquiet(outputdir);

hemis={'lh','rh'};

for h = 1:numel(hemis)
    H=upper(hemis{h}(1));
    
    surftypes={'midthickness','pial','white','inflated','very_inflated'};
    %In low res space, already exist as MSMSulc
    %(Optional: <surftype>_MSMAll)
    
    for st = 1:numel(surftypes)
        surftype=surftypes{st};
        f1=fullfilematch(sprintf('%s/%s.%s.%s%s.surf.gii',T1dir,'*',H,surftype,suff1));
        f2=sprintf('%s/%s.%s%s',outputdir,hemis{h},surftype,suff2);
        
        if(isempty(f1))
            continue;
        else
            f1=f1{1};
        end
        
        [~,cmdres]=system(sprintf('mris_convert %s %s',f1,f2));
    end
    
    %spheres only exist in MNINonLinear
    surftypes={'sphere','sphere.reg','sphere.reg.reg_LR','sphere.MSMSulc'};
    
    for st = 1:numel(surftypes)
        surftype=surftypes{st};
        f1=fullfilematch(sprintf('%s/%s.%s.%s%s.surf.gii',MNIdir,'*',H,surftype,suff1));
        f2=sprintf('%s/%s.%s%s',outputdir,hemis{h},surftype,suff2);
        
        if(isempty(f1))
            continue;
        else
            f1=f1{1};
        end
        [~,cmdres]=system(sprintf('mris_convert %s %s',f1,f2));
    end


    %%
    %Now convert metrics: have to use write_curv because mris_convert can't
    %create .curv files apparently

    %Convert native-resolution metrics
    %Note: curvature and sulc get sign-flipped in HCP pipeline, so reverse
    %that flip
    metrictypes={'curvature@curv','sulc','thickness'};
    metricflip={true,true,false};
    
    for mt = 1:numel(metrictypes)
        metric1=regexprep(metrictypes{mt},'@.*','');
        metric2=regexprep(metrictypes{mt},'.*@','');
        f1=fullfilematch(sprintf('%s/%s.%s.%s%s.shape.gii',MNIdir,'*',H,metric1,suff1));
        f2=sprintf('%s/%s.%s%s',outputdir,hemis{h},metric2,suff2);
        
        if(isempty(f1))
            continue;
        else
            f1=f1{1};
        end
        g=getfield(gifti(f1),'cdata');
        if(metricflip{mt})
            g=-g;
        end
        write_curv(f2,g,numel(g));
    end
    
end

