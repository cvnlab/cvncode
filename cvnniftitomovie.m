function cvnniftitomovie(files,movfile)

% function cvnniftitomovie(files,movfile)
%
% <files> is a path or wildcard matching some NIFTI files
% <movfile> is a .mov filename to write
%
% Load NIFTI files (4D volumes) and write out a QuickTime .mov file
% showing all of the volumes over time.  It is assumed that different
% NIFTI files have the same first three dimensions.

% deal with files
files = matchfiles(files);

% load all data
data = single([]);
for p=1:length(files)
  data = cat(4,data,single(getfield(load_untouch_nii(files{p}),'img')));
end

% write the movie out
viewmovie(data,{movfile 30});
