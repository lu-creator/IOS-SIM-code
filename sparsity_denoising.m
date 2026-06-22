% source code by Junchao Fan
addpath('./util')
pathname=handles.pathname;
filename=handles.filename;
image_stack_all=handles.image_stack;

mu=str2double(get(handles.MU_edit,'String'));
sigma=str2double(get(handles.sigma_edit,'String'));

Progressbar = waitbar(0, 'Sparsity denoising,please wait...');

%从维纳重建中导入数据
disp('Sparsity denoising,please wait...');
y = image_stack_all; % y=经过维纳重建之后的数据
%% initialization
iter_Bregman = 1e2;     %number of iteration
lamda = 1;              
gexiang=1;              
y=single(y);
tic
y_flag=size(y,3);
if y_flag<3
    sigma=0;
    y(:,:,end+1:end+(3-size(y,3)))=repmat(y(:,:,end),[1,1,3-size(y,3)]);
    msgbox('Number of data frame should be bigger than 3'); 
end
ymax=max(y(:));
y=y./ymax;
[sx,sy,sz] = size(y);
sizex=[sx,sy,sz] ;
x = zeros(sizex);                  %start point

z_gradient_zz(:,:,1)=1;
z_gradient_zz(:,:,2)=-2;
z_gradient_zz(:,:,3)=1;

z_gradient_xz(:,:,1)=[1,-1];
z_gradient_xz(:,:,2)=[-1,1];

z_gradient_yz(:,:,1)=[1;-1];
z_gradient_yz(:,:,2)=[-1;1];

%FFT of difference operator
% 对xx,xy,xz,yy,yz,zz方向的二次梯度求和,即海森约束
tmp_fft=fftn([1 -2 1],sizex).*conj(fftn([1 -2 1],sizex));
Fre_fft = tmp_fft;
tmp_fft=fftn([1 ;-2 ;1],sizex).*conj(fftn([1; -2 ;1],sizex));
Fre_fft=Fre_fft + tmp_fft;
tmp_fft=fftn(z_gradient_zz,sizex).*conj(fftn(z_gradient_zz,sizex));
Fre_fft=Fre_fft +(sigma^2)*tmp_fft;
tmp_fft=fftn([1 -1;-1 1],sizex).*conj(fftn([1 -1;-1 1],sizex));
Fre_fft=Fre_fft + 2 * tmp_fft;
tmp_fft=fftn(z_gradient_xz,sizex).*conj(fftn(z_gradient_xz,sizex));
Fre_fft=Fre_fft + 2 * (sigma)*tmp_fft;
tmp_fft= fftn(z_gradient_yz,sizex).*conj(fftn(z_gradient_yz,sizex));
Fre_fft=Fre_fft + 2 * (sigma)*tmp_fft;
clear  tmp_fft
divide = single((mu/lamda) + Fre_fft);
clear  Frefft

%% iteration
b1 = zeros(sizex,'single');
b2 = zeros(sizex,'single');
b3 = zeros(sizex,'single');
b4 = zeros(sizex,'single');
b5 = zeros(sizex,'single');
b6 = zeros(sizex,'single');
x = zeros(sizex,'int32');
frac = (mu/lamda)*(y); 
% 开始进行博格曼迭代
for ii = 1:iter_Bregman
%% renew x
        frac = fftn(frac);
        if ii>1
            x = real(ifftn(frac./divide));
        else
            x = real(ifftn(frac./(mu/lamda)));
        end

%% calculate the dirivative of x
%% renew d
% 'gexiang == 1' means anisotropic;'otherwise' means isotropic      
    frac = (mu/lamda)*(y); 
    u = back_diff(forward_diff(x,1,1),1,1); %求差
    signd = abs(u+b1)-1/lamda;
    signd(signd<0)=0;
    signd=signd.*sign(u+b1);
    d=signd;
    b1 = b1+(u-d);
    frac = frac+back_diff(forward_diff(d-b1,1,1),1,1);

    u = back_diff(forward_diff(x,1,2),1,2);
    signd = abs(u+b2)-1/lamda;
    signd(signd<0)=0;
    signd=signd.*sign(u+b2);
    d=signd;
    b2 = b2+(u-d);
    frac = frac+back_diff(forward_diff(d-b2,1,2),1,2);

    u = back_diff(forward_diff(x,1,3),1,3);
    signd = abs(u+b3)-1/lamda;
    signd(signd<0)=0;
    signd=signd.*sign(u+b3);
    d=signd;
    b3 = b3+(u-d);
    frac = frac+(sigma^2)*back_diff(forward_diff(d-b3,1,3),1,3);

    u = forward_diff(forward_diff(x,1,1),1,2);
    signd = abs(u+b4)-1/lamda;
    signd(signd<0)=0;
    signd=signd.*sign(u+b4);
    d=signd;
    b4 = b4+(u-d);
    frac = frac+ 2 * back_diff(back_diff(d-b4,1,2),1,1);

    u = forward_diff(forward_diff(x,1,1),1,3);
    signd = abs(u+b5)-1/lamda;
    signd(signd<0)=0;
    signd=signd.*sign(u+b5);
    d=signd;
    b5 = b5+(u-d);
    frac = frac+ 2 * (sigma)*back_diff(back_diff(d-b5,1,3),1,1);

    u = forward_diff(forward_diff(x,1,2),1,3);
    signd = abs(u+b6)-1/lamda;
    signd(signd<0)=0;
    signd=signd.*sign(u+b6);
    d=signd;
    b6 = b6+(u-d);
    frac = frac+ 2 * (sigma)*back_diff(back_diff(d-b6,1,3),1,2);
%     ii
    waitbar(ii/iter_Bregman , Progressbar, 'Sparsity denoising')
end
toc
x(x<0) = 0;
x=x(:,:,1:y_flag);
tif=x.*ymax;

imwritestack_16(tif, [pathname '\denoise-' filename]);

axes(handles.axes2);
imshow(tif(:,:,1),[]);


close(Progressbar);
disp('Sparsity denoise sim Successfully');
helpdlg('All Done');
