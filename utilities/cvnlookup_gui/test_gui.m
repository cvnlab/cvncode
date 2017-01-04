function varargout = test_gui(varargin)
% TEST_GUI MATLAB code for test_gui.fig
%      TEST_GUI, by itself, creates a new TEST_GUI or raises the existing
%      singleton*.
%
%      H = TEST_GUI returns the handle to a new TEST_GUI or the handle to
%      the existing singleton*.
%
%      TEST_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST_GUI.M with the given input arguments.
%
%      TEST_GUI('Property','Value',...) creates a new TEST_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before test_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to test_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help test_gui

% Last Modified by GUIDE v2.5 01-Nov-2016 17:34:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @test_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @test_gui_OutputFcn, ...
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


% --- Executes just before test_gui is made visible.
function test_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to test_gui (see VARARGIN)

% Choose default command line output for test_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes test_gui wait for user response (see UIRESUME)
% uiwait(handles.maingui);

% Start custom code here
%-----------------------%

% set up empty cells (one for each layer) for betas and se for each of the three HRFs
% layermean (average of preprocessed timeseries across layers) is treated as layer 7
handles.BETAS_OPT = cell(7,1);
handles.SE_OPT = cell(7,1);
handles.BETAS_IC1 = cell(7,1);
handles.SE_IC1 = cell(7,1);
handles.BETAS_IC2 = cell(7,1);
handles.SE_IC2 = cell(7,1);

% get the data directory, results directory, and subject ID (freesurfer) from the init gui
h = findobj('Tag','init_gui');
init_handles = guidata(h);
resultsdir = get(init_handles.resultsdirField,'String');
sep_idx = strfind(resultsdir,'/');
datadir = resultsdir(1:sep_idx(end-1)-1);

% Get experiment info
handles.experiment = init_handles.experiment;
handles.overlayVisibility = 1;

% Preload data from all layers and save it in handles
% Right now "IC1" and "IC2" just duplicate the canconical HRF results, but this can be modified to accept other results directories for comparison
h_wait = waitbar(0,'');
layers = {'1','2','3','4','5','6','mean'};

total_loads = 21;
idx = 1;
for layer = 1:7
	% load canonical HRF results
	waitbar(idx/total_loads, h_wait, sprintf('Loading Layer %.0f, Canonical HRF',layer));
	idx = idx + 1;
	[handles.BETAS_OPT{layer}, handles.SE_OPT{layer}, handles.subject] = init_fields(resultsdir, '',1:10, layers{layer});

	% load IC1 results (or copy from canonical for now)
	waitbar(idx/total_loads, h_wait, sprintf('Loading Layer %.0f, IC1',layer));
	idx = idx + 1;
	handles.BETAS_IC1{layer} = handles.BETAS_OPT{layer};
	handles.SE_IC1{layer} = handles.SE_OPT{layer};
	%[handles.BETAS_IC1{layer}, handles.SE_IC1{layer},~] = init_fields(resultsdir, '_IC12',1:10, layers{layer});

	% load IC2 results (or copy from canonical for now)
	waitbar(idx/total_loads, h_wait, sprintf('Loading Layer %.0f, IC2',layer));
	idx = idx + 1;
	handles.BETAS_IC2{layer} = handles.BETAS_OPT{layer};
	handles.SE_IC2{layer} = handles.SE_OPT{layer};
	%[handles.BETAS_IC2{layer}, handles.SE_IC2{layer}] = init_fields(resultsdir, '_IC12',11:20, layers{layer});
end
close(h_wait);

% populate various gui fields
set(handles.resultsdirField,'String',resultsdir);
[handles.categorynames,handles.categorynamesbase] = get_conditions(handles.experiment);
handles.contrast = get(init_handles.contrastField,'String');
set(handles.contrast_post,'String',handles.contrast);
[con1,con2] = get_con1_con2(handles.experiment,handles.contrast);

% For layer 1 (the default load) compute t-stat (default metric)
tstats = compute_glm_metric(handles.BETAS_OPT{1},handles.SE_OPT{1},con1,con2,'tstat',2);
metricmax = max(tstats);
metricmin = min(tstats);

set(handles.tmax,'string',metricmax);
set(handles.threshField,'string',metricmin);


% Generate default image (faces tstat layer1 canonical HRF)
[im, handles.L, handles.S] = make_figs(handles.subject,handles.BETAS_OPT{1},handles.SE_OPT{1},'tstat','hot',con1,con2,metricmin,metricmax,[], [],'','curv',handles.overlayVisibility);

% Switch focus to brainax, show image
axes(handles.brainax);
imshow(im);
hold on;

% Create colorbar (default is hot) with 100 colors
colormap(hot(100));
hc = colorbar;

% Explicity set display limits to those in GUI
ylim(hc,[metricmin,metricmax]);
hcImg = findobj(hc,'type','image');
set(hcImg,'YData',[metricmin,metricmax]);
ylabel(hc, 'tstat');
hold off;

% Set defaults as handles fields to grab them easily later on
handles.layer = '1';
handles.HRF = '';
handles.roi = [];

% Load mean bias corrected for each layer
bias_struct = matfile(sprintf([datadir, '/preprocessVER1SURF%s/meanbiascorrected04.mat'],handles.subject));
bias_data = permute(bias_struct.data,[3 1 2]);
for layer = 1:6
    mean_bias_corrected{layer} = bias_data(:,1,layer);
end

% Manually set bias corrected for layer mean
mean_bias_corrected{7} = mean(bias_data(:,1,:),3);
handles.bias_corrected_mean_epi = mean_bias_corrected;

% Update handles var for later use
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = test_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
update_axes(handles);

% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function threshField_Callback(hObject, eventdata, handles)
% hObject    handle to threshField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshField as text
%        str2double(get(hObject,'String')) returns contents of threshField as a double

update_axes(handles);

% --- Executes during object creation, after setting all properties.
function threshField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
update_axes(handles);

% --- Executes during object creation, after setting all properties.
function brainax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to brainax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate brainax


% --- Executes when selected object is changed in uipanel2.
function uipanel2_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel2 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
str = get(eventdata.NewValue,'Tag');
handles.layer = str(6:end); %cut off 'radio'
guidata(hObject, handles);
update_axes(handles);


% --- Executes during object creation, after setting all properties.
function uipanel2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes when selected object is changed in uipanel3.
function uipanel3_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel3 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
str = get(eventdata.NewValue,'Tag');
handles.HRF = str(6:end); %cut off 'radio'
if strcmp(handles.HRF,'Canonical')
    handles.HRF = '';
end
guidata(hObject, handles);
update_axes(handles);



function tmax_Callback(hObject, eventdata, handles)
% hObject    handle to tmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tmax as text
%        str2double(get(hObject,'String')) returns contents of tmax as a double
update_axes(handles);


% --- Executes during object creation, after setting all properties.
function tmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in savebutton.
function savebutton_Callback(hObject, eventdata, handles)
% hObject    handle to savebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contrast = get(handles.contrast_post,'String');
thresh = get(handles.threshField,'string');
tmax = get(handles.tmax,'string');
if (isempty(handles.HRF))
    hrfstr = 'canonical';
else
    hrfstr = handles.HRF;
end

defstring = sprintf('inflated_ventral_%s_%s_layer%s_HRF%s_t%s_%s.png', ...
	handles.experiment, contrast, handles.layer, ...
	hrfstr, thresh, tmax);
[file,path] = uiputfile(defstring,'Save file name');
outname = [path,file];
if (file)
	im = export_fig(handles.brainax,'-a1');
	imwrite(im,outname);
end

function L = update_axes(handles)
	set(handles.maingui, 'pointer', 'watch')
	drawnow;
	
	sub = handles.subject;
	thresh = str2num(get(handles.threshField,'string'));
	tmax = str2num(get(handles.tmax,'string'));

	contrast = get(handles.contrast_post,'String');
	[con1,con2] = get_con1_con2(handles.experiment,contrast);

	metricNum = get(handles.metricdrop,'Value');
	metrics = get(handles.metricdrop,'String');
	metric = metrics{metricNum};

	colormapNum = get(handles.colordrop,'Value');
	colormaps = get(handles.colordrop,'String');
	cmap = colormaps{colormapNum};

   	layerNum = str2num(handles.layer);
    
	backgroundNum = get(handles.backgroundDrop,'Value');
	backgrounds = get(handles.backgroundDrop,'String');
	bg = backgrounds{backgroundNum};
    
	switch bg
		case 'curvature'
		    bg = 'curv';
		case 'mean EPI'
		    bg = handles.bias_corrected_mean_epi{layerNum};
	end
    
	if strcmp(handles.HRF,'IC1')
	    b = handles.BETAS_IC1{layerNum};
	    s = handles.SE_IC1{layerNum};
	elseif strcmp(handles.HRF,'IC2')
	    b = handles.BETAS_IC2{layerNum};
	    s = handles.SE_IC2{layerNum};
	else 
	    b = handles.BETAS_OPT{layerNum};
	    s = handles.SE_OPT{layerNum};
	end

	[im, L,~] = make_figs(sub,b,s,metric,cmap,con1, con2, thresh, tmax, handles.L, handles.S, handles.HRF, bg, handles.overlayVisibility);

	axes(handles.brainax);
	if ~isempty(handles.roi)
		if (~isempty(handles.perim))
			% dilate border to make it easier to see
			tmp = imdilate(handles.perim,strel('disk',1));
			r = im(:,:,1);
			g = im(:,:,2);
			b = im(:,:,3);
			r(tmp) = 0;
			g(tmp) = 0;
			b(tmp) = 0;
			im(:,:,1) = r;
			im(:,:,2) = g;
			im(:,:,3) = b;
		end
	end
	imshow(im);
	hold on;
	% if roi exists but the perimeter hasn't been set (i.e., no shrinkwrapping) then draw bounding box
	if ~isempty(handles.roi) && isempty(handles.perim)
		hp = plot(handles.roix,handles.roiy,'k.-','MarkerSize',5,'LineWidth',3);
	end
	colormap(eval([cmap, '(', num2str(100), ')']));
	hc = colorbar;
	ylabel(hc, metric);
	ylim(hc,[thresh,tmax]);
	hcImg = findobj(hc,'type','image');
	set(hcImg,'YData',[thresh,tmax]);
	hold off;

	set(handles.maingui, 'pointer', 'arrow');
	drawnow;


% --- Executes on selection change in popupmenu3.
function metricdrop_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3
update_axes(handles);

% --- Executes during object creation, after setting all properties.
function metricdrop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
set(hObject,'Value',1);
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4.
function colordrop_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4
update_axes(handles);


% --- Executes during object creation, after setting all properties.
function colordrop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
set(hObject,'Value',1);
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function radio1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radio1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'Value',1);



function resultsdirField_Callback(hObject, eventdata, handles)
% hObject    handle to resultsdirField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of resultsdirField as text
%        str2double(get(hObject,'String')) returns contents of resultsdirField as a double


% --- Executes during object creation, after setting all properties.
function resultsdirField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to resultsdirField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in dataBrowseButton.
function dataBrowseButton_Callback(hObject, eventdata, handles)
% hObject    handle to dataBrowseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set the results directory based on Browse output
str = uigetdir(cvnpath('fmridata'),'Choose GLM Results folder');
set(handles.resultsdirField,'String',str);
resultsdir = get(handles.resultsdirField,'String');

% Load in data, use waitbar
h = waitbar(0,'');
layers = {'1','2','3','4','5','6','mean'};

total_loads = 21;
idx = 1;
for layer = 1:7
	
	waitbar(idx/total_loads, h, sprintf('Loading Layer %.0f, Canonical HRF',layer));
	idx = idx + 1;
	[handles.BETAS_OPT{layer}, handles.SE_OPT{layer}, subject] = init_fields(resultsdir, '',1:10, layers{layer});

	waitbar(idx/total_loads, h, sprintf('Loading Layer %.0f, IC1',layer));
	idx = idx + 1;
	handles.BETAS_IC1{layer} = handles.BETAS_OPT{layer};
	handles.SE_IC1{layer} = handles.SE_OPT{layer};
	%[handles.BETAS_IC1{layer}, handles.SE_IC1{layer},~] = init_fields(resultsdir, '_IC12',1:10, layers{layer});

	waitbar(idx/total_loads, h, sprintf('Loading Layer %.0f, IC2',layer));
	idx = idx + 1;
	handles.BETAS_IC2{layer} = handles.BETAS_OPT{layer};
	handles.SE_IC2{layer} = handles.SE_OPT{layer};
	%[handles.BETAS_IC2{layer}, handles.SE_IC2{layer}] = init_fields(resultsdir, '_IC12',11:20, layers{layer});
end
close(h);
tstats = compute_glm_metric(handles.BETAS_OPT{1},handles.SE_OPT{1},[1 2],[],'tstat',2);
metricmax = max(tstats);
metricmin = min(tstats);

set(handles.tmax,'string',metricmax);
set(handles.threshField,'string',metricmin);

% Load mean bias corrected for each layer
sep_idx = strfind(resultsdir,'/');
datadir = resultsdir(1:sep_idx(end-1)-1);
[handles.experiment, default_contrast] = data_dir_to_experiment(datadir);
set(handles.contrast_post,'String',default_contrast);
[handles.categorynames,handles.categorynamesbase] = get_conditions(handles.experiment);


bias_struct = matfile(sprintf([datadir, '/preprocessVER1SURF%s/meanbiascorrected04.mat'],subject));
bias_data = permute(bias_struct.data,[3 1 2]);
for layer = 1:6
	mean_bias_corrected{layer} = bias_data(:,1,layer);
end

% Manually set bias corrected for layer mean
mean_bias_corrected{7} = mean(bias_data(:,1,:),3);
handles.bias_corrected_mean_epi = mean_bias_corrected;
handles.subject = subject;

% Clear subject specific fields
handles.S = [];
handles.L = [];

% Clear ROI and its buttons
handles.roi = [];
handles.roix = [];
handles.roiy = [];
set(handles.analyzeroiButton,'enable','off');
set(handles.shrinkButton,'enable','off');
set(handles.saveroiButton,'enable','off');
set(handles.clearroiButton,'enable','off');

% Update brainax
guidata(hObject,handles);
L = update_axes(handles);
handles.L = L;
guidata(hObject,handles);


function subField_Callback(hObject, eventdata, handles)
% hObject    handle to subField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subField as text
%        str2double(get(hObject,'String')) returns contents of subField as a double
update_axes(handles);

% --- Executes during object creation, after setting all properties.
function subField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in roiButton.
function roiButton_Callback(hObject, eventdata, handles)
% hObject    handle to roiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.roi = [];
handles.roix = [];
handles.roiy = [];
handles.perim = [];
update_axes(handles);

%focus on the figure axes
axes(handles.brainax);

% draw ROI
[r, x, y] = roipoly();
handles.roi = r;

% pull vertices from ROI
verticesStruct = spherelookup_image2vert(handles.roi,handles.L);
handles.roi_vertices = verticesStruct.data;

handles.roix = x;
handles.roiy = y;
guidata(hObject,handles);
update_axes(handles);
set(handles.clearroiButton,'enable','on');
set(handles.analyzeroiButton,'enable','on');
set(handles.shrinkButton,'enable','on');
set(handles.saveroiButton,'enable','on');

% draw ROI on surface until next time button is clicked

function analyze_ROI(handles)
	roi_bar_gui
	return;
	
	% pull vertices from ROI
	verticesStruct = spherelookup_image2vert(handles.roi,handles.L);
	vertices = verticesStruct.data;
	vertmask = vertices > 0;

	layer = str2num(handles.layer);
	switch handles.HRF
		case ''
			b = handles.BETAS_OPT{layer};
		case 'IC1'
			b = handles.BETAS_IC1{layer};
		case 'IC2'
			b = handles.BETAS_IC2{layer};
	end

	valid_b = b(vertmask,:);

	means = mean(valid_b,1);
	sems = std(valid_b,[],1)./sqrt(size(valid_b,1));

	categorynames = handles.categorynamesbase;
	im = create_bar_fig(means,sems,categorynames);


% --- Executes on button press in analyzeroiButton.
function analyzeroiButton_Callback(hObject, eventdata, handles)
% hObject    handle to analyzeroiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
analyze_ROI(handles);


% --- Executes during object creation, after setting all properties.
function roiButton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to roiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in clearroiButton.
function clearroiButton_Callback(hObject, eventdata, handles)
% hObject    handle to clearroiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.roi = [];
handles.roix = [];
handles.roiy = [];
guidata(hObject,handles);
set(handles.analyzeroiButton,'enable','off');
set(handles.shrinkButton,'enable','off');
set(handles.saveroiButton,'enable','off');
set(hObject,'enable','off');
update_axes(handles);


% --- Executes during object creation, after setting all properties.
function analyzeroiButton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to analyzeroiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'enable','off');


% --- Executes during object creation, after setting all properties.
function clearroiButton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to clearroiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'enable','off');


% --- Executes on button press in shrinkButton.
function shrinkButton_Callback(hObject, eventdata, handles)
% hObject    handle to shrinkButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


layer = str2num(handles.layer);
switch handles.HRF
    case ''
        b = handles.BETAS_OPT{layer};
        se = handles.SE_OPT{layer};
    case 'IC1'
        b = handles.BETAS_IC1{layer};
        se = handles.SE_IC1{layer};
    case 'IC2'
        b = handles.BETAS_IC2{layer};
        se = handles.SE_IC2{layer};
end
thresh = str2num(get(handles.threshField,'string'));

contrast = get(handles.contrast_post,'String');
[con1,con2] = get_con1_con2(handles.experiment,contrast);

metricNum = get(handles.metricdrop,'Value');
metrics = get(handles.metricdrop,'String');
metric = metrics{metricNum};

valid_func_vertices = get_valid_func_vertices(b,se,metric,con1,con2,thresh);

rL = handles.L{1};
lL = handles.L{2};

valstruct = struct('data',valid_func_vertices,'numrh',rL.vertsN,'numlh',lL.vertsN);
validpx = spherelookup_vert2image(valstruct,handles.L,0);
roi = handles.roi;
overlap = roi .* validpx;
handles.roi = overlap;
handles.perim = bwperim(overlap);
handles.roix = [];
handles.roiy = [];

% update handles.roi_vertices
verticesStruct = spherelookup_image2vert(handles.roi,handles.L);
handles.roi_vertices = verticesStruct.data;

guidata(hObject,handles);
update_axes(handles);


% --- Executes during object creation, after setting all properties.
function shrinkButton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to shrinkButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'enable','off');


% --- Executes on button press in saveroiButton.
function saveroiButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveroiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
roi = handles.roi;
vertices = handles.roi_vertices;
roix = handles.roix;
roiy = handles.roiy;
perim = handles.perim;
resultsdir = get(handles.resultsdirField,'String');
sub_path = sprintf('%s/../ROIs',resultsdir);
mkdirquiet(sub_path);
[sfile,spath] = uiputfile([sub_path, '/*.mat'],'Save ROI');
outname = [spath sfile];
if (sfile)
	save(outname,'roi','vertices','roix','roiy','perim');
end


% --- Executes during object creation, after setting all properties.
function saveroiButton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveroiButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'enable','off');


% --- Executes on button press in roiloadbutton.
function roiloadbutton_Callback(hObject, eventdata, handles)
% hObject    handle to roiloadbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
resultsdir = get(handles.resultsdirField,'String');
sub_path = sprintf('%s/../ROIs',resultsdir);
[fname,pathname] = uigetfile([sub_path,'/*.mat'],'Load ROI');
if (fname)
	x = load([pathname,fname]);
	handles.roi = x.roi;
	handles.roix = x.roix;
	handles.roiy = x.roiy;
	handles.perim = x.perim;
	guidata(hObject,handles);
	update_axes(handles);
	set(handles.clearroiButton,'enable','on');
	set(handles.analyzeroiButton,'enable','on');
	set(handles.shrinkButton,'enable','on');
	set(handles.saveroiButton,'enable','on');
end


% --- Executes on button press in contrastSelectorButton.
function contrastSelectorButton_Callback(hObject, eventdata, handles)
% hObject    handle to contrastSelectorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contrast_selector_gui

function update_contrast(hObject,eventdata,x,contrast,handles)
	handles.contrast = contrast;
	set(handles.contrast_post,'String',handles.contrast);
	update_axes(handles);


% --- Executes on selection change in backgroundDrop.
function backgroundDrop_Callback(hObject, eventdata, handles)
% hObject    handle to backgroundDrop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns backgroundDrop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from backgroundDrop
update_axes(handles);

% --- Executes during object creation, after setting all properties.
function backgroundDrop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to backgroundDrop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
set(hObject,'Value',1);
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close maingui.
function maingui_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to maingui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in toggleButton.
function toggleButton_Callback(hObject, eventdata, handles)
% hObject    handle to toggleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (handles.overlayVisibility == 1)
	handles.overlayVisibility = 0;
else
	handles.overlayVisibility = 1;
end
guidata(hObject,handles);
update_axes(handles);
