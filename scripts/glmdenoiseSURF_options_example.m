%This is an example of what you should add before calling GLMdenoise on
%surface data, so that it will use cvnlookupimages to save figures properly

subject='C0041';
[surfL, surfR]=cvnreadsurface(subject,{'lh','rh'},'layerA1','DENSETRUNCpt');
numlh=size(surfL.vertices,1);
numrh=size(surfR.vertices,1);

opt=struct();
opt.numforhrf=500;

viewpt=[10 -40 180];
v=zeros(numlh,1);
[~,lookupL]=cvnlookupimages(subject,v,'lh',viewpt,[],'xyextent',[1 1]);

viewpt=[-10 -40 180];
v=zeros(numrh,1);
[~,lookupR]=cvnlookupimages(subject,v,'rh',viewpt,[],'xyextent',[1 1]);

cathemis=@(v)spherelookup_vert2image(struct('numlh',numlh,'numrh',numrh,'data',v(:,1)),{lookupR,lookupL},nan);
    
opt.drawfunction = @(vals,clim)cathemis(makeimagestack(vals(:),clim));

%now call GLMdenoisedata with 'opt'
