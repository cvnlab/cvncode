function vals = cvnloadmgz(files)

% function vals = cvnloadmgz(files)
%
% <files> is a wildcard that matches one or more .mgz files
%
% Concatenate the values from these files along the first dimension and return.
% Useful for concatenating lh and rh data.

% match
files = matchfiles(files);
if isempty(files)
  warning('no files found');
end

% load and concatenate
vals = [];
for q=1:length(files)
  vals = [vals; load_mgh(files{q})];
end
