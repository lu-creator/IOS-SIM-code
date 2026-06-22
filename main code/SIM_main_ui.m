function varargout = SIM_main_ui(varargin)


% Edit the above text to modify the response to help SIM_main_ui

% Last Modified by GUIDE v2.5 13-Apr-2021 20:17:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SIM_main_ui_OpeningFcn, ...
    'gui_OutputFcn',  @SIM_main_ui_OutputFcn, ...
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


% --- Executes just before SIM_main_ui is made visible.
function SIM_main_ui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = SIM_main_ui_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
currPath = fileparts(mfilename('fullpath'));% get current path
p = cd(currPath);  %open the m file folder
addpath(genpath( 'function_code'));



% --- Executes on button press in wiener_sim.
%=================================================模式选用
function wiener_sim_Callback(hObject, eventdata, handles)

set(handles.wiener_sim,'value',1);
set(handles.wiener_sim_batch,'value',0);
set(handles.sparsity_based_denoising,'value',0);
set(handles.sparsity_denoise_batch_button,'value',0);

%%
set(handles.wiener_parameter_edit,'visible','on');
set(handles.wavelength_edit,'visible','on');
set(handles.average_num_edit,'visible','on');
set(handles.MU_edit,'visible','on');
set(handles.sigma_edit,'visible','on');
set(handles.pixelsize_edit,'visible','on');
set(handles.NA_edit,'visible','on');
set(handles.theta1_edit,'visible','on');
set(handles.theta2_edit,'visible','on');
set(handles.theta3_edit,'visible','on');
set(handles.default_otf,'visible','on');
set(handles.special_otf,'visible','on');
set(handles.default_bg,'visible','on');
set(handles.special_bg,'visible','on');
set(handles.rolling_button,'visible','on');



% --- Executes on button press in sparsity_based_denoising.
function sparsity_based_denoising_Callback(hObject, eventdata, handles)
set(handles.wiener_sim,'value',0);
set(handles.wiener_sim_batch,'value',0);
set(handles.sparsity_based_denoising,'value',1);
set(handles.sparsity_denoise_batch_button,'value',0);
set(handles.wavelength_edit,'visible','on');

% --- Executes on button press in sparsity_denoise_batch_button.
function sparsity_denoise_batch_button_Callback(hObject, eventdata, handles)
set(handles.wiener_sim,'value',0);
set(handles.wiener_sim_batch,'value',0);
set(handles.sparsity_based_denoising,'value',0);
set(handles.sparsity_denoise_batch_button,'value',1);
set(handles.wavelength_edit,'visible','on');


% --- Executes on button press in default_bg.
function default_bg_Callback(hObject, eventdata, handles)
set(handles.default_bg,'value',1);
set(handles.special_bg,'value',0);
set(handles.no_bg,'value',0);

% --- Executes on button press in no_bg.
function no_bg_Callback(hObject, eventdata, handles)
set(handles.default_bg,'value',0);
set(handles.special_bg,'value',0);
set(handles.no_bg,'value',1);


% --- Executes on button press in special_bg.
function special_bg_Callback(hObject, eventdata, handles)
set(handles.default_bg,'value',0);
set(handles.special_bg,'value',1);
set(handles.no_bg,'value',0);
[bg_filename,bg_pathname]=uigetfile({'*.tif'},'Please choose the Tif format background');
if isequal(bg_filename,0)
    warndlg('Interrupt choosing a special background','warn','modal');
    set(handles.default_bg,'value',1);
    set(handles.special_bg,'value',0);
else
    disp(['User selected：', fullfile(bg_pathname, bg_filename)])
    handles.bg_pathname=bg_pathname;
    handles.bg_filename=bg_filename;
end
guidata(hObject,handles);

% --- Executes on button press in default_otf.
function default_otf_Callback(hObject, eventdata, handles)
set(handles.default_otf,'value',1);
set(handles.special_otf,'value',0);


% --- Executes on button press in special_otf.
function special_otf_Callback(hObject, eventdata, handles)
set(handles.default_otf,'value',0);
set(handles.special_otf,'value',1);

[otf_filename,otf_pathname]=uigetfile({'*.tif'},'Please choose the Tif format OTF');
if isequal(otf_filename,0)
    warndlg('Interrupt choosing a special OTF','warn','modal');
    set(handles.default_otf,'value',1);
    set(handles.special_otf,'value',0);
else
    disp(['User selected：', fullfile(otf_pathname, otf_filename)])
    handles.otf_pathname=otf_pathname;
    handles.otf_filename=otf_filename;
end
guidata(hObject,handles);



function wavelength_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function wavelength_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NA_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function NA_edit_CreateFcn(hObject, eventdata, handles)
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pixelsize_edit_Callback(hObject, eventdata, handles)
% hObject    handle to pixelsize_edit (see GCBO)
% --- Executes during object creation, after setting all properties.
function pixelsize_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function average_num_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function average_num_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function wiener_parameter_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function wiener_parameter_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function theta1_edit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function theta1_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function theta2_edit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function theta2_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function theta3_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function theta3_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MU_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function MU_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sigma_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function sigma_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in start_process_button.
%=============================================================选择操作模式
function start_process_button_Callback(hObject, eventdata, handles)
if     get(handles.wiener_sim,'Value')==1 && get(handles.sparsity_based_denoising,'Value')==0 ...
        && get(handles.sparsity_denoise_batch_button,'Value')==0 && get(handles.wiener_sim_batch,'Value')==0
    my_wiener_run_file
    
elseif  get(handles.wiener_sim,'Value')==0 && get(handles.sparsity_based_denoising,'Value')==1 ...
        && get(handles.sparsity_denoise_batch_button,'Value')==0 && get(handles.wiener_sim_batch,'Value')==0
    sparsity_denoising
    
elseif  get(handles.wiener_sim,'Value')==0 && get(handles.sparsity_based_denoising,'Value')==0 ...
        && get(handles.sparsity_denoise_batch_button,'Value')==1 && get(handles.wiener_sim_batch,'Value')==0
    sparsity_denoising_batch
    
elseif  get(handles.wiener_sim,'Value')==0 && get(handles.sparsity_based_denoising,'Value')==0 ...
        && get(handles.sparsity_denoise_batch_button,'Value')==0 && get(handles.wiener_sim_batch,'Value')==1
    wiener_sim_batch
    
elseif  get(handles.wiener_sim,'Value')==0 && get(handles.sparsity_based_denoising,'Value')==0 ...
        && get(handles.sparsity_denoise_batch_button,'Value')==0 && get(handles.wiener_sim_batch,'Value')==0
    warndlg('please choose a process mode','warn','modal');
end



function using_parameter_edit_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function using_parameter_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function start_frame_edit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function start_frame_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function save_parameter_edit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function save_parameter_edit_CreateFcn(hObject, eventdata, handles)
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in open_imageJ_radio.
function open_imageJ_radio_Callback(hObject, eventdata, handles)
if     get(handles.open_imageJ_radio,'Value')==1
    add_ImageJ_path;
end

%==============================直接读取stack
function input_stack_data_button_Callback(hObject, eventdata, handles)

%增加图像路径保存
txt_name='pathname1.txt';
if exist(txt_name)
    pathname=importdata(txt_name);
    pathname=pathname{1};
else
    pathname=pwd;
end
[filename,pathname]=uigetfile({[pathname '\*.*']},'Please choose the Tif');
%[filename,pathname]=uigetfile({'*.tif'},'Please choose the Tif format file');
num_of_average=str2double(get(handles.average_num_edit,'String'));
nangle = 3;
nort = 3;
if isequal(filename,0)
    warndlg('Interrupt choosing a data','warn','modal');
else
    disp(['User selected：', fullfile(pathname, filename)])
    info = imfinfo(fullfile(pathname, filename));
    if length(info) >= num_of_average*nangle*nort
        image_stack = imreadstack_TIRF(fullfile(pathname, filename), 1, num_of_average*nangle*nort);
    else
        image_stack = imreadstack(fullfile(pathname, filename));  %整个stack
    end
    % axes1显示，清空axes2结果
    axes(handles.axes1);
    imshow(image_stack(:,:,1),[]);
    cla(handles.axes2);

    handles.image_stack=image_stack;
    handles.pathname=pathname;
    handles.filename=filename;
end
guidata(hObject,handles);

delete(txt_name);
fp=fopen(txt_name,'a');
fprintf(fp,'%s',pathname);
fclose(fp);



% --- 读取单张tif,并生成stack
function input_folder_data_button_Callback(hObject, eventdata, handles)
%pathname = uigetdir('', 'Pick a Directory');
% 加载以保存图像路径
txt_name='pathname2.txt';
if exist(txt_name)
    pathname=importdata(txt_name);
    pathname=pathname{1};
    pathname=uigetdir(pathname, 'Pick a Directory');
else
    pathname=uigetdir('', 'Pick a Directory');
end

start_frame=1;
% [image_stack,filename]=imread_batch_tif(pathname,start_frame);
[image_stack,filename]=imread_batch_full_tif(pathname,start_frame);
% axes1显示，清空axes2,截取中间512*512部分显示
height_set=512;
width_set=512;
[height, width, ~] = size(image_stack);
image(:,:,1)=image_stack((floor(height/2)-height_set/2):1:(floor(height/2)+height_set/2-1),...
    (floor(width/2)-width_set/2):1:(floor(width/2)+width_set/2-1), 1);
axes(handles.axes1);
imshow(image(:,:,1),[]);
cla(handles.axes2);
if get(handles.open_imageJ_radio,'Value')==1
    MIJ.createImage(image_stack);
end

handles.image_stack=image_stack;
handles.pathname=pathname;
handles.filename=filename;
%写出stack
index_dir=strfind(pathname(1:(end-1)),'\');
pathname_superior=pathname(1:index_dir(end)-1);
% imwritestack(image_stack,[pathname_superior   '\' filename]);

guidata(hObject,handles);
delete(txt_name);
fp=fopen(txt_name,'a');
fprintf(fp,'%s',pathname);
fclose(fp);

% --- Executes on button press in input_batch_stack_data_button.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function input_batch_stack_data_button_Callback(hObject, eventdata, handles)
txt_name='pathname3.txt';
if exist(txt_name)
    pathname=importdata(txt_name);
    pathname=pathname{1};
else
    pathname=pwd;
end

% 改为选择多个tif
[filename_batch,pathname] = uigetfile({[pathname, '\*.*']},'Please choose the batch file.','MultiSelect','on');
nangle = 3;
nort = 3;
num_of_average=str2double(get(handles.average_num_edit,'String'));
if ~isequal(filename_batch,0)   %
    if iscell(filename_batch)   %多选,filename_batch为cell类型
        FileName_batch=filename_batch;
        nFile=length(FileName_batch);   %获取多选文件个数        
        info = imfinfo(fullfile(pathname, FileName_batch{1}));
        if length(info) >= num_of_average*nangle*nort
            image_stack = imreadstack_TIRF(strcat(pathname,FileName_batch{1}), 1, num_of_average*nangle*nort);
        else
            image_stack = imreadstack(strcat(pathname,FileName_batch{1}));%读入第一个tif
        end      
    else
        nFile=1;   %单选
        FileName_batch{1} = filename_batch;   %单选时filename_batch为字符类型，为了统一转换成cell类型
        info = imfinfo(fullfile(pathname, FileName_batch{1}));
        if length(info) >= num_of_average*nangle*nort
            image_stack = imreadstack_TIRF(strcat(pathname,filename_batch), 1, num_of_average*nangle*nort);
        else
            image_stack=imread(strcat(pathname,filename_batch));%读入当前图像
        end    
        
    end
else   %用户没有选择文件，而是在对话框中点击了取消按钮
    return;   %
end

% axes1显示，清空axes2
% 显示第一个数据
axes(handles.axes1);
imshow(image_stack(:,:,1),[]);
cla(handles.axes2);

handles.pathname=pathname;
handles.FileName_batch=FileName_batch;
handles.nFile=nFile;

guidata(hObject,handles);
delete(txt_name);
fp=fopen(txt_name,'a');
fprintf(fp,'%s',pathname);
fclose(fp);

% --- Executes on button press in rolling_button.
function rolling_button_Callback(hObject, eventdata, handles)
% hObject    handle to rolling_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of rolling_button
% set(handles.rolling_button,'value',1);
% set(handles.no_rolling_button,'value',0);
if get(handles.rolling_button,'Value')==1
    rolling_mode=1;
end

% --- Executes on button press in laser488_radio.
function laser488_radio_Callback(hObject, eventdata, handles)
% hObject    handle to laser488_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.laser488_radio,'Value')==1
    wave=488;
end
% Hint: get(hObject,'Value') returns toggle state of laser488_radio
% --- Executes on button press in laser561_radio.
function laser561_radio_Callback(hObject, eventdata, handles)
% hObject    handle to laser561_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.laser488_radio,'Value')==1
    wave=561;
end
% Hint: get(hObject,'Value') returns toggle state of laser561_radio

% --- Executes on button press in laser640_radio.
function laser640_radio_Callback(hObject, eventdata, handles)
% hObject    handle to laser640_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.laser640_radio,'Value')==1
    wave=640;
end

% Hint: get(hObject,'Value') returns toggle state of laser640_radio


% --- Executes on button press in multicolor_button.
function multicolor_button_Callback(hObject, eventdata, handles)
% hObject    handle to multicolor_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
laser488=get(handles.laser488_radio,'Value');
laser561=get(handles.laser561_radio,'Value');
laser640=get(handles.laser640_radio,'Value');
sum_color=laser488+laser561+laser640;

%if     sum_color>=2
% my_multicolor_seprated_file
isBatchSplit = get(handles.BatchSplit,'Value');
if isBatchSplit == 0
    my_multicolor_seprated_file_add_splitter;
elseif isBatchSplit == 1
    Batch_multicolor_seprated_file_add_splitter;
end
%elseif  sum_color<2
%    warndlg('please choose multicolor mode','warn','modal');
%end



function notch_standard_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function notch_standard_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in phase_plot_radiobutton.
function phase_plot_radiobutton_Callback(hObject, eventdata, handles)
% hObject    handle to phase_plot_radiobutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
if get(handles.phase_plot_radiobutton,'Value')==1
    phase_plot_enable=1;
end
%}

% --- Executes on button press in wiener_sim_batch.
function wiener_sim_batch_Callback(hObject, eventdata, handles)
% hObject    handle to wiener_sim_batch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.wiener_sim,'value',0);
set(handles.wiener_sim_batch,'value',1);
set(handles.sparsity_based_denoising,'value',0);
set(handles.sparsity_denoise_batch_button,'value',0);
set(handles.wavelength_edit,'visible','off');

% --- Executes on button press in isPoorData.
function isPoorData_Callback(hObject, eventdata, handles)
% hObject    handle to isPoorData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% set(handles.isPoorData,'value', 1);
% Hint: get(hObject,'Value') returns toggle state of isPoorData

% --- Executes on button press in BatchFloderData.
function BatchFloderData_Callback(hObject, eventdata, handles)
% hObject    handle to BatchFloderData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pathnameBatch = uigetdir2('', 'Pick some Directories');
start_frame = 1;
% [image_stack,filename]=imread_batch_tif(pathname,start_frame);
[image_stack,filename] = imread_batch_full_tif(pathnameBatch{1},start_frame);
% axes1显示，清空axes2,截取中间512*512部分显示
height_set=512;
width_set=512;
[height, width, ~] = size(image_stack);
image(:,:,1) = image_stack((floor(height/2)-height_set/2):1:(floor(height/2)+height_set/2-1),...
    (floor(width/2)-width_set/2):1:(floor(width/2)+width_set/2-1), 1);
axes(handles.axes1);
imshow(image(:,:,1),[]);
cla(handles.axes2);

handles.image_stack=image_stack;
handles.pathnameBatch=pathnameBatch;
handles.filename=filename;
% handles.pathname=pathnameBatch{1};
pathname = pathnameBatch{1};
index_dir = strfind(pathname(1:(end-1)),'\');
pathname_superior = pathname(1:index_dir(end)-1);
% imwritestack(image_stack,[pathname_superior   '\' filename]);
handles.pathname=pathname_superior;
guidata(hObject,handles);


% --- Executes on button press in BatchSplit.
function BatchSplit_Callback(hObject, eventdata, handles)
% hObject    handle to BatchSplit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of BatchSplit
% --- Executes on button press in BackgroundRemove.
function BackgroundRemove_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundRemove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of BackgroundRemove
function BackgroundRemoveA_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundRemoveA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of BackgroundRemoveA as text
%        str2double(get(hObject,'String')) returns contents of BackgroundRemoveA as a double
% --- Executes during object creation, after setting all properties.
function BackgroundRemoveA_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundRemoveA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function BackgroundRemoveB_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundRemoveB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of BackgroundRemoveB as text
%        str2double(get(hObject,'String')) returns contents of BackgroundRemoveB as a double

% --- Executes during object creation, after setting all properties.
function BackgroundRemoveB_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundRemoveB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
