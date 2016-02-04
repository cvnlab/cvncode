function [tfunFSSSlh,tfunFSSSrh,tfunSSFSlh,tfunSSFSrh] = cvncalctransferfunctions(fslhfile,fsrhfile,sslhfile,ssrhfile)

% function [tfunFSSSlh,tfunFSSSrh,tfunSSFSlh,tfunSSFSrh] = cvncalctransferfunctions(fslhfile,fsrhfile,sslhfile,ssrhfile)
%
% <fslhfile>,<fsrhfile> are locations of the fsaverage spherical surfaces
% <sslhfile>,<ssrhfile> are locations of other surfaces registered on the sphere to fsaverage
%
% return functions that perform nearest-neigbor interpolation 
% to go back and forth between values defined on the surfaces.

% load spherical surfaces (note that we skip the post-processing of vertices and faces since unnecessary for what we are doing)
clear fslh fsrh;
[fslh.vertices,fslh.faces] = freesurfer_read_surf_kj(fslhfile);
[fsrh.vertices,fsrh.faces] = freesurfer_read_surf_kj(fsrhfile);
clear sslh ssrh;
[sslh.vertices,sslh.faces] = freesurfer_read_surf_kj(sslhfile);
[ssrh.vertices,ssrh.faces] = freesurfer_read_surf_kj(ssrhfile);

% define the functions
tempix = griddata(fslh.vertices(:,1),fslh.vertices(:,2),fslh.vertices(:,3),1:size(fslh.vertices,1), ...
                  sslh.vertices(:,1),sslh.vertices(:,2),sslh.vertices(:,3),'nearest');
tfunFSSSlh = @(x) double(flatten(x(tempix)));
tempix = griddata(fsrh.vertices(:,1),fsrh.vertices(:,2),fsrh.vertices(:,3),size(fslh.vertices,1)+(1:size(fsrh.vertices,1)), ...
                  ssrh.vertices(:,1),ssrh.vertices(:,2),ssrh.vertices(:,3),'nearest');
tfunFSSSrh = @(x) double(flatten(x(tempix)));
tempix = griddata(sslh.vertices(:,1),sslh.vertices(:,2),sslh.vertices(:,3),1:size(sslh.vertices,1), ...
                  fslh.vertices(:,1),fslh.vertices(:,2),fslh.vertices(:,3),'nearest');
tfunSSFSlh = @(x) double(flatten(x(tempix)));
tempix = griddata(ssrh.vertices(:,1),ssrh.vertices(:,2),ssrh.vertices(:,3),size(sslh.vertices,1)+(1:size(ssrh.vertices,1)), ...
                  fsrh.vertices(:,1),fsrh.vertices(:,2),fsrh.vertices(:,3),'nearest');
tfunSSFSrh = @(x) double(flatten(x(tempix)));
