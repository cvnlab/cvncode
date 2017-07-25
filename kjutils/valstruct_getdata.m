function data = valstruct_getdata(valstruct,hemi)
%Return a single hemisphere's data from valstruct
%
%data = valstruct_getdata(valstruct,hemi)
%
%Inputs:
% valstruct: valstruct containing data, numlh, numrh
% hemi:      'lh' or 'rh' or '': which hemi to return (any other value = both)
%
%Outputs:
% data:      (numlh)x1 or (numrh)x1 or (lh+hr)x1 
%
%Examples:
%
%valstruct = valstruct_create('C1051','orig'); %initialize
%data = valstruct_getdata(valstruct,'lh'); %get the lh data (all zeros right now)
%
%See also: valstruct_setdata, valstruct_create

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

switch(lower(hemi))
    case ''
        data=valstruct.data;
    case 'lh'
        data=valstruct.data(1:valstruct.numlh,:);
    case 'rh'
        data=valstruct.data(valstruct.numlh+(1:valstruct.numrh),:);
end

