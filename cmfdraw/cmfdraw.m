function varargout = cmfdraw(varargin)
% CMFDRAW MATLAB code for cmfdraw.fig
%      CMFDRAW, by itself, creates a new CMFDRAW or raises the existing
%      singleton*.
%
%      H = CMFDRAW returns the handle to a new CMFDRAW or the handle to
%      the existing singleton*.
%
%      CMFDRAW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CMFDRAW.M with the given input arguments.
%
%      CMFDRAW('Property','Value',...) creates a new CMFDRAW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cmfdraw_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cmfdraw_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cmfdraw

% Last Modified by GUIDE v2.5 05-Aug-2018 12:35:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cmfdraw_OpeningFcn, ...
                   'gui_OutputFcn',  @cmfdraw_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before cmfdraw is made visible.
function cmfdraw_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cmfdraw (see VARARGIN)
global subjects userName

[status,userName] = unix('whoami');
userName = userName(1:end-1);
userName = getpref('ROIGUI','user',userName);
subjectLoader = load(strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/',userName,'/subjectsUnique.mat'));
subjects = subjectLoader.subjectsUnique;
%Assert directories exist
%Assert user exists


% Choose default command line output for cmfdraw
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes cmfdraw wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = cmfdraw_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in newLineButton.
function newLineButton_Callback(hObject, eventdata, handles)
% hObject    handle to newLineButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo L rgbimg hmapfig swapFlag cmap cmapRH pathResults rgbimgPA rgbimgECC curvatureOnly

%Check if line is selected
lines = get(handles.newLineSelect,'String');
value = get(handles.newLineSelect,'Value');
currentLine = strtrim(lines(value,:));
if (isempty(hmapfig))
    fprintf('Error: No figure number\n')
    return
end
if (strcmp(currentLine,'Select a Line'))
    fprintf('Error: No line selected\n')
    return
end
dataLoader = load(pathResults);
labels = dataLoader.labels;
for i = 1:24
    if(strcmp(currentLine,labels{i}))
        lineIndex = i;
    end
end


figure(hmapfig)

%Disable kastner for drawing
mapType = get(handles.mapList,'Value');
switch mapType
    case 1
        rgbimgTemp = rgbimgPA;
    case 2
        rgbimgTemp = rgbimgECC;
    case 3
        rgbimgTemp = curvatureOnly;
end

% ask the user to draw a line (green=start, red=end)
sxypoints=[]; % Note: can provide initial xypoints as Nx2 matrix of pixel coords
[sxypoints, sxyline, sxylineCell, pixelMask,sxyNC]=cmfroiline(hmapfig,rgbimg,sxypoints,[],todo,lineIndex);
if(size(sxypoints,1)<2)
    fprintf('Error: Not enough points selected\n')
    [rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,1);
    return
end
svertidx=spherelookup_imagexy2vertidx(sxyline,L);

% remove repeating vertices
uidx=[true; svertidx(2:end)~=svertidx(1:end-1)];
svertidx=double(svertidx(uidx));
if(size(sxypoints,1)>2)
    [~,pidx]=min(distance(sxypoints.',sxyline(uidx,:).'),[],2);
    svertidx_segments=svertidx(pidx);
else
    svertidx_segments=svertidx([1 end]);
end

%Export data
dataLoader = load(pathResults);
    xypoints = dataLoader.xypoints;
    xyline = dataLoader.xyline;
    vertidx = dataLoader.vertidx;
    vertidx_segments = dataLoader.vertidx_segments;
    xyNC = dataLoader.xyNC;
    xylineCell = dataLoader.xylineCell;

    xypoints{lineIndex} = sxypoints;
    xyline{lineIndex} = sxyline;
    vertidx{lineIndex} = svertidx;
    vertidx_segments{lineIndex} = svertidx_segments;
    xyNC{lineIndex} = sxyNC;
    xylineCell{lineIndex} = sxylineCell;
pathname = strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/lineData/',num2str(todo),'/');
file2save = pathResults;
save(file2save, 'xypoints','xyline','vertidx','vertidx_segments','xyNC','xylineCell','-append')

labels = dataLoader.labels;
labelsTodo = char('Select a Line');
for i = 1:24
    if (isempty(xyline{i}))
        labelsTodo = char(labelsTodo,labels{i});
    end
end
set(handles.newLineSelect,'String',labelsTodo,'Value',1)

[rgbimg,hmapfig] = cmfupdateIMG(todo, rgbimg, hmapfig,swapFlag,cmap,cmapRH,1);



% --- Executes on button press in editLineButton.
function editLineButton_Callback(hObject, eventdata, handles)
% hObject    handle to editLineButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo rgbimg hmapfig currentLine swapFlag cmap cmapRH pathResults L rgbimgPA rgbimgECC curvatureOnly hlines

%Check valid line
currentLine = get(handles.currentLineText, 'String');
if (strcmp(currentLine,'None') || strcmp(currentLine,'Current Line'))
    fprintf('Error: No line selected\n');
    return
end

%Load Results.mat and assign current line
figure(hmapfig)
dataLoader = load(pathResults);
labels = dataLoader.labels;
for i = 1:24
    if(strcmp(currentLine,labels{i}))
        lineIndex = i;
    end
end
xypoints = dataLoader.xypoints{lineIndex};
sxyNC = dataLoader.xyNC{lineIndex};

%Disable kastner for drawing
if(get(handles.kastnerCheck,'Value') == 1)
    mapType = get(handles.mapList,'Value');
    switch mapType
        case 1
            rgbimgTemp = rgbimgPA;
        case 2
            rgbimgTemp = rgbimgECC;
        case 3
            rgbimgTemp = curvatureOnly;
    end
    [rgbimg,hmapfig,hlines] = cmfupdateIMG(todo,rgbimgTemp,hmapfig,swapFlag,cmap,cmapRH,0,lineIndex);
    set(handles.kastnerCheck,'Value',0);
end
for ii = 1:length(hlines)
    if(hlines(ii) ~= 0)
        delete(hlines(ii))
    end
end
%Draw
[sxypoints, sxyline, sxylineCell, pixelMask,sxyNC]=cmfroiline(hmapfig,rgbimg,xypoints,sxyNC,todo,lineIndex);
if(size(sxypoints,1)<2)
    fprintf('Error: Not enough points selected\n')
    [rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,1);    
    return
end
%Confirm intent to change
flag = questdlg('Keep changes?','Confirm Changes','Yes continue','No cancel','No cancel');
if ~(strcmp(flag,'Yes continue'))
    [rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,1);    
    return
end

pathname = strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/lineData/',num2str(todo),'/');
file2save = pathResults;


svertidx=spherelookup_imagexy2vertidx(sxyline,L);

% remove repeating vertices
uidx=[true; svertidx(2:end)~=svertidx(1:end-1)];
svertidx=double(svertidx(uidx));
if(size(sxypoints,1)>2)
    [~,pidx]=min(distance(sxypoints.',sxyline(uidx,:).'),[],2);
    svertidx_segments=svertidx(pidx);
else
    svertidx_segments=svertidx([1 end]);
end

%Export data
    xypoints = dataLoader.xypoints;
    xyline = dataLoader.xyline;
    vertidx = dataLoader.vertidx;
    vertidx_segments = dataLoader.vertidx_segments;
    xyNC = dataLoader.xyNC;
    xylineCell = dataLoader.xylineCell;
    
    xypoints{lineIndex} = sxypoints;
    xyline{lineIndex} = sxyline;
    xylineCell{lineIndex} = sxylineCell;
    vertidx{lineIndex} = svertidx;
    vertidx_segments{lineIndex} = svertidx_segments;
    xyNC{lineIndex} = sxyNC;
pathname = strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/lineData/',num2str(todo),'/');
file2save = pathResults;
save(file2save, 'xypoints','xyline','vertidx','vertidx_segments','xyNC','xylineCell','-append')
[rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,1);

figure(hmapfig);
set(handles.currentLineText,'String','None');

% --- Executes on button press in launchButton.
function launchButton_Callback(hObject, eventdata, handles)
% hObject    handle to launchButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo L rgbimg hmapfig swapFlag rgbimgPA rgbimgECC currentLine cmap cmapRH mappedvalsPA mappedvalsECC curvimg subjects curvatureOnly rgbimgPA_Atlas rgbimgECC_Atlas curvatureOnly_Atlas subNum userName pathResults

subNum = str2double(get(handles.subjectNumber, 'String'));
if (subNum < 1 || subNum > 181 || isnan(subNum))
    fprintf('Error: Invliad subject number\n');
    fprintf(strcat('You entered:', get(handles.subjectNumber, 'String'),'\n'));
    return
end

fprintf(strcat('\nLaunching Subject: ', num2str(subNum),'\n'));
todo = str2double(subjects{subNum});

pathResults = strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/',userName,'/',num2str(todo),'/results.mat');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              Main Program                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Load in rgbimg and L
images = load(strcat('/home/stone-ext4/kendrick/HCP7TFIXED/manualdefinition/lineData/',num2str(todo),'/cache.mat'));
rgbimgPA = images.rgbimgPA;
rgbimgECC = images.rgbimgECC;
L = images.L;
mappedvalsPA = images.mappedvalsPA;
mappedvalsECC = images.mappedvalsECC;
curvimg = images.curvimg;
curvatureOnly = images.curvatureOnly;
rgbimgPA_Atlas = images.rgbimgPA_Atlas;
rgbimgECC_Atlas = images.rgbimgECC_Atlas;
curvatureOnly_Atlas = images.curvatureOnly_Atlas;

rgbimg = rgbimgPA;
cmap = cmfanglecmap;
cmapRH = cmfanglecmapRH;
[rgbimg, hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,-1,cmap,cmapRH,1);

%Set text boxes
set(handles.currentSubjectText, 'String', strcat(num2str(subNum),':',num2str(todo)));
swapFlag = -1;
currentLine = 0;
set(handles.currentLineText, 'String', 'None');
set(handles.kastnerCheck,'Value',0);
%Disable Kastner for intervals of 6
if (mod(subNum,6)  == 0)
    set(handles.kastnerCheck,'Enable','off')
else
    set(handles.kastnerCheck,'Enable','on')
end
dataLoader = load(pathResults);
labels = dataLoader.labels;
labelsTodo = char('Select a Line');
for i = 1:24
    if (isempty(dataLoader.xyline{i}))
        labelsTodo = char(labelsTodo,labels{i});
    end
end
set(handles.newLineSelect,'String',labelsTodo,'Value',1)

maps = char('Polar Angle','Eccentricity','Curvature');
set(handles.mapList,'String',maps,'Value',1);
set(handles.radiusEdit,'String',num2str(25));

completed = dataLoader.completed;
ratingsLeft = dataLoader.ratingsLeft;
ratingsRight = dataLoader.ratingsRight;
set(handles.doneCheck,'Value',completed);
set(handles.rateRight,'Value',ratingsRight);
set(handles.rateLeft,'Value',ratingsLeft);

set(handles.commentText,'String',dataLoader.currComment);
set(handles.undoButton,'visible','off');
return


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             End Main Program                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function subjectNumber_Callback(hObject, eventdata, handles)
% hObject    handle to subjectNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subjectNumber as text
%        str2double(get(hObject,'String')) returns contents of subjectNumber as a double


% --- Executes during object creation, after setting all properties.
function subjectNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subjectNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in deleteButton.
function deleteButton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo rgbimg hmapfig rgbimgPA rgbimgECC swapFlag cmap cmapRH pathResults

%Check valid line
currentLine = get(handles.currentLineText, 'String');
if (strcmp(currentLine,'None') || strcmp(currentLine,'Current Line'))
    fprintf('Error: No line selected\n');
    return
end

%Confirm intent to delete
flag = questdlg('Delete this line?','Confirm Deletion','Yes continue','No cancel','No cancel');
if ~strcmp(flag,'Yes continue')
        return
end

dataLoader = load(pathResults);
labels = dataLoader.labels;
currentLine = currentLine(1:end);
for i = 1:24
    if(strcmp(currentLine,labels{i}))
        lineIndex = i;
    end
end

%Delete current line data
xypoints = dataLoader.xypoints;
xyline = dataLoader.xyline;
vertidx = dataLoader.vertidx;
vertidx_segments = dataLoader.vertidx_segments;
xyNC = dataLoader.xyNC;

xypoints{lineIndex} = [];
xyline{lineIndex} = [];
vertidx{lineIndex} = [];
vertidx_segments{lineIndex} = [];
xyNC{lineIndex} = [];
file2save = pathResults;
save(file2save,'xypoints','xyline','vertidx','vertidx_segments','-append');

%Reset new line choice
set(handles.currentLineText,'String','None');

dataLoader = load(pathResults);
labels = dataLoader.labels;
labelsTodo = char('Select a Line');
for i = 1:24
    if (isempty(dataLoader.xyline{i}))
        labelsTodo = char(labelsTodo,labels{i});
    end
end
set(handles.newLineSelect,'String',labelsTodo,'Value',1)
[rgbimg, hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0);


% --- Executes on button press in colorRotButton.
function colorRotButton_Callback(hObject, eventdata, handles)
% hObject    handle to colorRotButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo swapFlag rgbimg hmapfig mappedvalsPA mappedvalsECC cmap cmapRH

fprintf('Start');
%Check if rotation increment is valid
rotI = str2double(get(handles.rotationEdit,'String'));
if (isnan(rotI) || rotI <= 0 || floor(rotI) ~= rotI)
    fprintf('Error: Not a positive integer\n')
    fprintf(strcat('You entered:',get(handles.rotationEdit,'String'),'\n'));
    return
end

%Swap flag is reverse of SwapMap function because flag is changed at end
%Main rotation

switch swapFlag
    case -1
        mappedvals = mappedvalsPA;
        clim = [0 360];
        cmapRH = circshift(cmapRH,-rotI);
    case 1
        mappedvals = mappedvalsECC;
        clim = [0 12];
    case 0 
        return
end
cmap = circshift(cmap,rotI);

%Apply to mappedvals
rgbimg = mat2rgb(mappedvals,'cmap',cmap,'clim',clim,'background','curv','bg_cmap',gray(64),'bg_clim',[-1 2],'rgbnan',0.5);
if(swapFlag == -1)
    rgbimg2 = mat2rgb(mappedvals,'cmap',cmapRH,'clim',clim,'background','curv','bg_cmap',gray(64),'bg_clim',[-1 2],'rgbnan',0.5);
    rgbimg = horzcat(rgbimg(:,1:1001,:),rgbimg2(:,1002:2000,:));
end
%Border line
for i = 1:size(rgbimg,1)
    rgbimg(i,1001,:) = 0;
    rgbimg(i,1002,:) = 0;
end

[rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0);
fprintf(strcat('Color rotated by:',get(handles.rotationEdit,'String'),'\n'));

% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo swapFlag rgbimg hmapfig mappedvalsPA mappedvalsECC cmap curvimg cmapRH

%Check thresh is valid
threshLowTemp = str2double(get(handles.threshEditLow, 'String'));
if (isnan(threshLowTemp) || threshLowTemp < 0)
    fprintf('Error: Thresh must be between greater than or equal to zero\n');
    fprintf(strcat('You entered thresh:',get(handles.threshEditLow,'String'),'\n'));
    return
end
threshLow = threshLowTemp;

threshHighTemp = str2double(get(handles.threshEditHigh, 'String'));
if (isnan(threshHighTemp) || threshHighTemp < 0)
    fprintf('Error: Thresh must be greater than or equal to zero\n');
    fprintf(strcat('You entered thresh:',get(handles.threshEditHigh,'String'),'\n'));
    return
end
threshHigh = threshHighTemp;

if (threshHigh < threshLow)
    fprintf('Error: Thresh mix match\n');
    return
end
threshRange = [threshLow threshHigh];
%Swap flag is reverse of SwapMap function because flag is changed at end
switch swapFlag
    case 1
        mappedvals = mappedvalsECC;
        clim = [0 12];
    case -1
        mappedvals = mappedvalsPA;
        clim = [0 360];
    case 0
        return
        
end

%Apply to mappedvals
rgbimg = mat2rgb(mappedvals,'cmap',cmap,'clim',clim,'overlayrange',threshRange,'background',curvimg,'bg_cmap',gray(64),'bg_clim',[-1 2],'rgbnan',0.5);
if(swapFlag == -1)
 rgbimg2 = mat2rgb(mappedvals,'cmap',cmapRH,'clim',clim,'overlayrange',threshRange,'background',curvimg,'bg_cmap',gray(64),'bg_clim',[-1 2],'rgbnan',0.5);
 rgbimg = horzcat(rgbimg(:,1:1001,:),rgbimg2(:,1002:2000,:));  
end


%Border line
for i = 1:size(rgbimg,1)
    rgbimg(i,1001,:) = 0;
    rgbimg(i,1002,:) = 0;
end
[rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0);



function threshEditLow_Callback(hObject, eventdata, handles)
% hObject    handle to threshEditLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshEditLow as text
%        str2double(get(hObject,'String')) returns contents of threshEditLow as a double
global swapFlag
value = str2double(get(handles.threshEditLow,'String'));
if(swapFlag == -1)
    if(isnan(value) || value<0 || value > 360)
        fprintf('Error: Please enter a valid threshhold value\n')
        return       
    end
    set(handles.lowerSlider,'Value',value/360);
end
if(swapFlag == 1)
    if(isnan(value) || value<0 || value > 10)
        fprintf('Error: Please enter a valid threshhold value\n')        
    end
    set(handles.lowerSlider,'Value',value/10);
end

% --- Executes during object creation, after setting all properties.
function threshEditLow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshEditLow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectButton.
function selectButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo rgbimg hmapfig currentLine swapFlag cmap cmapRH pathResults hlines

%Get lineIndex and check if there are lines
loader = load(pathResults);
labels = loader.labels;
count = 0;

for i = 1:24
    if(~isempty(loader.xyline{i}))
        count = count+1;
    end
end

if (count == 0)
    fprintf('Error: There are no lines to select\n')
    return
end


%Get click position
figure(hmapfig);
[y,x] = ginput(1);

%Get points of all lines
mins(1:24) = 1000;
for i = 1:24
    if (~isempty(loader.xyline{i}))
        xyline = loader.xyline{i};
        for j = 1:length(xyline);
            distance(j) = sqrt(((y - xyline(j,1))^2) + ((x - xyline(j,2))^2));
        end
        mins(i) = min(distance);
    end
end
[minValue, currentLineIndex] = min(mins);
fprintf(num2str(minValue));
currentLine = cell2str(labels(currentLineIndex));
currentLine = currentLine(4:end-3);
set(handles.currentLineText, 'String', currentLine);

[rgbimg,hmapfig, hlines] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0,currentLineIndex);

% --- Executes on selection change in newLineSelect.
function newLineSelect_Callback(hObject, eventdata, handles)
% hObject    handle to newLineSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns newLineSelect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from newLineSelect


% --- Executes during object creation, after setting all properties.
function newLineSelect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to newLineSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in rotateColorDown.
function rotateColorDown_Callback(hObject, eventdata, handles)
% hObject    handle to rotateColorDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo L swapFlag rgbimg hmapfig mappedvalsPA mappedvalsECC cmap cmapRH

fprintf('Start');
%Check if rotation increment is valid
rotI = str2double(get(handles.rotationEdit,'String'));
if (isnan(rotI) || rotI <= 0 || floor(rotI) ~= rotI)
    fprintf('Error: Not a positive integer\n')
    fprintf(strcat('You entered:',get(handles.rotationEdit,'String'),'\n'));
    return
end
rotI = -rotI;
%Swap flag is reverse of SwapMap function because flag is changed at end
%Main rotation
cmap = circshift(cmap,rotI);
switch swapFlag
    case -1
    mappedvals = mappedvalsPA;
    clim = [0 360];
    cmapRH = circshift(cmapRH,-rotI);
    case 1
    mappedvals = mappedvalsECC;
    clim = [0 12];
    case 0
        return
end

%Apply to mappedvals
rgbimg = mat2rgb(mappedvals,'cmap',cmap,'clim',clim,'background','curv','bg_cmap',gray(64),'bg_clim',[-1 2],'rgbnan',0.5);
if(swapFlag == -1)
    rgbimg2 = mat2rgb(mappedvals,'cmap',cmapRH,'clim',clim,'background','curv','bg_cmap',gray(64),'bg_clim',[-1 2],'rgbnan',0.5);
    rgbimg = horzcat(rgbimg(:,1:1001,:),rgbimg2(:,1002:2000,:));
end
%Border line
for i = 1:size(rgbimg,1)
    rgbimg(i,1001,:) = 0;
    rgbimg(i,1002,:) = 0;
end

[rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0);
fprintf(strcat('Color rotated by:-',get(handles.rotationEdit,'String'),'\n'));



function rotationEdit_Callback(hObject, eventdata, handles)
% hObject    handle to rotationEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rotationEdit as text
%        str2double(get(hObject,'String')) returns contents of rotationEdit as a double


% --- Executes during object creation, after setting all properties.
function rotationEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rotationEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function threshEditHigh_Callback(hObject, eventdata, handles)
% hObject    handle to threshEditHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshEditHigh as text
%        str2double(get(hObject,'String')) returns contents of threshEditHigh as a double
global swapFlag
value = str2double(get(handles.threshEditHigh,'String'));
if(swapFlag == -1)
    if(isnan(value) || value<0 || value > 360)
        fprintf('Error: Please enter a valid threshhold value\n')
        return       
    end
    set(handles.upperSlider,'Value',value/360);
end
if(swapFlag == 1)
    if(isnan(value) || value<0 || value > 10)
        fprintf('Error: Please enter a valid threshhold value\n')        
    end
    set(handles.upperSlider,'Value',value/10);
end

% --- Executes during object creation, after setting all properties.
function threshEditHigh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshEditHigh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function upperSlider_Callback(hObject, eventdata, handles)
% hObject    handle to upperSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global swapFlag
if (swapFlag ~= 1 && swapFlag ~= -1)
    fprintf('Error: No swap flag, please re-launch to use sliders\n');
    return
end

if (swapFlag == 1)
    sliderValueRaw = get(handles.upperSlider,'Value');
    sliderValue = sliderValueRaw * 10;
end
if (swapFlag == -1)
    sliderValueRaw = get(handles.upperSlider,'Value');
    sliderValue = sliderValueRaw * 360;
end
highThresh = num2str(sliderValue);
set(handles.threshEditHigh,'String',highThresh)


% --- Executes during object creation, after setting all properties.
function upperSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to upperSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function lowerSlider_Callback(hObject, eventdata, handles)
% hObject    handle to lowerSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global swapFlag
if (swapFlag ~= 1 && swapFlag ~= -1)
    fprintf('Error: No swap flag, please re-launch to use sliders\n');
    return
end

if (swapFlag == 1)
    sliderValueRaw = get(handles.lowerSlider,'Value');
    sliderValue = sliderValueRaw * 10;
end
if (swapFlag == -1)
    sliderValueRaw = get(handles.lowerSlider,'Value');
    sliderValue = sliderValueRaw * 360;
end
lowThresh = num2str(sliderValue);
set(handles.threshEditLow,'String',lowThresh)

% --- Executes during object creation, after setting all properties.
function lowerSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lowerSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in resetThreshButton.
function resetThreshButton_Callback(hObject, eventdata, handles)
% hObject    handle to resetThreshButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global todo swapFlag rgbimg hmapfig rgbimgPA rgbimgECC cmap cmapRH rgbimgPA_Atlas rgbimgECC_Atlas
kflag = get(handles.kastnerCheck,'Value');

set(handles.lowerSlider,'Value',0)
set(handles.upperSlider,'Value',1)
if(swapFlag == -1)
    set(handles.threshEditLow,'String','0')
    set(handles.threshEditHigh,'String','360')
    if(kflag)
        rgbimg = rgbimgPA_Atlas;
    else rgbimg = rgbimgPA;
    end
end
if(swapFlag == 1)
    set(handles.threshEditLow,'String','0')
    set(handles.threshEditHigh,'String','12')
    if(kflag)
        rgbimg = rgbimgECC_Atlas;
    else rgbimg = rgbimgECC;
    end
end
[rgbimg, hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0);



% --- Executes on button press in centerThreshButton.
function centerThreshButton_Callback(hObject, eventdata, handles)
% hObject    handle to centerThreshButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global todo swapFlag rgbimg hmapfig mappedvalsPA mappedvalsECC cmap cmapRH curvimg

centerValue = str2double(get(handles.centerThreshEdit,'String'));
radius = str2double(get(handles.radiusEdit,'String'));
if(swapFlag == -1)
    if(isnan(centerValue) || centerValue<0 || centerValue > 360)
        fprintf('Error: Please enter a valid threshhold value\n')
        return       
    end
    if(centerValue < 25 || centerValue > 335)
        set(handles.threshEditLow,'String',num2str(0));
        set(handles.threshEditHigh,'String',num2str(25));
        set(handles.lowerSlider,'Value',0);
        set(handles.upperSlider,'Value',(25/360));
        pushbutton8_Callback(handles.pushbutton8,eventdata,handles);
    else
        
        set(handles.threshEditLow,'String',num2str(centerValue-radius));
        set(handles.threshEditHigh,'String',num2str(centerValue+radius));
        set(handles.lowerSlider,'Value',(centerValue-radius)/360);
        set(handles.upperSlider,'Value',(centerValue+radius)/360);
        pushbutton8_Callback(handles.pushbutton8,eventdata,handles);
    end
end
if(swapFlag == 1)
    if(isnan(centerValue) || centerValue<0.5 || centerValue > 9.5)
        fprintf('Error: Please enter a valid threshhold value\n')
        return
    end
        set(handles.threshEditLow,'String',num2str(centerValue-radius));
        set(handles.threshEditHigh,'String',num2str(centerValue+radius));
        set(handles.lowerSlider,'Value',(centerValue-radius)/10);
        set(handles.upperSlider,'Value',(centerValue+radius)/10);
        pushbutton8_Callback(handles.pushbutton8,eventdata,handles);
% % %         %Apply to mappedvals
% % %         clim = [(centerValue-1) (centerValue+1)];
% % %         tempCmap = hsv(256);
% % %         tempCmap = tempCmap(1:84,:);
% % %         threshRange = [(centerValue-0.2) (centerValue+0.2)];
% % %         rgbimg = mat2rgb(mappedvalsECC,'cmap',tempCmap,'clim',clim,'overlayrange',threshRange,'background',curvimg,'bg_cmap',gray(64),'bg_clim',[-1 2],'rgbnan',0.5);
% % %         %Border line
% % %         for i = 1:size(rgbimg,1)
% % %             rgbimg(i,1001,:) = 0;
% % %             rgbimg(i,1002,:) = 0;
% % %         end
% % %         [rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,0);
end


function centerThreshEdit_Callback(hObject, eventdata, handles)
% hObject    handle to centerThreshEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of centerThreshEdit as text
%        str2double(get(hObject,'String')) returns contents of centerThreshEdit as a double


% --- Executes during object creation, after setting all properties.
function centerThreshEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to centerThreshEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in mapList.
function mapList_Callback(hObject, eventdata, handles)
% hObject    handle to mapList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns mapList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mapList
global todo rgbimgPA rgbimgECC hmapfig swapFlag cmap cmapRH rgbimg curvatureOnly rgbimgPA_Atlas rgbimgECC_Atlas curvatureOnly_Atlas
list = cellstr(get(handles.mapList,'String'));
map = strtrim(list{get(handles.mapList,'Value')});
kflag = get(handles.kastnerCheck,'Value');
switch map
    case 'Polar Angle'
        if(kflag)
            rgbimg = rgbimgPA_Atlas;
        else rgbimg = rgbimgPA;
        end
        swapFlag = -1;
        set(handles.radiusEdit,'String',num2str(25));
        cmap = cmfanglecmap;
    case 'Eccentricity'
        if(kflag)
            rgbimg = rgbimgECC_Atlas;
        else rgbimg = rgbimgECC;
        end
        swapFlag = 1;
        set(handles.radiusEdit,'String',num2str(0.2));
        cmap = cmfecccmap;
    case 'Curvature'
        if(kflag)
            rgbimg = curvatureOnly_Atlas;
        else rgbimg = curvatureOnly;
        end
        swapFlag = 0;
        set(handles.radiusEdit,'String','N/A');
end
[rgbimg, hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0);
    

% --- Executes during object creation, after setting all properties.
function mapList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mapList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in kastnerCheck.
function kastnerCheck_Callback(hObject, eventdata, handles)
% hObject    handle to kastnerCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of kastnerCheck
global rgbimg rgbimgPA rgbimgECC curvatureOnly swapFlag rgbimgPA_Atlas rgbimgECC_Atlas curvatureOnly_Atlas todo hmapfig cmap cmapRH
kFlag = get(handles.kastnerCheck,'Value');

switch swapFlag
    case -1
        if(kFlag)
            rgbimg = rgbimgPA_Atlas;
        else rgbimg = rgbimgPA;
        end
    case 0
        if(kFlag)
            rgbimg = curvatureOnly_Atlas;
        else rgbimg = curvatureOnly;
        end
    case 1
        if(kFlag)
            rgbimg = rgbimgECC_Atlas;
        else rgbimg = rgbimgECC;
        end
end
[rgbimg,hmapfig] = cmfupdateIMG(todo,rgbimg,hmapfig,swapFlag,cmap,cmapRH,0);



function radiusEdit_Callback(hObject, eventdata, handles)
% hObject    handle to radiusEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radiusEdit as text
%        str2double(get(hObject,'String')) returns contents of radiusEdit as a double


% --- Executes during object creation, after setting all properties.
function radiusEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radiusEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in doneCheck.
function doneCheck_Callback(hObject, eventdata, handles)
% hObject    handle to doneCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of doneCheck
global pathResults
loader = load(pathResults);
if (get(handles.doneCheck,'Value') == 1)
vertidx = loader.vertidx;
for i = 1:length(vertidx)
    if isempty(vertidx{i})
        fprintf('Error: Please draw all lines before marking subject as complete\n');
        set(handles.doneCheck,'Value',0);
        return
    end
end
end
doneFlag = get(handles.doneCheck,'Value');
completed = loader.completed;
ratingsLeft = loader.ratingsLeft;
ratingsRight = loader.ratingsRight;
if (ratingsLeft ==1 || ratingsRight == 1)
    fprintf('Error: Please rate quality of data before marking as complete\n');
    set(handles.doneCheck,'Value',0);
    return
end
completed = doneFlag;
file2save = pathResults;
save(file2save,'completed','-append')

% --- Executes on selection change in rateRight.
function rateRight_Callback(hObject, eventdata, handles)
% hObject    handle to rateRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns rateRight contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rateRight
global pathResults
ratingsRight = get(handles.rateRight,'Value');
file2save = pathResults;
save(file2save,'ratingsRight','-append')

% --- Executes during object creation, after setting all properties.
function rateRight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rateRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in nextButton.
function nextButton_Callback(hObject, eventdata, handles)
% hObject    handle to nextButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global subNum

if (subNum <=180)
    subNum = subNum + 1;
else subNum = 1;
end
set(handles.subjectNumber,'String',num2str(subNum));

launchButton_Callback(handles.launchButton,eventdata,handles)



function commentText_Callback(hObject, eventdata, handles)
% hObject    handle to commentText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of commentText as text
%        str2double(get(hObject,'String')) returns contents of commentText as a double
global pathResults prevText todo
if(isempty(todo))
    set(handles.commentText,'String','');
    return
end
loader = load(pathResults);
%Set previous comment as last saved text
prevText = loader.currComment;
%Set current comment as text in box and save
currComment = get(handles.commentText,'String');
file2save = pathResults;
save(file2save,'currComment','-append');
set(handles.undoButton,'visible','on')

% --- Executes during object creation, after setting all properties.
function commentText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to commentText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in undoButton.
function undoButton_Callback(hObject, eventdata, handles)
% hObject    handle to undoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pathResults prevText
set(handles.commentText,'String',prevText);
set(handles.undoButton,'visible','off');
currComment = prevText;
save(pathResults,'currComment','-append');
prevText = [];


% --- Executes on selection change in rateLeft.
function rateLeft_Callback(hObject, eventdata, handles)
% hObject    handle to rateLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns rateLeft contents as cell array
%        contents{get(hObject,'Value')} returns selected item from rateLeft
global pathResults
ratingsLeft = get(handles.rateLeft,'Value');
file2save = pathResults;
save(file2save,'ratingsLeft','-append')

% --- Executes during object creation, after setting all properties.
function rateLeft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rateLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
