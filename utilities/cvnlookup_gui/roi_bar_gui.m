function varargout = roi_bar_gui(varargin)
% ROI_BAR_GUI MATLAB code for roi_bar_gui.fig
%      ROI_BAR_GUI, by itself, creates a new ROI_BAR_GUI or raises the existing
%      singleton*.
%
%      H = ROI_BAR_GUI returns the handle to a new ROI_BAR_GUI or the handle to
%      the existing singleton*.
%
%      ROI_BAR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROI_BAR_GUI.M with the given input arguments.
%
%      ROI_BAR_GUI('Property','Value',...) creates a new ROI_BAR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before roi_bar_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to roi_bar_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help roi_bar_gui

% Last Modified by GUIDE v2.5 29-Oct-2016 09:58:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @roi_bar_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @roi_bar_gui_OutputFcn, ...
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


% --- Executes just before roi_bar_gui is made visible.
function roi_bar_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to roi_bar_gui (see VARARGIN)

% Choose default command line output for roi_bar_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes roi_bar_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% after opening, grab info from test_gui
h = findobj('Tag','maingui');
hdata = guidata(h);
layer = str2num(hdata.layer);
hrf = hdata.HRF;

% set up initial parameters on this end
switch layer
    case 1
        set(handles.radio1,'Value',1);
    case 2
        set(handles.radio2,'Value',1);
    case 3
        set(handles.radio3,'Value',1);
    case 4
        set(handles.radio4,'Value',1);
    case 5
        set(handles.radio5,'Value',1);
    case 6
        set(handles.radio6,'Value',1);
    case 7
	set(handles.radio7,'Value',1);
end
    
% pull vertices from ROI
verticesStruct = spherelookup_image2vert(hdata.roi,hdata.L);
vertices = verticesStruct.data;
vertmask = vertices > 0;

switch hrf
        case '' 
                b = hdata.BETAS_OPT{layer};
		se = hdata.SE_OPT{layer};
                set(handles.Canonical,'Value',1);
        case 'IC1'
                b = hdata.BETAS_IC1{layer};
		se = hdata.SE_IC1{layer};
                set(handles.IC1,'Value',1);
        case 'IC2'
                b = hdata.BETAS_IC2{layer};
		se = hdata.SE_IC2{layer};
                set(handles.IC2,'Value',1);
end

valid_b = b(vertmask,:);
valid_se = se(vertmask,:);

means = mean(valid_b,1);
sems = mean(valid_se,1);
categorynames = hdata.categorynamesbase;

% Update internal data fields
handles.vertmask = vertmask;
handles.layer = hdata.layer;
handles.HRF = hdata.HRF;
handles.ylims = get_ylims(hdata);
guidata(hObject,handles);

populateBars(means,sems,categorynames,handles);

% --- Outputs from this function are returned to the command line.
function varargout = roi_bar_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function ylims = get_ylims(hdata)
	verticesStruct = spherelookup_image2vert(hdata.roi,hdata.L);
	vertices = verticesStruct.data;
	vertmask = vertices > 0;

	maxVal = -1000;
	minVal = 1000;
	hrf_strs = {'BETAS_OPT','BETAS_IC1','BETAS_IC2'};
	for layer = 1:7
		for hrf = 1:3
		
			betas = hdata.(hrf_strs{hrf}){layer};

			roi = betas(vertmask,:);
			roimean = mean(roi,1);
		
			tmp_max = max(roimean(:));
			tmp_min = min(roimean(:));

			if (tmp_max > maxVal)
				maxVal = tmp_max;
			end

			if (tmp_min < minVal)
				minVal = tmp_min;
			end
		end
	end
	
	% add a bit of a gap to top and bottom of graph-- set as 1x2 array where first value determines bottom gap and second value determines top gap
	gaps = [3 3];
	ylims = [minVal-gaps(1), maxVal+gaps(2)];	

function update_axes(handles)
	h = findobj('Tag','maingui');
	hdata = guidata(h);
	layer = str2num(handles.layer);
	hrf = handles.HRF;
	switch hrf
		case ''
			b = hdata.BETAS_OPT{layer};
			se = hdata.SE_OPT{layer};
			set(handles.Canonical,'Value',1);
		case 'IC1'
			b = hdata.BETAS_IC1{layer};
			se = hdata.SE_IC1{layer};
			set(handles.IC1,'Value',1);
		case 'IC2'
			b = hdata.BETAS_IC2{layer};
			se = hdata.SE_IC2{layer};
			set(handles.IC2,'Value',1);
	end

	valid_b = b(handles.vertmask,:);
	valid_se = se(handles.vertmask,:);

	means = mean(valid_b,1);
	sems = mean(valid_se,1);

	categorynames = hdata.categorynamesbase;
	populateBars(means,sems,categorynames,handles);

function populateBars(means,sems,names,handles)
    cla(handles.barax);
    N = length(means);
    colors = hsv(N);

    axes(handles.barax);
    hold on;
    for i=1:N
         bar(i,means(i),0.5,'facecolor',colors(i,:));
    end
    errorbar(1:N,means,sems,'k.');
    legend(names);
    ylabel('Beta');
    ylim(handles.ylims);
    set(gca,'XTickLabel',{[]});
    hold off;
 


% --- Executes when selected object is changed in uipanel5.
function uipanel5_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel5 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
handles.HRF = get(eventdata.NewValue,'Tag');
if strcmp(handles.HRF,'Canonical')
    handles.HRF = '';
end
guidata(hObject, handles);
update_axes(handles);


% --- Executes when selected object is changed in uipanel6.
function uipanel6_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel6 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
str = get(eventdata.NewValue,'Tag');
handles.layer = str(6:end); %cut off 'radio'
guidata(hObject, handles);
update_axes(handles);


% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
defstring = sprintf('betas_layer%s_hrf%s.png', handles.layer, handles.HRF);
[file,path] = uiputfile(defstring,'Save file name');
outname = [path,file];
im = export_fig(handles.barax,'-a1');
imwrite(im,outname);
