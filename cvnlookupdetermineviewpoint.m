%%% NOTE: this is a set of notes and still a work in progress.

% show the fsaverage surface
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
%set(h,'FaceColor',[1 .5 .5]);
lighting gouraud
camlight;
axis equal;

% rotate a little manually.
[az,el]=view
view(180,90);
    %az = 95; el = -60;
    % az = -120; el = -5
    % az =  120; el = -5
view(-35,40);  %lh
view( 35,40);  %rh

% check parameters:
view(-120,-5);  %lh
view( 120,-5);  %rh
view(180,90);  % rh

% define
oo = [az el 270];  % value on 3 means CW
oo = [-120 -5 0];
oo = [ 120 -5 0];
oo = [0 90 0];
oo = [0 90 0];
oo = [-180 0 0];
oo = [-180 0 0];
oo = [-35 40 0];
oo = [ 35 40 0];

% check the 3rd parameter (rotation)
figure(1); view(oo(1),oo(2));
%camlight;
figurewrite('test',[],[],pwd,1); 
im = imread('test.png');
figure(2); setfigurepos([100 100 900 900]); imagesc(imrotate(im,-oo(3)));

% modify code (cvn functions) accordingly.

%%%% other junk

% some tests.
cvnlookup('EMILY001', 12,[],[],[],10,[],[],{'savelookup',false});   % savelookup false
cvnlookup('fsaverage', 14,[],[],[],10);
cvnlookup('fsaverage', 15,[],[],[],10);

for p=1:10
  cvnlookup(sprintf('EMILY%03d',p), 12,[],[],[],10,[],[],{'savelookup',false});   % savelookup
  imwrite(rgbimg,sprintf('~/Dropbox/pitchprf/subj%03d.png',p));
end
