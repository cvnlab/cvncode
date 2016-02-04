function S = fillstruct(varargin)
% returns a structure from a list of variables you input as arguments
%
% example:
% foo = 7;
% bar = 'some string';
% >> S = fillstruct(foo,bar)
% S = 
%     foo: 7
%     bar: 'some string'


S = struct();
for i = 1:nargin
    vname = inputname(i);
    val = varargin{i};
    
    if(isempty(vname))
        vname = val;
        val = evalin('caller',vname);
    end
    S.(vname) = val;
end
