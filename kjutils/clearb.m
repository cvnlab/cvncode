function clearb(varargin)
%clear but then restore breakpoints

s=dbstatus('-completenames');
save('tmpbreakpoints.mat', 's');
evalin('caller',['clear ' varargin{:} ';']);
load('tmpbreakpoints.mat');
dbstop(s);

delete('tmpbreakpoints.mat');
