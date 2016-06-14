function [roimask, roidescription, roicolors] = cvnroimask(subject,hemi,roifile,roival,destsuffix,outputstyle)
% [roimask, roidescription, roicolors] = cvnroimask(subject,hemi,roifile,roival,destsuffix,outputstyle)
%
% subject = freesurfer subject ID
% hemi = lh or rh
% roifile = search string for files in <subject>/label/<hemi>*.mgz, *.annot, <hemi>*.label
%           Can contain wildcards
% roival =  For .mgz and .annot files, you can choose a particular ROI(s)
%               within the file, either:
%           1) by value (ie vertex label values) 
%        or 2) by name if <roifile>.ctab is available
% destsuffix = orig|DENSE|DENSETRUNCpt (defines output)
% outputstyle = cell(default)|collapsebinary|collapsevals|matrix|vals
%
% Outputs:
%   roimask=1xN cell array of Vx1 binary masks
%   roiname=1xN cell array of names for each roimask in output
%
% roifile argument can also be '<roival>@<roifile>' (in which case it 
%   ignores roival argument).
% Both roifile and roival can contain wildcards.
%
% Examples:
% [roimask,roidescription]=cvnroimask('C0045','rh','*_lv',[],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','Kastner2015Labels',[],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','V1*@Kastner*',[],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','1:3@Kastner*',[],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','[1 4 6]@Kastner*',[],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','Kastner*',[1 4 6],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','*cuneus*@aparc',[],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','*cuneus*@aparc',[],'DENSETRUNCpt');
% [roimask,roidescription]=cvnroimask('C0045','rh','G_occipital*@aparc.a2009s',[],'DENSETRUNCpt');

if(~exist('outputstyle','var') || isempty(outputstyle))
    outputstyle='cell';
end

freesurfdir=cvnpath('freesurfer');
subjdir=sprintf('%s/%s',freesurfdir,subject);
labeldir=sprintf('%s/label',subjdir);

roistr=[];
if(any(roifile=='@'))
    roiparts=strsplit(roifile,'@');
    roival=str2num(roiparts{1}); %#ok<ST2NM>
    if(isempty(roival))
        roistr=roiparts{1};
    end
    roifile=roiparts{2};
elseif(ischar(roival))
    tmpval=str2num(roival); %#ok<ST2NM>
    if(isempty(tmpval))
        roistr=roival;
        roival=[];
    else
        roival=tmpval;
        roistr=[];
    end
end

suffixes=[destsuffix setdiff({'DENSE','DENSETRUNCpt','orig'},destsuffix)];
labelext={'.mgz','.mgh','.label','.annot'};

roival_input=roival;
roistr_input=roistr;
roifile_input=roifile;

roimask={};
roidescription={};
roicolors={};
for s = 1:numel(suffixes)
    roifile=roifile_input;
    roival=roival_input;
    roistr=roistr_input;
    
    suffix=suffixes{s};
    if(isequal(suffix,'orig'))
        filesuffix='';
    else
        filesuffix=suffix;
    end
    
    %format: label/rh<surftype>.<roiname>.label
    labelname=sprintf('%s/%s%s.%s',labeldir,hemi,filesuffix,roifile);

    labelfiles={};

    w=warning('off');
    [~,~,ext]=fileparts(roifile);
    if(ismember(ext,labelext))
        labelfiles=matchfiles(labelname);
    else
        for le = 1:numel(labelext)
            labelfiles=[labelfiles matchfiles([labelname labelext{le}])];
        end
    end
    warning(w);
    
    
    [sourceN,lookup,valid]=cvnlookupvertex(subject,hemi,suffix,destsuffix);
    fullroi=zeros(size(lookup));
    fullroi(~valid)=0;
    
    for f = 1:numel(labelfiles)
        roifile=roifile_input;
        roival=roival_input;
        roistr=roistr_input;
        
        [fdir,fname,ext]=fileparts(labelfiles{f});
        
        
        %possible ctab filenames = <hemi><suffix>.<name>.<ext>.ctab
        %                       or <name>.<ext>.ctab
        ctabfile1=[fullfile(fdir,strrep(fname,sprintf('%s%s.',hemi,filesuffix),'')) ext '.ctab'];
        ctabfile2=[labelfiles{f} '.ctab'];
        
        if(exist(ctabfile1,'file'))
            ctabfile=ctabfile1;
        elseif(exist(ctabfile2,'file'))
            ctabfile=ctabfile2;
        else
            ctabfile=[];
        end

        islabel=false;
        ctab=[];
        switch(ext)
            case '.label'
                labelvert=read_ROIlabel(labelfiles{f});
                roi=zeros(sourceN,1);
                roi(labelvert)=1;
                islabel=true;
            case {'.mgz','.mgh'}
                roi=load_mgh(labelfiles{f});
                if(isempty(roival) && isempty(roistr))
                    roival=unique(roi);
                    roival(roival==0)=[];
                end
            case {'.annot'}
                [vertidx,vertlabel,ctab]=read_annotation(labelfiles{f});
                roi=zeros(sourceN,1);
                roi(vertidx+1)=vertlabel;
                if(isempty(roival) && isempty(roistr))
                    roival=unique(roi);
                    roival(roival==0)=[];
                end
        end
        
        roidesc={};
        roirgb={};
        if(~isempty(roival) || ~isempty(roistr))
            if(isempty(ctab) && ~isempty(ctabfile))
                ctab=read_ctab(ctabfile);
            end
            if(~isempty(roistr))
                roiidx=find(wildcardmatch(ctab.struct_names,roistr));
                
                roival=ctab.table(roiidx,end);
                roiidx=roiidx(roival~=0);
                roival=roival(roival~=0);
                
                roidesc=ctab.struct_names(roiidx);
                roirgb=ctab.table(roiidx,[1 2 3]);
            else
                %[roiidx,b]=ismember(ctab.table(:,end),roival);
                [b,roiidx]=ismember(roival,ctab.table(:,end));
                roiidx=roiidx(b);
                roidesc=ctab.struct_names(roiidx);
                roirgb=ctab.table(roiidx,[1 2 3]);
            end
        elseif(isempty(roival))
            roival=1;
            roidesc={};
        end
        
        valfound=ismember(roival,roi);
        roival=roival(valfound);
        if(~isempty(roidesc))
            roidesc=roidesc(valfound);
        end
        
        if(~islabel && isempty(roidesc) && ~isempty(roival))
            roidesc=cellfun(@num2str,num2cell(roival),'uniformoutput',false);
        end
        
        
        fullroi(valid)=roi(lookup(valid),:);
        roimask=[roimask bsxfun(@eq,fullroi,reshape(roival,1,[]))];
        
        roifilestr=strrep(fname,sprintf('%s%s.',hemi,filesuffix),'');
        for i = 1:numel(roival)
            if(~isempty(roidesc))
                roidescription=[roidescription sprintf('%s@%s',roidesc{i},roifilestr)];
            else
                roidescription=[roidescription roifilestr];
            end
        end
        if(~isempty(roirgb))
            roirgb=reshape(num2cell(double(roirgb)/255,2),1,[]);
        end
        roicolors=[roicolors roirgb];
    end
    
    if(~isempty(roimask))
        break;
    end
end

roimask=cat(2,roimask{:});


if(isequal(outputstyle,'collapsebinary'))
    roimask=max(roimask,[],2);
    if(numel(roidescription) > 1)
        roidescription={roifile};
    end
    if(numel(roirgb) > 1)
        roirgb={};
    end
elseif(isequal(outputstyle,'collapsevals'))
    roimask=max(roimask*diag(1:size(roimask,2)),[],2);
elseif(isequal(outputstyle,'mat'))
    
elseif(isequal(outputstyle,'vals'))
    roimask=fullroi;
else
    %converting columns to rows takes the longest
    roimask=num2cell(roimask,1);
end
