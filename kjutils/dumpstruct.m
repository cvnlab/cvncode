function dumpstruct(S)
% take a structure and copy it's fields out into the caller's workspace as
% LOCAL variables
%
% example:
% S.field1 = 8;
% S.field2 = 'some text';
%
% >> dumpstruct(S);
% >> field1
% field1 = 
%     8
% >> field2
% field2 = 
%     'some text'

if(isempty(S))
    return;
end
fnames = fieldnames(S);

if(isempty(inputname(1)))
    error('Argument must be a variable, not an expression');
end
for f = 1:numel(fnames)
    str = sprintf('%s = %s.%s;',fnames{f},inputname(1),fnames{f});
    evalin('caller',str);
end
