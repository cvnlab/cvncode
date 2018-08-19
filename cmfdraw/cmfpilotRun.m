function [rgbimg,L,mappedvals] = cmfpilotRun(todo,type,roi)
%Inputs
%type: Map type
%type = 1 Polar Angle
if(type == 1)
    rng = [0 360];
    cmap = cmfanglecmap;
    ctype = 1;
    thresh = [];
end
%type = 2 Eccentricity
if(type == 2)
    rng = [0 12];
    cmap = cmfecccmap;
    ctype = 0;
    thresh = [];
end
if(type == 3)
    rng = [0 360];
    cmap = cmfanglecmapRH;
    ctype = 1;
    type = 1;
    thresh = [];
end
if(type ==4)
    rng = [0 360];
    cmap = cmfanglecmap;
    ctype = 1;
    type =1;
    thresh = [500];
end

% LOAD DATA
% load results
a1 = load('/stone/ext4/kendrick/HCP7TFIXED/prfresults.mat');

% WHICH SUBJECT AM I DOING?

% which subject to do
%todo = 21;

%GENERATE THE MAP

% get subject list
a2 = matchfiles('/stone/ext4/kendrick/HCP7TFIXED/??????');
subjects = cellfun(@(x) stripfile(x,1),a2,'UniformOutput',0)';
subjects = subjects(1:end-3);

% get Kastner ROIs
rois = { ...
  vflatten(cvnloadmgz('/stone/ext4/kendrick/HCP7TFIXED/lr.wang91k.mgz')) ...
};

% define
subjectid = subjects{todo};
surfsuffix = 'orig';
surftype = 'sphere';
viewname = 'occip';
imageres = 1000;
xyextent = [1 1];
hemis = {'lh' 'rh'};
hemitexts = {'L' 'R'};

% calc
fsdir = sprintf('%s/%s',cvnpath('freesurfer'),subjectid);
surfdir = sprintf('/home/stone-ext4/kendrick/HCP7TFIXED/%s/surf',subjectid);   % no longer use 'gifti' version!

% get mapping
indexingvector = [vflatten(cvnloadmgz(sprintf('%s/lh.cifti_indices_nearest.mgz',surfdir))); ...
                  vflatten(cvnloadmgz(sprintf('%s/rh.cifti_indices_nearest.mgz',surfdir)))];
indexingvectorbad = find(indexingvector==-1);  % where are NaNs?
indexingvector = indexingvector + 1;           % convert 0-based to 1-based
indexingvector(indexingvectorbad) = 1;         % put in dummy value for NaN locations

% put in native data
V = cvnreadsurfacemetric([],{'lh' 'rh'},'curv','','orig','surfdir',surfdir);   %V.data = V.data<0;
V.data = a1.allresults(indexingvector,type,todo,1);     % get angle (full fit) into native subject space
V.data(indexingvectorbad) = NaN;                     % set bad locations to NaN

% define some parameters
%cmap = hsv(256);
%rng = [0 360];

%circulartpe 1 for circular
%f = cmfanglecmap;

%thresh = [];
alpha = 1;

% transfer ROIs to this subject

roisTOUSE = {};
if (roi == 1)
    for z=1:length(rois)
        if z==1
            for zz=1:6  % this is V1-V3
                temp = ismember(rois{z},zz);
                temp = temp(indexingvector);
                temp(indexingvectorbad) = 0;
                roisTOUSE{end+1} = vflatten(temp);
            end
        end
    end
end

% define viewpoint
viewpt = cvnlookupviewpoint(subjectid,hemis,viewname,surftype);
if isequal(surftype,'sphere') && isequal(viewname,'occip')
  viewpt = {[10 -30 0] [-10 -30 0]};  % just use this instead of the default for sphere-occip
end
% %test colormap
% cmap = cmfanglecmap;
% temp = cmap(1:90,:);
% temp = flip(temp);
% cmap(91:180,:) = temp;
% temp = cmap(271:360,:);
% temp = flip(temp);
% cmap(181:270,:) = temp;
    

% calc some lookup stuff
L = [];
[mappedvals,L,rgbimg] = cvnlookupimages(subjectid,V,hemis,viewpt,L, ...
  'xyextent',xyextent,'imageres',imageres,'text',hemitexts,'rgbnan',0.5, ...
  'surftype',surftype,'surfsuffix',surfsuffix, ...
  'colormap',cmap,'clim',rng,'circulartype',ctype, ...
  'threshold',thresh,'overlayalpha',alpha, ...
  'surfdir',surfdir,'roimask',roisTOUSE,'roicolor','w');

        
        


