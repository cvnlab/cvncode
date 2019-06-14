function valstruct = valstruct_create(subject,surfsuffix,fillval)
%Initialize a valstruct for a given subject and surfsuffix
%valstruct = valstruct_create(subject,surfsuffix,data)
%
%Inputs:
% subject:      FreeSurfer subject ID (where surfaces are found)
% surfsuffix:   Surface type: DENSETRUNCpt|DENSE|orig (default=orig)
% fillval:      Initial value for data (default=0)
%
%Outputs:
% valstruct: struct with .data=(numlh+numrh)x1, .numlh, .numrh
%
%Examples:
%
%valstruct = valstruct_create('C1051','DENSETRUNCpt')
% valstruct = 
%      data: [870401x1 double]
%     numlh: 398939
%     numrh: 471462
%
%See also: valstruct_getdata, valstruct_setdata
%
% history:
% - 2019/06/13 - changed default for surfsuffix to 'orig'

if(~exist('surfsuffix','var') || isempty(surfsuffix))
%    surfsuffix='DENSETRUNCpt';
  surfsuffix = 'orig';
end

if(~exist('fillval','var') || isempty(fillval))
    fillval=[];
end

hemis={'lh','rh'};
[numlh, numrh] = cvnreadsurface(subject, hemis, 'sphere', surfsuffix, 'justcount',true);

% Set empty value struct
valstruct = struct('data',zeros(numlh+numrh,1),'numlh',numlh,'numrh',numrh);

if(~isempty(fillval))
    if(numel(fillval)==1 && (isnumeric(fillval) || islogical(fillval)))
        valstruct.data(:)=fillval; %single value
    else
        assert(size(fillval,1)==(numlh+numrh),'Input data is not the right size');
        valstruct.data=fillval;
    end
end
