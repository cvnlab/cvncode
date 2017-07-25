function valstruct = valstruct_setdata(valstruct,hemi,data,fillval)
%Insert a single hemisphere's values into a valstruct
%
%valstruct = valstruct_setdata(valstruct,hemi,data,fillval)
%
%Inputs:
% valstruct: existing valstruct to use as template
% hemi:      'lh' or 'rh' or '': which hemi to insert (any other value = both)
% data:      (numlh)x1 or (numrh)x1 or (lh+hr)x1 
% [fillval]: optional single value to use for OTHER hemi (eg: 0)
%            If fillval is not provided or is empty, leave whatever was already
%            in valstruct for the other hemi
%
%Outputs:
% valstruct: struct with .data, .numlh, .numrh
%
%Examples:
%
%valstruct = valstruct_create('C1051','orig'); %initialize
%valstruct = valstruct_setdata(valstruct,'lh', lhdata, 0); %set 1:numlh to lhdata
%valstruct = valstruct_setdata(valstruct,'rh', rhdata);    %replace rest with rhdata
%
%OR: 
%valstruct = valstruct_setdata(valstruct,'rh', rhdata,0);  %zero-out lh, do rhdata only
%
%See also: valstruct_getdata, valstruct_create

if(~exist('fillval','var') || isempty(fillval))
    fillval=[];
end

if(iscell(hemi))
    if(numel(hemi)==1)
        hemi=hemi{1};
    else
        hemi='';
    end
end
if(~ischar(hemi))
    hemi='';
end


if(isempty(fillval))
    valstruct.data=valstruct.data(:,1:size(data,2));
else
    valstruct.data=fillval*ones(valstruct.numlh+valstruct.numrh,size(data,2));
end

switch(lower(hemi))
    case ''
        valstruct.data=data;
    case 'lh'
        valstruct.data(1:valstruct.numlh,:)=data;
    case 'rh'
        valstruct.data(valstruct.numlh+(1:valstruct.numrh),:)=data;
end
