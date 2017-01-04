function varargout = contrast_selector_gui(varargin)
% CONTRAST_SELECTOR_GUI MATLAB code for contrast_selector_gui.fig
%      CONTRAST_SELECTOR_GUI, by itself, creates a new CONTRAST_SELECTOR_GUI or raises the existing
%      singleton*.
%
%      H = CONTRAST_SELECTOR_GUI returns the handle to a new CONTRAST_SELECTOR_GUI or the handle to
%      the existing singleton*.
%
%      CONTRAST_SELECTOR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CONTRAST_SELECTOR_GUI.M with the given input arguments.
%
%      CONTRAST_SELECTOR_GUI('Property','Value',...) creates a new CONTRAST_SELECTOR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before contrast_selector_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to contrast_selector_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help contrast_selector_gui

% Last Modified by GUIDE v2.5 21-Oct-2016 18:40:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @contrast_selector_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @contrast_selector_gui_OutputFcn, ...
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

% --- Executes just before contrast_selector_gui is made visible.
function contrast_selector_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to contrast_selector_gui (see VARARGIN)

% Choose default command line output for contrast_selector_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes contrast_selector_gui wait for user response (see UIRESUME)
% uiwait(handles.contrast_selector_gui);

h = findobj('Tag','maingui');
if (isempty(h))
	h = findobj('Tag','init_gui');
	hdata = guidata(h);
	handles.hdata = hdata;
	conditions = get_conditions(hdata.experiment);
	nConditions = numel(conditions);
	handles.mainIsOpen = 0;
else
	hdata = guidata(h);
	handles.hdata = hdata;
	conditions = get_conditions(hdata.experiment);
	nConditions = numel(conditions);
	handles.mainIsOpen = 1;
end

set(handles.listcon1,'String',conditions);

conditions_w_all = [{'all'} conditions];
set(handles.listcon2,'String',conditions_w_all);

set(handles.listcon1,'Max',nConditions,'Min',0);
set(handles.listcon2,'Max',nConditions,'Min',0);
guidata(hObject,handles);

% --- Outputs from this function are returned to the command line.
function varargout = contrast_selector_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listcon1.
function listcon1_Callback(hObject, eventdata, handles)
% hObject    handle to listcon1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listcon1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listcon1


% --- Executes during object creation, after setting all properties.
function listcon1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listcon1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on selection change in listcon2.
function listcon2_Callback(hObject, eventdata, handles)
% hObject    handle to listcon2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listcon2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listcon2


% --- Executes during object creation, after setting all properties.
function listcon2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listcon2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in goButton.
function goButton_Callback(hObject, eventdata, handles)
% hObject    handle to goButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
con1_all = get(handles.listcon1,'String');
con1_selected = con1_all(get(handles.listcon1,'Value'));
con2_all = get(handles.listcon2,'String');
con2_selected = con2_all(get(handles.listcon2,'Value'));

con1str = con1_selected{1};
for i=2:length(con1_selected)
	con1str = [con1str '_' con1_selected{i}];
end

con2str = con2_selected{1};
for i=2:length(con2_selected)
	con2str = [con2str '_' con2_selected{i}];
end

contrast = [con1str 'VS' con2str];
if (handles.mainIsOpen)
	test_gui('update_contrast',hObject,eventdata,handles,contrast,handles.hdata);
else
	initialization_gui('update_contrast',hObject,eventdata,handles,contrast,handles.hdata);
end
close(get(hObject,'Parent'));

