% This script can be used to help determine new viewpoints to be 
% used in cvnlookup.m and cvndefinerois.m.

% load surface
surf = cvnreadsurface('fsaverage','lh','inflated','orig');
curv = cvnreadsurfacemetric('fsaverage','lh','curv',[],'orig');
surf = cvnreadsurface('fsaverage','rh','inflated','orig');
curv = cvnreadsurfacemetric('fsaverage','rh','curv',[],'orig');

% render it
figure; setfigurepos([100 100 900 900]);
h = patch(surf);
set(h,'EdgeColor','none');
%%set(h,'FaceColor',[1 .5 .5]);
set(h,'FaceVertexCData',double(curv<0));
set(h,'FaceColor','interp');
lighting gouraud;
camlight;
axis equal;

% rotate manually

% get the current view (azimuth, elevation)
[az,el] = view

% explicitly set the view
view(-35,40);  % lh
view( 35,40);  % rh

% define 3-element vector with [A E R]
% where A is azimuth
%       E is elevation
%       R is image rotation (positive means clockwise)
oo = [-35 40 0];  % lh
oo = [ 35 40 0];  % rh

% after you carefully decide on your parameters,
% the code (cvn functions) need to be modified
% accordingly.
%
% the relevant functions are:
%   cvnlookup.m, cvnlookupviewpoint.m, cvndefinerois.m
