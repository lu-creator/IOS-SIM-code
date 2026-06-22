
%% 数据读取，根据数据路径新建结果存放文件夹
disp('Start reconstruction,please wait...');
pathname=handles.pathname;
filename=handles.filename;
image_stack=handles.image_stack;
warning off
addpath('./util')
addpath('./TIF')
% 如果最后一个不是\，则为文件夹输入方式
if pathname(end)~='\'
    index_dir=strfind(pathname(1:(end-1)),'\');
    pathname_superior=pathname(1:index_dir(end)-1);
elseif pathname(end)=='\' %stack输入方式
    pathname_superior=pathname;
end
mkdir([pathname_superior '\结果reconstruction Wiener sim']);

%%  参数读入
% 是否存储当前求解参数，或使用已有参数
using_parameter=str2double(get(handles.using_parameter_edit,'String'));
save_parameter=str2double(get(handles.save_parameter_edit,'String'));
wiener_parameter=str2double(get(handles.wiener_parameter_edit,'String'));
num_of_average=str2double(get(handles.average_num_edit,'String'));
Pixel_Size=str2double(get(handles.pixelsize_edit,'String'));
Excition_NA=str2double(get(handles.NA_edit,'String'));
sp_rate=[str2double(get(handles.theta1_edit,'String')),str2double(get(handles.theta2_edit,'String')),str2double(get(handles.theta3_edit,'String'))];
otf_flag=get(handles.default_otf,'Value')-get(handles.special_otf,'Value');
homochromy_wavelengh=str2double(get(handles.wavelength_edit,'String'));
notch_standard=str2double(get(handles.notch_standard,'String'));
isPoorData = get(handles.isPoorData,'Value');
rolling_mode= get(handles.rolling_button,'Value');
phase_plot_enable= get(handles.phase_plot_radiobutton,'Value');
isBackgroundRemove = get(handles.BackgroundRemove,'Value');
BackgroundRemoveA = str2double(get(handles.BackgroundRemoveA,'String'));
BackgroundRemoveB = str2double(get(handles.BackgroundRemoveB,'String'));
BackgroundRemoveParam = [isBackgroundRemove, BackgroundRemoveA, BackgroundRemoveB];

if otf_flag == 1
    otf_filename = '';
else
    otf_filename = [handles.otf_pathname '\' handles.otf_filename ];
end

h = 512;
w = 512;
if get(handles.default_bg,'Value') && ~get(handles.special_bg,'Value') && ~get(handles.no_bg,'Value')
    bgname = 'background.tif';
    bg = imreadstack(bgname);
    bgjie488 = bg((end/2)+1-(h)/2:(end/2)+(h)/2,(end/2)+1-(w)/2:(end/2)+(w)/2);
elseif ~get(handles.default_bg,'Value') && get(handles.special_bg,'Value') && ~get(handles.no_bg,'Value')
    bgname = [handles.bg_pathname '\' handles.bg_filename];
    bgjie488 = imreadstack(bgname);
%     bgjie488 = bg((end/2)+1-(h)/2:(end/2)+(h)/2,(end/2)+1-(w)/2:(end/2)+(w)/2);
elseif ~get(handles.default_bg,'Value') && ~get(handles.special_bg,'Value') && get(handles.no_bg,'Value')
    bgjie488 = zeros(h,w);
end

%% 区分单色或者多色情况，
laser488=get(handles.laser488_radio,'Value');
laser561=get(handles.laser561_radio,'Value');
laser640=get(handles.laser640_radio,'Value');
sum_color=laser488+laser561+laser640;

%% 如果是单色输入情况
%sum_color=0时，为单色成像，波长看homochromy_wavelengh
if sum_color==0
    
    tirff = ReconstructionSIM2(image_stack, bgjie488, homochromy_wavelengh, Pixel_Size, rolling_mode, BackgroundRemoveParam, otf_filename,...
        pathname_superior, filename, using_parameter, sp_rate, num_of_average, phase_plot_enable, isPoorData, wiener_parameter, notch_standard,0);
    
    cla(handles.axes1);
    axes(handles.axes1);
    imshow(real(image_stack(:,:,1)),[]);
    cla(handles.axes2);
    axes(handles.axes2);
    imshow(real(tirff(:,:,1)),[]);
    
    %% 多色成像，循环处理
elseif sum_color==2 ||sum_color==3
    [width, height, zstack_all]=size(image_stack);
    single_color_frame=zstack_all/sum_color;% 每一种颜色数据的帧数
    stack_pack=zeros(width, height, single_color_frame,sum_color);
    pack = zstack_all/9;
    if sum_color==2
        %区分488+561 、488+640、561+640成像
        if laser488==1
            colorname{1}='part_488nm';   %出错
            if laser561==1&& laser640==0
                colorname{2}='part_561nm';
            elseif laser561==0 && laser640==1
                colorname{2}='part_640nm';
            end
        elseif laser488==0 && laser561==1
            colorname{1}='part_561nm';
            colorname{2}='part_640nm';
        end
        % 将原始的所有双色数据按波长打包
        kk=0;
        for ii=1:pack
            color_rem= rem(ii,sum_color);
            if color_rem==0 %双色时第二种
                stack_pack(:,:,1+kk*9:9+kk*9,2)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
                kk=kk+1;
            elseif color_rem==1 % 第一种颜色
                stack_pack(:,:,1+kk*9:9+kk*9,1)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
            end
        end
    end
    
    if sum_color==3
        colorname{1}='part_488nm';
        colorname{2}='part_561nm';
        colorname{3}='part_640nm';
        % 将原始的所有三色数据按波长打包
        kk=0;
        for ii=1:pack
            color_rem= rem(ii,sum_color);
            if color_rem==0 %三色时第三种
                stack_pack(:,:,1+kk*9:9+kk*9,3)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
                kk=kk+1;
            elseif color_rem==1 % 第一种颜色
                stack_pack(:,:,1+kk*9:9+kk*9,1)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
            elseif color_rem==2 %三色时第二种
                stack_pack(:,:,1+kk*9:9+kk*9,1)=image_stack(:,:,1+9*(ii-1):9+9*(ii-1));
            end
        end
    end    
    %%%%%%%%%%%% for 循环开始重建 ，与单色基本相同
    for color_rank=1:sum_color        
        %%%%% 根据不同波长和尺寸选择OTF
        size1=max(height,width);
        max_image_length=max(size1,256);
        colorname_rank= colorname{color_rank};
        switch colorname_rank
            case 'part_488nm'
                wavelength = 488;
            case 'part_561nm'
                wavelength = 561;
            case 'part_640nm'
                wavelength=640;
        end        
        Progressbar = waitbar(0, 'Parameter Estimation...');        
        %%%%% 开始重建
        image_stack = stack_pack(:,:,:,color_rank);
        [height,width,zstack]=size(image_stack);
        % 重新定义文件名
        index_dir = strfind(pathname(1:(end-1)),'\');
        pathname_last = pathname(index_dir(end)+1:end);
        filename = [pathname_last '-' colorname{color_rank} '.tif'];        
        tirff = ReconstructionSIM(image_stack, bgjie488, wavelength, Pixel_Size, rolling_mode, BackgroundRemoveParam, otf_filename, ...
                pathname_superior, filename, using_parameter, sp_rate, num_of_average, phase_plot_enable, isPoorData, wiener_parameter, notch_standard, 0);       
    end
    cla(handles.axes1);
    axes(handles.axes1);
    imshow(real(image_stack(:,:,1)),[]);
    cla(handles.axes2);
    axes(handles.axes2);
    imshow(real(tirff(:,:,1)),[]);
end
disp('All Done')
helpdlg('All Done');