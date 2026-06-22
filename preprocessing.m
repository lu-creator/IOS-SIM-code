%% ===================== 全局参数&路径配置区 =====================
clc; clear all; close all;
% 输入文件路径
input_path = 'C:\Users\CSR\Desktop\IOS-SIM MATLAB\sampledata\cell-100X-P6.tif';
% 算法可调参数
total_per_group = 9;    % 每组总帧数10
sim_frame_num   = 9;     % 有效SIM 1~9帧
gauss_D0        = 90;    % 高斯低通截止频率
norm_max_val    = 50000; % 归一化上限值

% 高频叠加系数模式选择 1/2/3 三选一
% 1:固定系数0.45  2:按全局最大值自适应ratio4  3:按全局均值自适应ratio5
weight_mode = 1;
fixed_coeff = 0.45;      % mode1固定权重

%% ===================== 读取原始堆叠数据 =====================
rawdata = imreadstack_TIRF(input_path);
[img_h, img_w, total_slices] = size(rawdata);
group_num = total_slices / total_per_group; % 分组总数

% 预分配全局输出矩阵
Isum2 = zeros(img_h, img_w, sim_frame_num * group_num);

%% ===================== 逐组循环处理SIM数据 =====================
for k = 1 : group_num
    k2 = k;
    % 拆分单组10帧SIM数据
    SIM = zeros(img_h, img_w, total_per_group);
    for j = 1 : total_per_group
        slice_idx = (j - 1) * group_num + k;
        SIM(:, :, j) = rawdata(:, :, slice_idx);
    end

    %% 1. 三个方向合成最大宽场MAX_WF
    MAX_WF = zeros(img_h, img_w, 3);
    for dir_idx = 1 : 3
        slice_range = (dir_idx - 1) * 3 + (1:3);
        A = SIM(:, :, slice_range);
        MAX_WF(:, :, dir_idx) = max(A, [], 3);
    end
    WF_uniform = mean(SIM(:,:,1:9),3);

    %% 2. 背景相减：SIM帧 - 对应方向MAX_WF，负值抬升
    SIM2 = zeros(img_h, img_w, sim_frame_num);
    SIM3 = zeros(img_h, img_w, sim_frame_num);
    % 方向1 1-3通道
    [SIM2(:,1:3), SIM3(:,1:3)] = SubtractBg(SIM(:,1:3), MAX_WF(:,:,1));
    % 方向2 4-6通道
    [SIM2(:,4:6), SIM3(:,4:6)] = SubtractBg(SIM(:,4:6), MAX_WF(:,:,2));
    % 方向3 7-9通道
    [SIM2(:,7:9), SIM3(:,7:9)] = SubtractBg(SIM(:,7:9), MAX_WF(:,:,3));

    %% 3. 高斯高通滤波提取照明高频分量
    img_high = GetHighFreq(WF_uniform, gauss_D0);
    max_high = max(img_high, [], 'all');

    %% 4. 三种高频权重系数计算模式
    max_SIM3_all = max(SIM3, [], [1,2]);
    maxvalue1 = max(max_SIM3_all(:));
    mean_SIM3_all = mean(SIM3, [1,2]);
    meanvalue1 = mean(mean_SIM3_all(:));
    meanvalue2 = mean(img_high(:));
    maxvalue2 = max_high;

    ratio4 = maxvalue1 / maxvalue2;   % 最大值自适应权重
    ratio5 = meanvalue1 / meanvalue2; % 均值自适应权重

    % 根据选择模式确定最终叠加系数
    switch weight_mode
        case 1
            coeff = fixed_coeff;
        case 2
            coeff = ratio4;
        case 3
            coeff = ratio5;
    end

    %% 5. 高频融合 + 单通道归一化到0~50000
    Icombin  = zeros(img_h, img_w, sim_frame_num);
    Icombin2 = zeros(img_h, img_w, sim_frame_num);
    for ch = 1 : sim_frame_num
        % 叠加高频分量
        Icombin(:, :, ch) = SIM3(:, :, ch) + coeff * img_high;
        % 单帧线性归一化
        frame_min = min(Icombin(:, :, ch), [], 'all');
        frame_max = max(Icombin(:, :, ch), [], 'all');
        Icombin2(:, :, ch) = (Icombin(:, :, ch) - frame_min) / (frame_max - frame_min) * norm_max_val;
    end

    %% 6. 存入总输出矩阵
    slice_start = (k - 1) * sim_frame_num + 1;
    slice_end   = k * sim_frame_num;
    Isum2(:, :, slice_start : slice_end) = Icombin2;

    % 打印处理进度与当前权重系数
    fprintf('正在处理第 %d / %d 组，组号k2=%d，当前高频系数=%.4f\n', k, group_num, k2, coeff);
end
fprintf('所有分组处理完成，开始保存结果\n');

%% ===================== 分块输出tif堆叠 =====================
% 注意：原代码 Isum2(:,:,739:549) 切片起始大于结束，会报错，需修正区间
imwritestack(Isum2,    '\Result of 6P-5.tif');

%% ===================== 子函数1：背景相减，负值抬升 =====================
function [sub_res, shift_res] = SubtractBg(img_batch, wf_ref)
    [h, w, n] = size(img_batch);
    sub_res  = zeros(h, w, n);
    shift_res = zeros(h, w, n);
    
    % 强制将wf_ref缩放/裁剪到和单帧图像 h,w 完全一致
    wf_ref = imresize(wf_ref, [h,w]);
    wf_3d = repmat(wf_ref,1,1,n);
    
    for i = 1 : n
        sub_res(:, :, i) = wf_3d(:, :, i) - img_batch(:, :, i);
        min_val = min(sub_res(:, :, i), [], 'all');
        if min_val < 0
            offset = -floor(min_val);
            shift_res(:, :, i) = sub_res(:, :, i) + offset;
        else
            shift_res(:, :, i) = sub_res(:, :, i);
        end
    end
end

%% ===================== 子函数2：高斯高通提取高频 =====================
function high_img = GetHighFreq(img, D0)
    [h, w] = size(img);
    fft_raw = fft2(img);
    fft_shift = fftshift(fft_raw);

    [U, V] = meshgrid(-w/2 : w/2-1, -h/2 : h/2-1);
    D = sqrt(U.^2 + V.^2);
    gauss_low = exp(-(D.^2) / (2 * D0^2));

    fft_filter = fft_shift .* gauss_low;
    fft_ishift = ifftshift(fft_filter);
    low_comp = abs(ifft2(fft_ishift));

    high_img = img - low_comp;
    high_img(high_img < 0) = 0;
end