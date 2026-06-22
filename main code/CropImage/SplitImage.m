%--------------------------------------------------------------------------
% Title: 将图像按照波长分离出来
% Date: 20230611
% Author: WenJy
%--------------------------------------------------------------------------
addpath('./function_code/util/')
path = 'D:\03_TestData\GTL_SIM\20230615_SIM_Mask400\ROI2\';
name = 'Image_crop.tif';
ColorNumber = 3;
nAngles = 3;
nPhases = 3;
Img = imreadstack(fullfile(path, name));
[SizeX, SizeY, SizeZ] = size(Img);
NumZ = SizeZ / (ColorNumber*nAngles*nPhases);
Img488 = zeros(SizeX, SizeY, NumZ);
Img561 = zeros(SizeX, SizeY, NumZ);
Img637 = zeros(SizeX, SizeY, NumZ);
for iZ = 1:NumZ
    Img488(:, :, (iZ-1)*nAngles*nPhases+1:iZ*nAngles*nPhases) = Img(:, :, (iZ-1)*nAngles*nPhases*ColorNumber+1:(iZ-1)*nAngles*nPhases*ColorNumber+9);
    Img561(:, :, (iZ-1)*nAngles*nPhases+1:iZ*nAngles*nPhases) = Img(:, :, (iZ-1)*nAngles*nPhases*ColorNumber+10:(iZ-1)*nAngles*nPhases*ColorNumber+18);
    Img637(:, :, (iZ-1)*nAngles*nPhases+1:iZ*nAngles*nPhases) = Img(:, :, (iZ-1)*nAngles*nPhases*ColorNumber+19:(iZ-1)*nAngles*nPhases*ColorNumber+27);
end
imwritestack_16(Img488, [path '488.tif']);
imwritestack_16(Img561, [path '561.tif']);
imwritestack_16(Img637, [path '637.tif']);