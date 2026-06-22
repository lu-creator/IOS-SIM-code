%--------------------------------------------------------------------------
% Title: 带重叠裁图
% Date: 20230616
% Author: WenJy
%--------------------------------------------------------------------------
addpath('./function_code/util/')
Path = 'D:\03_TestData\GTL_SIM\20230615_SIM_Mask400\ROI2\';
SavePath = 'D:\03_TestData\GTL_SIM\20230615_SIM_Mask400\ROI2\ROI_512\';
Name = '488.tif';
if ~exist(SavePath, 'dir')
    mkdir(SavePath)
end
Img = imreadstack(fullfile(Path, Name));
[SizeX, ~, SizeZ] = size(Img);
ROI = 512;
DivideNum = ceil(SizeX/ROI);
Overlap = floor((ROI*DivideNum - SizeX) / (DivideNum-1));
img_crop = zeros(ROI, ROI, SizeZ);
for iX = 1:DivideNum
    for iY = 1:DivideNum
        if (iX-1)*ROI + 1 - (iX-1)*Overlap > 0
            StartCoordinateX = (iX-1)*ROI + 1 - (iX-1)*Overlap;
        else
            StartCoordinateX = 1;
        end
        if iX*ROI - (iX-1)*Overlap < SizeX
            EndCoordinateX = iX*ROI - (iX-1)*Overlap;
        else
            EndCoordinateX = SizeX;
        end
        if (iY-1)*ROI + 1 - (iY-1)*Overlap > 0
            StartCoordinateY = (iY-1)*ROI + 1 - (iY-1)*Overlap;
        else
            StartCoordinateY = 1;
        end
        if iY*ROI - (iY-1)*Overlap < SizeX
            EndCoordinateY = iY*ROI - (iY-1)*Overlap;
        else
            EndCoordinateY = SizeX;
        end
        img_crop(:,:,:) = Img(StartCoordinateX: EndCoordinateX,StartCoordinateY: EndCoordinateY, :);
        imwritestack_16(img_crop, [SavePath Name(1:end-4) '_' num2str(iX) '_' num2str(iY) '.tif']);
    end
end