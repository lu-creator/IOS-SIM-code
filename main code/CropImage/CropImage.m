%--------------------------------------------------------------------------
% Title: 取图像中心区域
% Date: 20230611
% Author: WenJy
%--------------------------------------------------------------------------
addpath('./function_code/util/')
path = 'D:\03_TestData\GTL_SIM\20230615_SIM_Mask400\ROI2\';
name = 'Image.tif';
img = imreadstack(fullfile(path, name));

[sizex, sizey, sizez] = size(img);
ROI = min(sizex, sizey);

img_crop = img( floor(sizex/2)+1 - (floor(ROI/2)): floor(sizex/2) + (floor(ROI/2)),...
             floor(sizey/2)+1 - (floor(ROI/2)): floor(sizey/2) + (floor(ROI/2)), :);
imwritestack_16(img_crop, [path name(1:end-4) '_crop.tif']);