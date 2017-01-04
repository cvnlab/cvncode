function varargout = initialization_gui(varargin)
% INITIALIZATION_GUI MATLAB code for initialization_gui.fig
%      INITIALIZATION_GUI, by itself, creates a new INITIALIZATION_GUI or raises the existing
%      singleton*.
%
%      H = INITIALIZATION_GUI returns the handle to a new INITIALIZATION_GUI or the handle to
%      the existing singleton*.
%
%      INITIALIZATION_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INITIALIZATION_GUI.M with the given input arguments.
%
%      INITIALIZATION_GUI('Property','Value',...) creates a new INITIALIZATION_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before initialization_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to initialization_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help initialization_gui

% Last Modified by GUIDE v2.5 30-Oct-2016 11:42:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @initialization_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @initialization_gui_OutputFcn, ...
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


% --- Executes just before initialization_gui is made visible.
function initialization_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to initialization_gui (see VARARGIN)

% Choose default command line output for initialization_gui
handles.output = hObject;
handles.experiment = 'floc';
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes initialization_gui wait for user response (see UIRESUME)
% uiwait(handles.init_gui);


% --- Outputs from this function are returned to the command line.
function varargout = initialization_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



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


% --- Executes on button press in browseButton.
function browseButton_Callback(hObject, eventdata, handles)
% hObject    handle to browseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
str = uigetdir(cvnpath('fmridata'),'Choose GLM Results folder');
set(handles.resultsdirField, 'String', str);
[handles.experiment, handles.default_contrast] = data_dir_to_experiment(str);
set(handles.contrastField,'String',handles.default_contrast);
set(handles.experimentSelector,'String',handles.experiment);
guidata(hObject,handles);


function contrastField_Callback(hObject, eventdata, handles)
% hObject    handle to contrastField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of contrastField as text
%        str2double(get(hObject,'String')) returns contents of contrastField as a double


% --- Executes during object creation, after setting all properties.
function contrastField_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contrastField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectContrastButton.
function selectContrastButton_Callback(hObject, eventdata, handles)
% hObject    handle to selectContrastButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contrast_selector_gui

% --- Executes on selection change in experimentSelector.
function experimentSelector_Callback(hObject, eventdata, handles)
% hObject    handle to experimentSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns experimentSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from experimentSelector
experimentNum = get(handles.experimentSelector,'Value');
experiments = get(handles.experimentSelector,'String');
if (iscell(experiments))
	handles.experiment = experiments{experimentNum};
else
	handles.experiment = experiments;
end

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function experimentSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to experimentSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject,'String','floc');

function update_contrast(hObject,eventdata,x,contrast,handles)
	handles.contrast = contrast;
	set(handles.contrastField,'String',handles.contrast);

% --- Executes on button press in launchButton.
function launchButton_Callback(hObject, eventdata, handles)
% hObject    handle to launchButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

test_gui
close(get(hObject,'Parent'));
