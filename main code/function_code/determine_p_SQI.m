function [phase_matrix,zuobiaox,zuobiaoy, peakmax]=...
   determine_p_SQI(image_stack, psf, sp_rate, num_of_average, max_h_w, fre_length_half, seek_range, init_position ,...
    n_phases, n_angles, Progressbar, wiener_sim_batch_flag)
%=================================================================
[height, width, zstack]=size(image_stack);
% addpath('./Interpolation')
addpath('./util')
addpath('./TIF')
%% ========= 根据输入倍数对图像求平均，并将参数拉伸到512*512  ============================================
%image_for_p 为用于求p的图像子集
% 校验批量处理标志是否存在（避免未定义报错）
if exist('wiener_sim_batch_flag','var')==0
    wiener_sim_batch_flag = 0;
end
% 选取用于估计p的图像子集（仅用前num_of_average×9帧，降低噪声）
if zstack >= num_of_average*9
    image_for_p=image_stack(:,:,1:num_of_average*9);
elseif  wiener_sim_batch_flag == 1
    num_of_average = floor(zstack/9);
    image_for_p=image_stack(:,:,1:num_of_average*9);
else
% 帧数不足时提示并终止（避免后续计算出错）
    if  Progressbar ~= 1  % 不显示进度条
        close(Progressbar);
    end
    warndlg('The number of averaged frames should be smaller','warn','modal');
    return;
end

H = psf;

% 初始化平均图像矩阵（9帧：3相×3角）
image_for_p_average = zeros(height,width,(n_phases*n_angles));

% 按图像尺寸缩放频域参数（适配非512×512尺寸）
fre_length_half = ceil(fre_length_half*(max_h_w/512));
init_position = ceil(init_position*(max_h_w/512));
seek_range = ceil(seek_range*(max_h_w/512));

% 构建相位矩阵（488nm波长，SIM相位分离核心）
phase_matrix= [-1 1 -1;
    -exp(1i*2*pi*(sp_rate(1)/sum(sp_rate))) 1  -exp(-1i*2*pi*(sp_rate(1)/sum(sp_rate)));
    -exp(1i*2*pi*((sp_rate(1)+sp_rate(2))/sum(sp_rate))) 1  -exp(-1i*2*pi*((sp_rate(1)+sp_rate(2))/sum(sp_rate)));];%488

for i=1:1:(n_phases*n_angles)%average frames
    image_for_p_average(:,:,i)=sum(image_for_p(:,:,[i:(n_phases*n_angles):(n_phases*n_angles)*num_of_average]),3)./num_of_average;
end

image_for_p=image_for_p_average;%观测图像

%% ============ =================
%尺寸适配：任意尺寸→max_h_w×max_h_w（补0为正方形）
K_h = [height,width];
N_h = [max_h_w,max_h_w];
L_h = ceil((N_h-K_h) / 2);
v_h = colonvec(L_h+1, L_h+K_h);
hw=zeros(N_h);

DIbars=zeros(max_h_w,max_h_w,n_phases*n_angles);
for ii=1:1:(n_phases*n_angles)
    hw(v_h{:})=image_for_p(:,:,ii);   %原始图像填充到正方形中心，其他区域为0
    % figure,imagesc(hw(v_h{:}));
    DIbars(:,:,ii) = fftshift(fft2(ifftshift(hw))); %%% 傅里叶变换→频域
    % figure,imagesc(abs(log(DIbars(:,:,ii))));
end

% %令PSF中半径大于FC的高频值为0 OTF滤波：去除半径>fre_length_half的高频噪声
[k_x, k_y]=meshgrid(-(max_h_w)/2:(max_h_w)/2-1, -(max_h_w)/2:(max_h_w)/2-1);
k_r = sqrt(k_x.^2+k_y.^2);
H(k_r > fre_length_half )=0;
H=abs(H);
% figure,imagesc(H);

%% =====  原始图像频谱与OTF相乘，并进行相位分离==========
H1=H; %PSF
H1(H1~=0)=1;%二值化，保证像素值大小不变
H2=H1;
H9=repmat(H1,[1 1 (n_phases*n_angles)]);%9个PSF
DIbars = H9 .* DIbars;  %将外圈高频去除后的后的9个PSF
inv_phase_matrix = inv(phase_matrix);
temp_separated = zeros(max_h_w,max_h_w,n_phases);
sp = zeros(max_h_w,max_h_w,n_phases*n_angles);

% OTF尺寸扩展（2倍），用于后续互相关
K_h = size(H2);%扩展PSF
N_h = 2*K_h;
L_h = ceil((N_h-K_h) / 2);
v_h = colonvec(L_h+1, L_h+K_h);
hw=zeros(N_h);
hw(v_h{:})=H;
H=hw;
hw(v_h{:})=H1;
H1=hw;

% 相位分离：提取每个角度的低频/高频分量
for itheta=1:n_angles
    for j = 1:n_phases
        for k = 1:n_phases
            temp_separated(:,:,k) = inv_phase_matrix(j,k).*DIbars(:,:,(itheta-1)*n_phases+k);
            sp(:,:,(itheta-1)*n_phases+j) = sp(:,:,(itheta-1)*n_phases+j)+temp_separated(:,:,k);
        end
        
    end
end
sp=sp./(abs(sp)+eps);% 9个分量归一化，忽略幅值信息，保留相位信息

%%  ======计算低频与高频分量的互相关系数，根据最大值寻找P的坐标，再进行亚像素搜索====
% 设初始值
zuobiaox(1:(n_phases*n_angles),1)=max_h_w;
zuobiaoy(1:(n_phases*n_angles),1)=max_h_w;

% nihe = zeros(1023,1023,6);
nihe = zeros(2*height-1, 2*width-1, 6);
sp = sp .* H9; %再次应用OTF滤波

% 遍历6个高频分量（3角度×2个高频）
for spi=1:2:(n_angles)*(n_phases-1) %1：2：6
    sp_center = sp(:,:,ceil(spi/2)*n_phases-1);%1个低频分量，0阶
    sp_highfreq = sp(:,:,ceil(spi/2)+2*floor(spi/2));%1个高频分量，-1阶

    % OTF反转，计算互相关系数（筛选高相关区域）
    H_zuan = H2(end:-1:1,end:-1:1);%对OTF进行反转
    coef=dft(H2,H_zuan);%PSF互相关系数
    coef_i=coef;
    coef_i(coef_i<0.9)=0; % 保留相关系数>0.9的区域
    coef_i(coef_i~=0)=1;

    % 高频分量共轭反转，与低频分量互相关
    sp_tmp=conj(sp_highfreq);%某个分离分量做互相关
    sp_tmp=sp_tmp(end:-1:1,end:-1:1);
    result=dft(sp_center,sp_tmp);%低频分量和高频分量的互相关结果

    result=result.*coef_i;%保留相关系数较高部分
    fitting=abs(result./(coef+eps));

    % 限定环形搜索范围（init_position±seek_range）
    [k_x, k_y]=meshgrid(-(2*max_h_w)/2+1:(2*max_h_w)/2-1, -(2*max_h_w)/2+1:(2*max_h_w)/2-1);
    k_r = sqrt(k_x.^2+k_y.^2);
    % figure,imagesc(k_r);
    indi =  ((k_r < (init_position-seek_range))|(k_r > (init_position+seek_range))) ; %限定一个环的范围
    fitting(indi)=0;  % 超出范围置0，缩小搜索范围
    % h_fig = figure;
    % imagesc(fitting);
    % print(h_fig, '-dtiff', '-r300', [pathname_superior '\结果reconstruction Wiener sim\'  num2str(iframe), 'frame_fitting', num2str(iframe), 'frame-' num2str(ii_polt), '.png']);

    % 亚像素插值找峰值坐标（精度0.001像素）
    method = 3;
    tol = 0.001;
    [max_x, max_y] = Interpolation2D(fitting, method, tol, spi);
    
    nihe(:,:,spi) = fitting;
    peakmax(spi) = max(fitting(:));  % 记录峰值强度

    % 赋值峰值坐标（+1阶和-1阶对称）
    zuobiaox(spi+1+floor((spi-1)/2),:)=max_x;
    zuobiaoy(spi+1+floor((spi-1)/2),:)=max_y;
    zuobiaox(spi+2+floor((spi-1)/2),:)=2*max_h_w-max_x;
    zuobiaoy(spi+2+floor((spi-1)/2),:)=2*max_h_w-max_y;

    % 更新进度条
    if  Progressbar ~= 1  % 不显示进度条
        waitbar(spi/((n_angles)*(n_phases-1)), Progressbar, 'determined P ...');
    end
end
% imwritestack(nihe,'nihe.tif')
if  Progressbar ~= 1  % 不显示进度条
    waitbar(1, Progressbar, 'determine p Done');
end