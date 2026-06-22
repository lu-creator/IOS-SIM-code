% 2020.7.24修改
% determine phase  增加显示输出 g_hist_output , g_hist_fitting_output ,xishu
function [c6, angle6, g_hist_output,g_hist_fitting_output]...
    =determine_phase (image_stack, zuobiaox, zuobiaoy, bgjie488, phase_matrix,...
    num_of_average, fc_ang, fc_con, wavelength, psf, n_phases, n_angles, Progressbar, wiener_sim_batch_flag)
%%
[height,width,zstack]=size(image_stack);
addpath('./util')
addpath('./TIF')
%% ============== 根据输入倍数对图像作t轴平均 ==========

% 批量处理标志初始化（避免未定义报错）
if exist('wiener_sim_batch_flag')
    wiener_sim_batch_flag = 0;
end

% 选取用于相位估计的图像子集（降噪，逻辑同determine_p_SQI）
if zstack >= num_of_average*9
    image_for_p=image_stack(:,:,1:num_of_average*9);
elseif  wiener_sim_batch_flag == 1
    num_of_average = floor(zstack/9);
    image_for_p=image_stack(:,:,1:num_of_average*9);
else    
    warndlg('The number of averaged frames should be smaller','warn','modal');
    return;
end

% 9组图像分别求平均（降噪，3相×3角）
image_for_p_average=zeros(height,width,9);

for i=1:1:(n_phases*n_angles)
    image_for_p_average(:,:,i)=sum(image_for_p(:,:,[i:(n_phases*n_angles):(n_phases*n_angles)*num_of_average]),3)./num_of_average;
end
image_for_p=image_for_p_average;

%%%============================================================ 如果p 长度大于180，则 fc_con 取 120 ======================
% 非正方形填充成正方形，计算p长度，自适应调整fc_con（p过长时增大滤波半径）,
max_h_w=max([height, width]);
zuobiaox1=zuobiaox*(height/max_h_w);
zuobiaoy1=zuobiaoy*(width/max_h_w);
p_length= floor(sum(((zuobiaox1-zuobiaox1(1,1)).^2+(zuobiaoy1-zuobiaoy1(1,1)).^2).^0.5)./(2*3));
if p_length>180
    fc_con=120;   % p过长→增大调制系数滤波半径
end
%%%============================================================  end   =========================
% 按图像尺寸缩放滤波半径
fc_ang = ceil(fc_ang*(max_h_w/512));
if wavelength==640
    fc_con = ceil(80*(max_h_w/512));
else
    fc_con = ceil(fc_con*(max_h_w/512));
end
% p坐标缩放（适配max_h_w尺寸）
zuobiaox_512=zuobiaox*(max_h_w/floor((zuobiaox(1,1)+zuobiaoy(1,1))/2));
zuobiaoy_512=zuobiaoy*(max_h_w/floor((zuobiaox(1,1)+zuobiaoy(1,1))/2));

%%  对OTF进行二值化、填0扩充处理
% 读入OTF
H_ang = psf; % 相位估计用OTF
H_con = H_ang;  % 调制系数估计用OTF

[k_x, k_y]=meshgrid(-(max_h_w)/2:(max_h_w)/2-1, -(max_h_w)/2:(max_h_w)/2-1);
k_r = sqrt(k_x.^2+k_y.^2);
indi_ang =  k_r > fc_ang ;  % 相位滤波：半径>fc_ang置0
indi_con =  k_r > fc_con ;  % 调制系数滤波：半径>fc_con置0
H_ang(indi_ang)=0;  %OTF大于限定范围部分置0
H_con(indi_con)=0;
H_ang=abs(H_ang);
H_con=abs(H_con);
%  OTF二值化（保留有效区域，忽略幅值）
H1_ang=H_ang;
H1_con=H_con;
H1_ang(H1_ang~=0)=1;%二值化
H1_con(H1_con~=0)=1;

%% 将图像扩展到512*512 ，将OTF扩展到1024*1024
%  图像频域转换（补0为max_h_w×max_h_w + 背景去除）
K_h = [height,width];
N_h = [max_h_w,max_h_w];
L_h = ceil((N_h-K_h) / 2);
v_h = colonvec(L_h+1, L_h+K_h);
hw = zeros(N_h);
DIbars=zeros(max_h_w,max_h_w,n_phases*n_angles);
for ii=1:1:(n_phases*n_angles)
    image_for_p(:,:,ii)=image_for_p(:,:,ii)-bgjie488; %减去背景
    hw(v_h{:})=image_for_p(:,:,ii); %
    DIbars(:,:,ii) = fftshift(fft2(ifftshift(hw))); % 傅里叶变换→频域
end

% 将OTF扩展成原来的两倍（避免频域混叠）
K_h = size(H1_ang);
N_h = 2*K_h;
L_h = ceil((N_h-K_h) / 2);
v_h = colonvec(L_h+1, L_h+K_h);
hw=zeros(N_h);
hw(v_h{:})=H_ang;
H_ang=hw;           % 相位OTF扩展
hw(v_h{:})=H_con;
H_con=hw;           % 调制系数OTF扩展
hw(v_h{:})=H1_ang;
H1_ang=hw;
hw(v_h{:})=H1_con;
H1_con=hw;

%%   分离高低频分量
% 初始化输出参数
c6=zeros(1,1,3*(n_phases-1));   % 6组调制系数（3角度×2高频）
angle6=zeros(1,1,3*(n_phases-1));   % 6组相位
% 中间变量初始化（频域分量存储）
replc6_con=zeros(2*max_h_w,2*max_h_w,(n_angles)*(n_phases-1));
replc6_ang=zeros(2*max_h_w,2*max_h_w,(n_angles)*(n_phases-1));
cm_con=zeros(2*max_h_w,2*max_h_w,(n_angles)*(n_phases-1));
cm_ang=zeros(2*max_h_w,2*max_h_w,(n_angles)*(n_phases-1));
R2_ang=zeros(2*max_h_w,2*max_h_w,(n_angles)*(n_phases-1));
R2_zhongxin_ang=zeros(2*max_h_w,2*max_h_w,(n_angles)*(n_phases-1));
sp = zeros(max_h_w,max_h_w,n_phases*n_angles);
temp_separated = zeros(max_h_w,max_h_w,n_phases);
% 相位矩阵逆矩阵（分离高低频分量）
inv_phase_matrix = inv(phase_matrix);
for itheta=1:n_angles
    for j = 1:n_phases
        for k = 1:n_phases
            temp_separated(:,:,k) = inv_phase_matrix(j,k).*DIbars(:,:,(itheta-1)*3+k);
            sp(:,:,(itheta-1)*3+j) = sp(:,:,(itheta-1)*3+j)+temp_separated(:,:,k);
            % figure,imagesc(abs(sp(:,:,(itheta-1)*3+j)));
        end
    end
end

%% 根据公式对高低频分量处理
% x=0:(2*max_h_w-1);
% y=(0:(2*max_h_w-1))';
% xx2=repmat(x,2*max_h_w,1);
% yy2=repmat(y,1,2*max_h_w);
% 生成2倍尺寸的坐标网格（-max_h_w ~ max_h_w-1）
[xx2,yy2] = meshgrid(-max_h_w:max_h_w-1, -max_h_w:max_h_w-1);  % 坐标原点与之前2D SIM的定义不一样

for spi=1:1:(n_angles)*(n_phases-1)   %1:1:6  6个高频分量（3角度×2高频）
    
    %  提取低频（0阶）和高频（±1阶）分量
    sp_center = sp(:,:,ceil(spi/2)*3-1);  % 低频分量
    sp_highfreq = sp(:,:,ceil(spi/2)+2*floor(spi/2));   % 高频分量
    
    %  扩展分量到2倍尺寸（匹配OTF尺寸）
    hw(v_h{:})=sp_highfreq;   % 拉伸到1024*1024的高频分量
    sp_highfreq=hw;
    hw(v_h{:})=sp_center;
    sp_center=hw;
    
    %利用频谱分布函数求解出来的坐标p设置pattern
    %  基于p坐标生成结构光相位模式（pattern）
    ky_test = 2*pi*(zuobiaox_512(spi+1+floor((spi-1)/2))-max_h_w)/(2*max_h_w);
    kx_test = 2*pi*(zuobiaoy_512(spi+1+floor((spi-1)/2))-max_h_w)/(2*max_h_w);
    pattern(:,:)=exp(1i*(kx_test*xx2+ky_test*yy2));
    
    %将pattern与OTF相乘，并二值化
    %  OTF与pattern卷积（频域移位，匹配结构光相位）
    replcH_test_ang(:,:) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(H1_ang))).*pattern(:,:))));
    replcH_test_con(:,:) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(H1_con))).*pattern(:,:))));
    % OTF二值化（保留有效区域）
    replcH_test_ang(abs(replcH_test_ang)>0.9)=1;
    replcH_test_ang(abs(replcH_test_ang)~=1)=0;
    replcH_test_con(abs(replcH_test_con)>0.9)=1;
    replcH_test_con(abs(replcH_test_con)~=1)=0;
    %  OTF与pattern卷积（保留幅值）
    replch_ang(:,:) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(H_ang))).*pattern(:,:))));
    replch_con(:,:) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(H_con))).*pattern(:,:))));
    replch_ang = replch_ang.*replcH_test_ang;  % 仅保留有效区域
    replch_con = replch_con.*replcH_test_con;
    
    % 将数据与pattern相乘，并求取低频与高频的重叠部分
     %  高频分量与pattern卷积（匹配结构光相位）
    replc_test(:,:) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(sp_highfreq))).*pattern(:,:))));
    % 滤波：仅保留OTF有效区域
    youhua_test_ang=replc_test.*replcH_test_ang.*H_ang;
    youhua_test_con=replc_test.*replcH_test_con.*H_con;
    %  计算低频/高频分量的重叠区域（核心：相位/调制系数的来源）
    overlap_ang=sp_center.*replch_ang;
    overlap_con=sp_center.*replch_con;
    %  计算相位/调制系数的原始分量（避免除以0）
    cm_con(:,:,spi)=youhua_test_con./(overlap_con+eps);  % 调制系数分量
    replc6_con(:,:,spi)=replch_con.*H_con;
    cm_ang(:,:,spi)=youhua_test_ang./(overlap_ang+eps);   % 相位分量
    replc6_ang(:,:,spi)=replch_ang.*H_ang;
    % R2_ang(:,:,spi)=youhuatest_ang;
    %  R2_zhongxin_ang(:,:,spi)=chongdie_ang;
end

% 提取相位（角度）和调制系数（幅值）
angcm=angle(cm_ang);  % 取相位 % 取复数值的相位（-π~π）
abscm=abs(cm_con);    % 取复数值的幅值（0~1）
% imwritestack((angcm),'angcm.tif');
% imwritestack((abscm),'abscm.tif');

% 对重叠部分拟合回归，得到系数
% 相位范围：-π~π，步长0.02；调制系数范围：0~0.6，步长0.02
f=-pi:0.02:pi;
ff=0:0.02:0.6;

%%====================  增加 =========================================
% 初始化直方图数组（输出用）
g_hist_output=zeros((n_angles)*(n_phases-1),length(f));
g_hist_fitting_output=zeros((n_angles)*(n_phases-1),length(f));
%%====================================================================

for ii=1:1:(n_angles)*(n_phases-1)   % 6组分量
    %  提取有效区域的相位/调制系数分量（去除0值区域）
    a_ang=replc6_ang(:,:,ii);
    a_con=replc6_con(:,:,ii);
    b_ang=a_ang(:);
    b_con=a_con(:);
    b_ang(b_ang~=0)=1;
    b_con(b_con~=0)=1;    % 二值化，标记有效区域
    c=angcm(:,:,ii);
    cc=abscm(:,:,ii);
    d=c(:);
    dd=cc(:);
    b_ang(:,2)=d;
    b_con(:,2)=dd;
    b_ang((b_ang(:,1)==0),:)=[] ;    % 仅保留有效区域
    b_con((b_con(:,1)==0),:)=[] ;
    e=b_ang(:,2);
    ee=b_con(:,2);      % 有效区域的相位/调制系数值

    e=e';
    ee=ee';
    %  相位直方图统计（-π~π）
    g=histc(e,f); % 取直方图,输出
    
    %=====================================延拓初相===============================
    % 相位延拓：解决相位跨-π/π边界的问题（直方图拼接）
    num = numel(g);
    gyantou = [g(1:end-1) g(end-1) g(1:end-1) g(end-1)];         % g的最后一个值0不要
    if sum(g) == 0
        Index=1;
    else        
        [value, Index] = min(g(1:end-1));                           % 取一个锋，并记录移动位置 % 找到相位边界（最小值位置）
        gyantou = gyantou(Index:Index+num-1);                       % 移位延拓
        clear g
        g = gyantou;
    end
 
    %%================================================== 增加输出 =================
    g_hist_output(ii,:)=g;     % 保存原始直方图
    %%==================================================end =======================
    %  调制系数直方图统计（0~0.6）
    gg=histc(ee,ff);
    
    % 利用emd拟合回归
    %  EMD拟合降噪（经验模态分解，去除高频噪声）
    imf=emd(g);      % 相位直方图EMD分解
    imf2=emd(gg);    % 调制系数直方图EMD分解
    % 相位拟合：根据幅值选择EMD分量求和（降噪）
    if max(g)<50
        g=sum(imf(5:end,:),1);   % 低幅值→取更高阶分量
    else
        g=sum(imf(4:end,:),1);   % 高幅值→取低阶分量
    end
    if sum(g) == 0
        g = zeros(1, length(f));   % 保存拟合后直方图
    end
    %%================================================== 增加输出 =================
    g_hist_fitting_output(ii,:)=g;
    %%==================================================end =======================
    % 调制系数拟合：所有EMD分量求和
    gg=sum(imf2(1:end,:),1);

    %  找直方图峰值（相位/调制系数的最终估计值）
    h=find(g==max(g));  % 相位峰值位置
    if max(g) == 0
        h = 0;
    end
    hh=(find(gg==max(gg)));     % 调制系数峰值位置
    
    %  相位值转换（还原延拓的偏移）
    if h > num-Index+1                % 根据移动位置，对应到原本的0值位置
        angle6(:,:,ii)=-pi+0.02*(h-(num-Index+1));
    else 
        angle6(:,:,ii)=-pi+0.02*(h+Index-1);
    end
    %  调制系数值计算（峰值位置的平均值）
    c6(:,:,ii)=0.02*mean(hh);
    %  regress_R2;
end
% 关闭进度条
if  Progressbar ~= 1  % 不显示进度条
    close(Progressbar);
end
