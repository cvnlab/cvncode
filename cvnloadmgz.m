function vals = cvnloadmgz(files)

% function vals = cvnloadmgz(files)
%
% <files> is a wildcard that matches one or more .mgz files
%
% Concatenate the values from these files into a column vector and return.

% match
files = matchfiles(files);

% load and concatenate
vals = [];
for q=1:length(files)
  vals = [vals; load_mgh(files{q})];
end
