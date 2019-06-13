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
  temp = load_mgh(files{q});
  
  % if a vector along fourth dimension, re-orient to be column vector
  if size(temp,1)==1 && size(temp,2)==1 && size(temp,3)==1
    temp = permute(temp,[4 1 2 3]);
  end

  vals = [vals; temp];
end
