% 单色重建
function tirff = ReconstructionSIM(image_stack_all, bgjie488, wavelength, Pixel_Size, rolling_mode, BackgroundRemoveParam, otf_filename,...
    pathname_superior, filename, using_parameter, sp_rate, num_of_average, phase_plot_enable, ...
    isPoorData, wiener_parameter, notch_standard, isbatch)
warning off
addpath('./util')
addpath('./TIF')


% init_position = 48;  % 100X 10p
% init_position = 54;  % 100X 9p
% init_position = 61;  % 100X 8p
% init_position = 70;   % 100X 7p
init_position = 82;   % 100X 6p
% init_position = 98;   % 100X 5p
% init_position = 122;   % 100X 4p
% init_position = 162;   % 100X 3p
% init_position = 131;   % 100X SIM-1



seek_range = 10;
nphases = 3;
nangles = 3;
fre_length_half = 220;  %%限定范围略大于OTF边界
fc_ang = 120;
fc_con = 105;
% mode = 2;
% 去背景参数
isBackgroundRemove = BackgroundRemoveParam(1);
BackgroundRemoveA = BackgroundRemoveParam(2);
BackgroundRemoveB = BackgroundRemoveParam(3);

%%============================= 模拟任意尺寸成像和重建================================
% 默认尺寸
[h, w, z] = size(image_stack_all);
n_rect = max(h, w);
K_h = [h, w];
N_h = [n_rect,n_rect];
L_h = ceil((N_h-K_h) / 2);
v_h = colonvec(L_h+1, L_h+K_h);

% 如果是任意尺寸的成像和重建,不知道background对应位置的情况
if h ~= w           % 如果任意尺寸不是正方形,周围填充0,最小正方形
    image_stack = zeros(n_rect,n_rect);
    K_h = [h, w];
    N_h = [n_rect,n_rect];
    L_h = ceil((N_h-K_h) / 2);
    v_h = colonvec(L_h+1, L_h+K_h);
    hw = zeros(N_h);
    for ii = 1:1:z
        hw(v_h{:}) = image_stack_all(:,:,ii);
        image_stack(:,:,ii) = hw;
    end
else
    image_stack = image_stack_all;
end
if h~=512 || w~=512
    clear bgjie488
    bgjie488 = zeros(n_rect, n_rect);
    bgjie488(v_h{:}) = 99;
end

% ============================= 不同波长参数选择
if wavelength==488
    % 选择PSF/OTF
    if isempty(otf_filename) %选择默认的OTF/PSF
        deconv_otfname1 = '488FFT_512.tif';
    else %选择特定的OTF/PSF
        deconv_otfname1 = otf_filename;
    end
    psf = imreadstack(deconv_otfname1);

elseif wavelength==561
    if isempty(otf_filename)
        deconv_otfname1 = '561FFT_512.tif';
    else
        deconv_otfname1 = otf_filename;
    end
    psf=imreadstack(deconv_otfname1);

elseif wavelength==640||wavelength==637||wavelength==638
    if isempty(otf_filename)
        deconv_otfname1 = '640FFT_512.tif';
    else
        deconv_otfname1 = otf_filename;
    end
    psf=imreadstack(deconv_otfname1);

elseif wavelength==405
    if isempty(otf_filename)
        deconv_otfname1 = '405FFT_512.tif';
    else
        deconv_otfname1 = otf_filename;
    end
    psf=imreadstack(deconv_otfname1);

else
    if isempty(otf_filename)
        warndlg('The default OTF only support 405/488/561/640/637/638 wavelength. Please choose your special OTF if other wavelength.','warn','modal');
        return;
    end
    psf = imreadstack(otf_filename);
end

%========================================================= reconstruction

% 是否使用已有参数
% zuobiao_name = [pathname_superior '\结果reconstruction Wiener sim\' filename(1:end-4) '_zuobiao.mat'];%p所在位置的横坐标
% ang_name = [pathname_superior '\结果reconstruction Wiener sim\' filename(1:end-4) '_samec_angle.mat'];%包括相位angle6和调制系数c6
% zuobiao_name = ('D:\RIF-SIM\数据\20251127\bio_cell\100X\ROI3\P6\10frame\结果reconstruction Wiener sim\Result of data14_zuobiao.mat');
% ang_name = ('D:\RIF-SIM\数据\20251127\bio_cell\100X\ROI3\P6\10frame\结果reconstruction Wiener sim\Result of data14_samec_angle.mat');


if using_parameter==1
    % 如果没有数据？ 提醒
    if exist(zuobiao_name)  && exist(ang_name)
        load(zuobiao_name);
        load(ang_name);
        disp('调用已有P和phase');

    else
        if ~isbatch
            close(Progressbar);
        end
        warndlg('Parameter file does not exist');
        return
    end

elseif using_parameter==0
    % 任意尺寸重建，对应的PSF 也要任意尺寸
    max_h_w = max([h, w]);        % 参数求解初始化等比例缩放
    psf = imresize(psf, [max_h_w, max_h_w], 'bilinear');
  
    if isbatch
        Progressbar = 1;
    end
    info = imfinfo(strcat(pathname_superior,filename));  
    frame = length(info)/(nphases*nangles);
    % if frame < num_of_average
    %     num_of_average = frame;
    % end
    num_of_average =1;
    
    for iframe = 1:frame
    if ~isbatch
    Progressbar = waitbar(0, 'Parameter Estimation...');
    end
    image_stack = imreadstack_TIRF(strcat(pathname_superior,filename),  (iframe-1)*nangles*nphases+1, iframe*nangles*nphases);
    [phase_matrix, zuobiaox, zuobiaoy, peakmax]=...
        determine_p_SQI(image_stack, psf, sp_rate, num_of_average, max_h_w, fre_length_half, seek_range, init_position ,...
        nphases, nangles, Progressbar);
    
    [c6, angle6, g_hist_output, g_hist_fitting_output]...
        = determine_phase(image_stack, zuobiaox, zuobiaoy, bgjie488, phase_matrix,...
        num_of_average, fc_ang, fc_con, wavelength, psf, nphases, nangles, Progressbar, isbatch);
    if phase_plot_enable==1
        for ii_polt=1:6
            figure,plot(g_hist_output(ii_polt,:),'b');hold on;
            plot(g_hist_fitting_output(ii_polt,:),'r'); hold off;
            print(gcf, '-dtiff', '-r300', [pathname_superior '\结果reconstruction Wiener sim\'  num2str(iframe) 'frame_fitting' num2str(iframe) 'frame-' num2str(ii_polt) '.png']);
            close
        end
    end


    ZBX(iframe,1:9) = zuobiaox; ZBY(iframe,1:9) = zuobiaoy;
    XISHUC(iframe,1:6) = c6; XISHUA(iframe,1:6) = angle6;
    % % 保存新参数
    % save([pathname_superior '\结果reconstruction Wiener sim\' num2str(iframe) 'frame_zuobiao.mat'],'zuobiaox','zuobiaoy');
    % save([pathname_superior '\结果reconstruction Wiener sim\' num2str(iframe) 'frame_samec_angle.mat'],'c6','angle6');
    % clear zuobiaox zuobiaoy c6 angle6
    % load(zuobiao_name);
    % load(ang_name);

    for i=1:6
    if isnan(c6(1,1,i))
        c6(1,1,i)=1/2;
    end
    end

    evaC = c6(:);
    for i=1:6
    if c6(1,1,i) < 0.2
        c6(:)=0.4;
        break
    end
    end

    if isPoorData == 1
    c6(:) = 0.4;
    end

    xishu =[1,((1/c6(:,:,1))+(1/c6(:,:,2)))/2,((1/c6(:,:,1))+(1/c6(:,:,2)))/2,1,((1/c6(:,:,3))+(1/c6(:,:,4)))/2,((1/c6(:,:,3))+(1/c6(:,:,4)))/2,1,((1/c6(:,:,5))+(1/c6(:,:,6)))/2,((1/c6(:,:,5))+(1/c6(:,:,6)))/2];
    modulation_depth = xishu      %输出到命令行窗口
    p_length = sum(((zuobiaox-zuobiaox(1,1)).^2+(zuobiaoy-zuobiaoy(1,1)).^2).^0.5)./6

    % 分别计算三个方向的频率长度
    for i = 1:3
       n = (i-1)*3+2;
       PL(i,1) = ((zuobiaox(n,1)-zuobiaox(1,1)).^2+(zuobiaoy(n,1)-zuobiaoy(1,1)).^2).^0.5;

    end
    PL 

    % info = imfinfo(strcat(pathname_superior,filename));

if rolling_mode == 0 
    % frame = length(info)/(nphases*nangles);
    % for iframe = 1:frame
        image_stack_all = imreadstack_TIRF(strcat(pathname_superior,filename),  (iframe-1)*nangles*nphases+1, iframe*nangles*nphases);
        % 如果是任意尺寸的成像和重建
        [h, w, z] = size(image_stack_all);
        max_h_w = max([h, w]);
        padsize=0;
        x = 1:(w+2*padsize);
        y = (1:(h+2*padsize))';
        sig = 0.25;
        mask = repmat(sigmoid(sig*(x-padsize)) - sigmoid(sig*(x-w-padsize-1)),  h+2*padsize, 1) .* repmat(sigmoid(sig*(y-padsize)) - sigmoid(sig*(y-h-padsize-1)), 1, w+2*padsize);
        mask9 = repmat(mask.^3,[1 1 (nphases*nangles)]);
        mask9Pad = zeros(max_h_w, max_h_w, (nphases*nangles));
        K_h = [h, w];
        N_h = [n_rect,n_rect];
        L_h = ceil((N_h-K_h) / 2);
        v_h = colonvec(L_h+1, L_h+K_h);
        for i = 1:size(mask9, 3)
            hw = zeros(N_h);
            hw(v_h{:}) = mask9(:,:,i);
            mask9Pad(:,:,i) = hw;
        end
        if h ~= w           % 如果任意尺寸不是正方形,周围填充0,最小正方形
            image_stack = zeros(n_rect,n_rect);
            hw = zeros(N_h);
            for ii=1:1:z
                hw(v_h{:}) = image_stack_all(:,:,ii);
                image_stack(:,:,ii) = hw;
            end
        else
            image_stack = image_stack_all;
        end
%         [tirff, drr] = merge_all_component_GPUFilter(image_stack, c6, angle6, zuobiaox, zuobiaoy, fre_length_half, max_h_w,...
%                 wiener_parameter, psf, bgjie488, sp_rate, nphases, nangles, notch_standard, 1,  Pixel_Size,...
%                 isBackgroundRemove, BackgroundRemoveA, BackgroundRemoveB, mask9Pad);
        % [tirff, drr] = merge_all_component_Filter(image_stack, c6, angle6, zuobiaox, zuobiaoy, fre_length_half, max_h_w,...
        %         wiener_parameter, psf, bgjie488, sp_rate, nphases, nangles, notch_standard, 1,  Pixel_Size,...
        %         isBackgroundRemove, BackgroundRemoveA, BackgroundRemoveB, mask9Pad);
        disp(['========== 开始批量重建，第 ', num2str(iframe), ' 张图像，一共有',num2str(frame),'张图像 ==========']);
        [tirff, drr] = merge_all_component_rolling_notch_filter(image_stack, c6, angle6, zuobiaox, zuobiaoy, fre_length_half, max_h_w,...
                wiener_parameter, psf, bgjie488, sp_rate, nphases, nangles, notch_standard, 1,  Pixel_Size,...
                isBackgroundRemove, BackgroundRemoveA, BackgroundRemoveB, mask9Pad);
        % crop任意尺寸时填充黑边
        xfanwei = v_h{1};
        yfanwei = v_h{2};
        pcons = 10;
        stack(1:2*h, 1:2*w, :) = tirff( (2*xfanwei(1)-1):((2*xfanwei(1)-1)+2*h-1), (2*yfanwei(1)-1):((2*yfanwei(1)-1)+2*w-1), :);
        tirff = stack;
        if notch_standard == 0
            notch_swith = 0;
        else 
            notch_swith = 1;
        end
        if frame == 1
            imwritestack(stack, [pathname_superior '\结果reconstruction Wiener sim\Wiener' filename(1:end-4) '_wn' num2str(wiener_parameter) ...
            '_NF' num2str(notch_swith) '-' num2str(notch_standard) '_BG' num2str(isBackgroundRemove) '-' num2str(BackgroundRemoveA) '-' num2str(BackgroundRemoveB) '.tif']);
            imwritestack( abs(drr),[pathname_superior  '\结果reconstruction Wiener sim\' filename(1:end-4) '-fft.tif']);
        else
            imwritestacka(stack, [pathname_superior '\结果reconstruction Wiener sim\Wiener' filename(1:end-4) '_wn' num2str(wiener_parameter) ...
            '_NF' num2str(notch_swith) '-' num2str(notch_standard) '_BG' num2str(isBackgroundRemove) '-' num2str(BackgroundRemoveA) '-' num2str(BackgroundRemoveB) '.tif']);
            imwritestacka( abs(drr),[pathname_superior  '\结果reconstruction Wiener sim\' filename(1:end-4) '-fft.tif']);
        end


    % end

elseif rolling_mode==1
    if mode == 1
        image_stack_all = imreadstack(strcat(pathname_superior,filename));
        % 如果是任意尺寸的成像和重建
        [h, w, z] = size(image_stack_all);
        max_h_w = max([h, w]);
        padsize=0;
        x = 1:(w+2*padsize);
        y = (1:(h+2*padsize))';
        sig = 0.25;
        mask = repmat(sigmoid(sig*(x-padsize)) - sigmoid(sig*(x-w-padsize-1)),  h+2*padsize, 1) .* repmat(sigmoid(sig*(y-padsize)) - sigmoid(sig*(y-h-padsize-1)), 1, w+2*padsize);
        mask9 = repmat(mask.^3,[1 1 (nphases*nangles)]);
        mask9Pad = zeros(max_h_w, max_h_w, (nphases*nangles));
        K_h = [h, w];
        N_h = [n_rect,n_rect];
        L_h = ceil((N_h-K_h) / 2);
        v_h = colonvec(L_h+1, L_h+K_h);
        for i = 1:size(mask9, 3)
            hw = zeros(N_h);
            hw(v_h{:}) = mask9(:,:,i);
            mask9Pad(:,:,i) = hw;
        end
        if h ~= w           % 如果任意尺寸不是正方形,周围填充0,最小正方形
            image_stack = zeros(n_rect,n_rect);
            hw = zeros(N_h);
            for ii=1:1:z
                hw(v_h{:}) = image_stack_all(:,:,ii);
                image_stack(:,:,ii) = hw;
            end
        else
            image_stack = image_stack_all;
        end
        [tirff, drr] = merge_all_component_rolling_notch_filter(image_stack, c6, angle6, zuobiaox, zuobiaoy, fre_length_half,...
            max_h_w, wiener_parameter, psf, bgjie488, sp_rate, nphases, nangles, notch_standard, 1, Pixel_Size,...
            isBackgroundRemove, BackgroundRemoveA, BackgroundRemoveB, mask9Pad);
        % crop任意尺寸时填充黑边
        xfanwei = v_h{1};
        yfanwei = v_h{2};
        pcons = 10;
        stack(1:2*h, 1:2*w, :) = tirff( (2*xfanwei(1)-1):((2*xfanwei(1)-1)+2*h-1), (2*yfanwei(1)-1):((2*yfanwei(1)-1)+2*w-1), :);
        tirff = stack;
        imwritestack(stack, [pathname_superior '\结果reconstruction Wiener sim\Wiener' filename(1:end-4), '_rolling1.tif']);
        imwritestack( abs(drr).^(1/pcons),[pathname_superior  '\结果reconstruction Wiener sim\' filename(1:end-4),'-fft_rolling1.tif']);
    elseif mode == 2
        frame = length(info);
        for iframe = nphases*nangles:frame
            disp(iframe)
            if iframe == nphases*nangles
                image_stack_all = imreadstack_TIRF(strcat(pathname_superior,filename), 1, nangles*nphases);
            else
                frameNew = mod(iframe,nphases*nangles);
                if frameNew == 0
                    frameNew = 9;
                end
                image_stack_all(:,:,frameNew) = imreadstack_TIRF(strcat(pathname_superior,filename), iframe, iframe);
            end
            % 如果是任意尺寸的成像和重建
            [h, w, z] = size(image_stack_all);
            max_h_w = max([h, w]);
            padsize=0;
            x = 1:(w+2*padsize);
            y = (1:(h+2*padsize))';
            sig = 0.25;
            mask = repmat(sigmoid(sig*(x-padsize)) - sigmoid(sig*(x-w-padsize-1)),  h+2*padsize, 1) .* repmat(sigmoid(sig*(y-padsize)) - sigmoid(sig*(y-h-padsize-1)), 1, w+2*padsize);
            mask9 = repmat(mask.^3,[1 1 (nphases*nangles)]);
            mask9Pad = zeros(max_h_w, max_h_w, (nphases*nangles));
            K_h = [h, w];
            N_h = [n_rect,n_rect];
            L_h = ceil((N_h-K_h) / 2);
            v_h = colonvec(L_h+1, L_h+K_h);
            for i = 1:size(mask9, 3)
                hw = zeros(N_h);
                hw(v_h{:}) = mask9(:,:,i);
                mask9Pad(:,:,i) = hw;
            end
            if h ~= w           % 如果任意尺寸不是正方形,周围填充0,最小正方形
                image_stack = zeros(n_rect,n_rect);
                hw = zeros(N_h);
                for ii=1:1:z
                    hw(v_h{:}) = image_stack_all(:,:,ii);
                    image_stack(:,:,ii) = hw;
                end
            else
                image_stack = image_stack_all;
            end

            [tirff, drr] = merge_all_component_GPUFilter(image_stack, c6, angle6, zuobiaox, zuobiaoy, fre_length_half, max_h_w,...
                wiener_parameter, psf, bgjie488, sp_rate, nphases, nangles, notch_standard, 1,  Pixel_Size,...
                isBackgroundRemove, BackgroundRemoveA, BackgroundRemoveB, mask9Pad);

            % crop任意尺寸时填充黑边
            xfanwei = v_h{1};
            yfanwei = v_h{2};
%             pcons = 10;
            stack(1:2*h, 1:2*w, :) = tirff( (2*xfanwei(1)-1):((2*xfanwei(1)-1)+2*h-1), (2*yfanwei(1)-1):((2*yfanwei(1)-1)+2*w-1), :);
            tirff = stack;
            if iframe == nangles*nphases
                imwritestack(stack, [pathname_superior '\结果reconstruction Wiener sim\Wiener' filename(1:end-4), '_rolling2.tif']);
%                 imwritestack( abs(drr).^(1/pcons),[pathname_superior  '\结果reconstruction Wiener sim\' filename(1:end-4),'-fft_rolling2.tif']);
            else
                imwritestacka(stack, [pathname_superior '\结果reconstruction Wiener sim\Wiener' filename(1:end-4),'_rolling2.tif']);
%                 imwritestacka( abs(drr).^(1/pcons),[pathname_superior  '\结果reconstruction Wiener sim\' filename(1:end-4),'-fft_rolling2.tif']);
            end
        end
    end
end
    end

    save([pathname_superior '\结果reconstruction Wiener sim\' num2str(frame) 'frame_zuobiaoX.mat'],'ZBX');
    save([pathname_superior '\结果reconstruction Wiener sim\' num2str(frame) 'frame_zuobiaoY.mat'],'ZBY');
    save([pathname_superior '\结果reconstruction Wiener sim\' num2str(frame) 'frame_c6.mat'],'XISHUC');
    save([pathname_superior '\结果reconstruction Wiener sim\' num2str(frame) 'frame_angle.mat'],'XISHUA');

end




% ================== 判断重建结果的质量--根据p参数的估计结果
if using_parameter==0
    addpath('C:\Users\csr-b\Desktop\SIM MATLAB GUI v1.6.4\main code\function_code\evaluate_reconstructed');
    [isPTrue, p, ang, Pscore] = evaluateP(zuobiaox, zuobiaoy);

    % ================== 判断重建结果的质量--根据参数angle和c的估计结果
    [~, kut, Kscore] = evaluatePeak(g_hist_output);   % 根据参数angle的拟合曲线判断
    [~, Cscore] = evaluateC(evaC);                    % 根据参数c的求解结果判断

    % 计算互相关求p的峰值分数
    gooddata = 0.20;    % 较好数据的互相关峰值
    %     poordata = 0;
    %     peakmax
    PeakScores = peakmax.*(10/gooddata);
    PeakScores(PeakScores>10) = 10;
    PeakScores(PeakScores<0) = 0;
    PeakScore = sum(PeakScores)/3;

    Score = round(0.5*PeakScore + 0.1*Pscore + 0.2*Kscore + 0.2*Cscore);
    if Score<0 || isPTrue == 0
        Pscore = 0;
        Score = 0;
        disp(['Parameters fitting score: ', num2str( Score )]);
    else
        disp(['Parameters fitting score: ', num2str( Score )]);
    end
    if isPTrue == 0
        disp("Data's quality may be poor, You can use Prior Parameter");
    end

    % 并记录参数和分数结果
    f = fopen( [pathname_superior '\结果reconstruction Wiener sim\'  'Score.csv'], 'a');
    fprintf(f, '\r\n %s', [pathname_superior '\' filename]);
    for i = 1:numel(zuobiaox)
        fprintf(f, ',%s', num2str(zuobiaox(i)));
    end
    for i = 1:numel(zuobiaoy)
        fprintf(f, ',%s', num2str(zuobiaoy(i)));
    end
    ang = min(180-ang, ang);  % 转换到90度范围
    for i = 1:numel(ang)
        fprintf(f, ',%s', num2str(ang(i)));
    end
    for i = 1:numel(p)
        if i == 1 || i == 4 || i == 7

        else
            fprintf(f, ',%s', num2str(p(i)));
        end
    end
    for i = 1:numel(kut)
        fprintf(f, ',%s', num2str(kut(i)));
    end
    for i = 1:numel(c6)
        fprintf(f, ',%s', num2str(c6(i)));
    end
    for i = 1:2:numel(peakmax)
        fprintf(f, ',%s', num2str(peakmax(i)));
    end
    fprintf(f, ',%s', num2str(Pscore));
    fprintf(f, ',%s', num2str(PeakScore));
    fprintf(f, ',%s', num2str(Kscore));
    fprintf(f, ',%s', num2str(Cscore));
    fprintf(f, ',%s', num2str(isPTrue));
    fprintf(f, ',%s', num2str(Score));
    fclose(f);
end

if ~isbatch
    tirf_f = drr;
    pcons = 10;
    tirf_f2 = abs(tirf_f).^(1/pcons);   % 幅值开方增强显示效果
    % 定义需要标记的6个P值索引（根据SIM逻辑：2/3/5/6/8/9对应6个±1阶高频分量）
    p_index = [2,3,5,6,8,9]; 
    % 提取这6个点的坐标
    p_x = zuobiaox(p_index);  % 6个点的x坐标
    p_y = zuobiaoy(p_index);  % 6个点的y坐标
   
    % 频谱图像中心（像素坐标）
    x0=size(tirf_f,1)/2;
    y0=size(tirf_f,2)/2;
    % 添加辅助线
    theta1=20*pi/180;  %竖直30，水平60
    x1=x0-x0*cos(theta1);
    y1=y0-y0*sin(theta1);
    x2=x0+x0*cos(theta1);
    y2=y0+y0*sin(theta1);
    theta2=80*pi/180;  
    x3=x0-x0*cos(theta2);
    y3=y0-y0*sin(theta2);
    x4=x0+x0*cos(theta2);
    y4=y0+y0*sin(theta2);
    theta3=140*pi/180;  %竖直30，水平60
    x5=x0-x0*cos(theta3);
    y5=y0-y0*sin(theta3);
    x6=x0+x0*cos(theta3);
    y6=y0+y0*sin(theta3);
    h=figure;
    imshow(tirf_f2(:,:,1),[]),hold on;
    % plot([x0,x0],[5, size(tirf_f,2)-5],'r--'); hold on;
    plot([x1,x2],[y1,y2],'r--');hold on;
    plot([x3,x4],[y3,y4],'r--');hold on;
    plot([x5,x6],[y5,y6],'r--');hold on;

    plot(p_y, p_x, 'g+', 'MarkerSize', 12, 'LineWidth', 2); 
    for i = 1:length(p_index)
    text(p_y(i)+5, p_x(i)+5, num2str(p_index(i)), ...
         'Color','white', 'FontSize',8, 'FontWeight','bold');
    end
    hold off;  % 结束绘图

    saveas(h,[pathname_superior '\结果reconstruction Wiener sim\' filename(1:end-4),'-fftfig.tif']);

    
    h2=figure;
    imshow(tirf_f2(:,:,1),[]);

    saveas(h2,[pathname_superior '\结果reconstruction Wiener sim\' filename(1:end-4),'-fftfig2.tif']);


end
end