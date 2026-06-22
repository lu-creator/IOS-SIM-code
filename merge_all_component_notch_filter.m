function [tirff,drr,tirffF1]=merge_all_component_notch_filter(image_stack, c6, angle6, zuobiaox, zuobiaoy, fre_length_half,  max_h_w ,wiener_para,...
    psf, bgjie488, sp_rate, n_phases, n_angles, notch_standard,Progressbar,...
    PixelSize,isBackgroundRemove,BackgroundRemoveA,BackgroundRemoveB,pathname_superior,filename)
%%
if  Progressbar ~= 1  % 不显示进度条
    waitbar(0, Progressbar, 'Wiener Merge....');
end
addpath('./util')
addpath('./TIF')
[height, width, zstack] = size(image_stack);
%读入OTF，并拉伸
%     [otfx,~,~] = size(imreadstack(deconv_otfname));
[otfx,~,~] = size(psf);
zuobiaox=zuobiaox*(otfx/max_h_w);
zuobiaoy=zuobiaoy*(otfx/max_h_w);
max_h_w=otfx;
%生成结构光时候的调制系数
xishu=[1,((1/c6(:,:,1))+(1/c6(:,:,2)))/2,((1/c6(:,:,1))+(1/c6(:,:,2)))/2,...
       1,((1/c6(:,:,3))+(1/c6(:,:,4)))/2,((1/c6(:,:,3))+(1/c6(:,:,4)))/2,...
       1,((1/c6(:,:,5))+(1/c6(:,:,6)))/2,((1/c6(:,:,5))+(1/c6(:,:,6)))/2];
% xishu = [1, (c6(:,:,1) + c6(:,:,2))/2, (c6(:,:,1) + c6(:,:,2))/2,...
%          1, (c6(:,:,3) + c6(:,:,4))/2, (c6(:,:,3) + c6(:,:,4))/2,...
%          1, (c6(:,:,5) + c6(:,:,6))/2, (c6(:,:,5) + c6(:,:,6))/2];
fre_length_half = ceil(fre_length_half*(max_h_w/512)); % 可能达到的maximum spatial frequency
plong= floor(sum(((zuobiaox-zuobiaox(1,1)).^2+(zuobiaoy-zuobiaoy(1,1)).^2).^0.5)./(2*n_angles));
p_out=zeros(9,1);
for ip=1:9
    if ip~=1||ip~=4||ip~=7
        p_out(ip,1)=    ((zuobiaox(ip,1)-zuobiaox(1,1)).^2+(zuobiaoy(ip,1)-zuobiaoy(1,1)).^2).^0.5;
    end
end
p_out
%调制深度
deph1= sign(angle6(:,:,1))*(abs(angle6(:,:,1))+abs(angle6(:,:,2)))*0.5;
deph2= sign(angle6(:,:,3))*(abs(angle6(:,:,3))+abs(angle6(:,:,4)))*0.5;
deph3= sign(angle6(:,:,5))*(abs(angle6(:,:,5))+abs(angle6(:,:,6)))*0.5;
image_512=zeros(max_h_w,max_h_w);
DIbar = zeros(max_h_w,max_h_w,(n_phases*n_angles));
retirff = zeros(2*max_h_w,2*max_h_w,(n_phases*n_angles));
spsim = zeros((2*max_h_w),(2*max_h_w),n_phases*n_angles);
replcHtest = zeros((2*max_h_w),(2*max_h_w),(n_phases*n_angles));
replch = zeros((2*max_h_w),(2*max_h_w),(n_phases*n_angles));
tmprc1 = zeros((2*max_h_w),(2*max_h_w),(n_phases*n_angles));
pattern = zeros((2*max_h_w),(2*max_h_w),(n_phases*n_angles));
% 截取范围
[k_x, k_y]=meshgrid(-(max_h_w)/2:(max_h_w)/2-1, -(max_h_w)/2:(max_h_w)/2-1);
k_r = sqrt(k_x.^2+k_y.^2);
indi =  k_r > fre_length_half ;
jiequ=ones(max_h_w,max_h_w);
jiequ(indi) = 0;
jiequ9=repmat(jiequ,[1,1,(n_phases*n_angles)]);

%% 读入PSF，与pattern相乘，结果二值化
%     psf = imreadstack(deconv_otfname);
H = psf;
H=H.*jiequ;
H=H./max(H(:));
H1=H;
H1(H1~=0)=1;
K_h = size(psf);
N_h = 2*K_h;
L_h = ceil((N_h-K_h) / 2);
v_h = colonvec(L_h+1, L_h+K_h);
hw=zeros(N_h);
hw(v_h{:})=H;
Hk=hw;
hw(v_h{:})=H1;
H1=hw;
x=0:(2*max_h_w-1);
y=(0:(2*max_h_w-1))';
xx2=repmat(x,2*max_h_w,1);
yy2=repmat(y,1,2*max_h_w);
clear hw N_h K_h L_h v_h
for ii=1:1:(n_phases*n_angles)
    kytest = 2*pi*(zuobiaox(ii,:)-max_h_w)/(2*max_h_w);
    kxtest = 2*pi*(zuobiaoy(ii,:)-max_h_w)/(2*max_h_w);
    pattern(:,:,ii)=exp(1i*(kxtest*xx2+kytest*yy2));
    replcHtest(:,:,ii) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(H1))).*pattern(:,:,ii))));
    replch(:,:,ii) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(Hk))).*pattern(:,:,ii))));
end
replcHtest(abs(replcHtest)>0.9)=1;
replcHtest(abs(replcHtest)~=1)=0;
replch= replch.*replcHtest;
re=replch;
absre=abs(re);
absre(absre~=0)=1;
re=re.*absre;
re(re==0)=10000000000000000000;
re=re./abs(re);
reh=abs(replch);
hs = sum(abs(reh(:,:,:)).^2,3);
reh=repmat(reh,[1 1 2]);
%限定重构后频谱的最大范围
[k_x, k_y]=meshgrid(-(2*max_h_w)/2:(2*max_h_w)/2-1, -(2*max_h_w)/2:(2*max_h_w)/2-1);
k_r = sqrt(k_x.^2+k_y.^2);
k_max = plong+fre_length_half;
%截止函数
bhs = cos(pi*k_r/(2*k_max));
indi = find( k_r > k_max );
bhs(indi) = 0;
clear H1 H2 Hk absre;
%% 计算3个相位矩阵
phi1tmp=linspace(0+deph1,2*pi+deph1,sum(sp_rate)+1);
phi1(1)=phi1tmp(1);
phi1(2)=phi1tmp(1+sp_rate(1));
phi1(3)=phi1tmp(1+sp_rate(1)+sp_rate(2));
phi2tmp=linspace(0+deph2,2*pi+deph2,sum(sp_rate)+1);
phi2(1)=phi2tmp(1);
phi2(2)=phi2tmp(1+sp_rate(1));
phi2(3)=phi2tmp(1+sp_rate(1)+sp_rate(2));
phi3tmp=linspace(0+deph3,2*pi+deph3,sum(sp_rate)+1);
phi3(1)=phi3tmp(1);
phi3(2)=phi3tmp(1+sp_rate(1));
phi3(3)=phi3tmp(1+sp_rate(1)+sp_rate(2));
phase_matrix1 = [1 exp(1i*phi1(1)) exp(-1i*phi1(1));1 exp(1i*phi1(2)) exp(-1i*phi1(2));1 exp(1i*phi1(3)) exp(-1i*phi1(3));];
phase_matrix2 = [1 exp(1i*phi2(1)) exp(-1i*phi2(1));1 exp(1i*phi2(2)) exp(-1i*phi2(2));1 exp(1i*phi2(3)) exp(-1i*phi2(3));];
phase_matrix3 = [1 exp(1i*phi3(1)) exp(-1i*phi3(1));1 exp(1i*phi3(2)) exp(-1i*phi3(2));1 exp(1i*phi3(3)) exp(-1i*phi3(3));];
inv_phase_matrix1 = inv(phase_matrix1);
inv_phase_matrix2 = inv(phase_matrix2);
inv_phase_matrix3 = inv(phase_matrix3);
inv_phase_matrix(:,:,1) = inv_phase_matrix1;
inv_phase_matrix(:,:,2) = inv_phase_matrix2;
inv_phase_matrix(:,:,3) = inv_phase_matrix3;
%%
padsize=0;
x = 1:(width+2*padsize);
y = (1:(height+2*padsize))';
sig=0.25;
mask = repmat(sigmoid(sig*(x-padsize)) - sigmoid(sig*(x-width-padsize-1)), height+2*padsize, 1) .* repmat(sigmoid(sig*(y-padsize)) - sigmoid(sig*(y-height-padsize-1)), 1, width+2*padsize);
mask9=repmat(mask.^3,[1 1 (n_phases*n_angles)]);
K_h2 = [max_h_w,max_h_w];
N_h2 = 2*K_h2;
L_h2 = ceil((N_h2-K_h2) / 2);
v_h2 = colonvec(L_h2+1, L_h2+K_h2);
hw2=zeros(N_h2);
% HiFi-SIM的滤波去背景方法
if isBackgroundRemove==1
    a = BackgroundRemoveA;
    b = BackgroundRemoveB;
    gs = @(a, b, k) 1 - a.*exp(- (power(k,2))./power(b,2) );   % 衰减OTF的高斯
    [mm, nn, ~] = size(image_stack);
    
    [k_m, k_n]=meshgrid(-mm : mm-1, -nn: nn-1);
    OneArray = ones(2*mm,2*nn);
    Pixel_Size = PixelSize*10^(-3);
    for ii=1:1:9               % 利用前面求得的坐标位置来生成高斯
        kk = sqrt((k_m-(zuobiaoy(ii)-mm)).^2+(k_n-(zuobiaox(ii)-nn)).^2);
        kk_transf = kk./(mm*Pixel_Size);
        if (ii == 1) || (ii == 4) || (ii == 7)  % 0频
            gs9_1(:,:,ii) = OneArray;
        else
            gs9_1(:,:,ii)=  gs(a/1.05, 0.5*b, kk_transf);
        end
    end
    hsf = conj(reh).*reh;         % 前面每个OTF分量 的 模平方
    for t1 = 1:n_phases*n_angles  % 第一步优化的分母
        fenmu1(:,:,t1) = gs9_1(:,:,t1).*hsf(:,:,t1);
    end
    fenmu1 = sum(fenmu1, 3);
    for iii=1:1:9        % 移动高斯  +p -p 将gs0平移后得到gs9
        kk = sqrt((k_m-(zuobiaoy(iii)-mm)).^2+(k_n-(zuobiaox(iii)-nn)).^2);
        kk_transf = kk./(mm*Pixel_Size);
        gs9(:,:,iii)= gs(a, 0.5*b, kk_transf);
    end   
end
%% 每9张合成1张图像
tirff = zeros(2*height,2*width,zstack/9,'single');
drr = zeros(2*height,2*width,zstack/9,'single');
% tic
for iir=1:1:(zstack/9)   
    % 对数据进行傅里叶变化，求取频谱
    D=image_stack(:,:,(1+9*(iir-1)):1:((1+9*(iir-1))+8));
    D=D-repmat(bgjie488,[1,1,n_phases*n_angles]);
    for beishui=1:1:9
        fdd_an(:,:,beishui)=sum(D(:,:,[beishui:9:9]),3);
    end
    D=fdd_an;
    weights =mean(mean(double(D)));
    weights = mean(weights)./weights;
    D=D.*mask9;  
    K_h = [size(D,1),size(D,2)];
    N_h = [max_h_w,max_h_w];
    L_h = ceil((N_h-K_h) / 2);
    v_h = colonvec(L_h+1, L_h+K_h);
    hw=zeros(N_h);
    for I=1:(n_phases*n_angles)
        D(:,:,I) = D(:,:,I) .* weights(1,1,I);
        hw(v_h{:})=D(:,:,I);
        image_512(:,:,I)=hw;
        DIbar(:,:,I) = fftshift(fft2(ifftshift(image_512(:,:,I))));
    end   
    % 频谱分离
    sp = zeros(max_h_w,max_h_w,n_phases*n_angles);
    sp1 = zeros(max_h_w,max_h_w,n_phases*n_angles);
    for itheta=1:n_angles
        for j = 1:n_phases
            temp_separated = zeros(max_h_w,max_h_w,n_phases);
            for k = 1:n_phases
                temp_separated(:,:,k) = inv_phase_matrix(j,k,itheta).*DIbar(:,:,(itheta-1)*3+k); %%%%% point
                sp1(:,:,(itheta-1)*3+j) = sp1(:,:,(itheta-1)*3+j)+temp_separated(:,:,k);
            end
        end
    end
    %% 增加陷波滤波
    if notch_standard==0
        sp=sp1;
    else
        fc_thred=200;
        [k_x, k_y]=meshgrid(-(max_h_w)/2:(max_h_w)/2-1, -(max_h_w)/2:(max_h_w)/2-1);
        k_r = sqrt(k_x.^2+k_y.^2);
        indi =  k_r > fc_thred ;
        % notch_standard=70;  %标准差
        notch_filter=exp((-k_x.^2-k_y.^2)/notch_standard.^2);
        notch_filter(indi)=0;
        %
        for spi=1:1:9
            %第1,4,7是零频，2,3,5,6,8,9是正负1频
            if spi~=1 && spi~=4 &&spi~=7
                sp_high = sp1(:,:,spi);
                sp_high=sp_high.*(1-notch_filter);
                sp(:,:,spi)=sp_high;
            else
                sp(:,:,spi)=sp1(:,:,spi);
            end
        end       
    end  
    %%
    sp = sp.*jiequ9; %乘上截止函数   
    % 将高低频分量移动到合适位置
    for ii=1:1:(n_phases*n_angles)
        hw2(v_h2{:}) = sp(:,:,ii);
        spsim(:,:,ii) = hw2;
        retirff(:,:,ii) = fftshift(fft2(ifftshift(fftshift(ifft2(ifftshift(spsim(:,:,ii)))).*pattern(:,:,ii))));
    end
    % 将高低频分量组合
    spttH = retirff.*replcHtest;
    retirff = spttH./(re);
    for t = 1:n_phases*n_angles
        tmprc1(:,:,t) =   (xishu(t).*retirff(:,:,t).*(conj(reh(:,:,t))))./ ( hs + .005*length(itheta)*(wiener_para)^2);
    end
    dr = sum(tmprc1,3);
    drr(:,:,iir) = dr.*bhs; %频谱
    fimage = fftshift(ifft2(ifftshift(drr(:,:,iir))));
    tirff(:,:,iir) = fimage((end/2)+1-(height):(end/2)+(height),(end/2)+1-(width):(end/2)+(width));
    % HiFi 去背景
    if isBackgroundRemove==1
        for t = 1:n_phases*n_angles
            tmprcf1(:,:,t) = xishu(t).*retirff(:,:,t).*conj(reh(:,:,t)).*gs9(:,:,t)./ (fenmu1 + .005*length(itheta)*(wiener_para)^2);
        end
        drF1 = sum(tmprcf1,3);
        drrF1 = drF1.*bhs; %频谱
        fimageF1 = fftshift(ifft2(ifftshift(drrF1)));
        tirffF1(:,:,iir) = real(fimageF1((end/2)+1-(height):(end/2)+(height),(end/2)+1-(width):(end/2)+(width)));        
    end
end
% toc
if isBackgroundRemove==1
    tirffF1(tirffF1<0) = 0;
%     imwritestack_16(tirffF1, [pathname_superior '\结果reconstruction Wiener sim\Wiener' filename(1:end-4)  '-BR.tif']);
end
tirff(tirff<0)=0;
disp('Wiener reconstruction Successfully');
if  Progressbar ~= 1  % 不显示进度条
    close(Progressbar);
end