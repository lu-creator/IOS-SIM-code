%--------------------------------------------------------------------------
% Title: 将ROI拼接回原图
% Date: 20230616
% Author: WenJy
%--------------------------------------------------------------------------
addpath('../function_code/util/')
Path = 'D:\03_TestData\GTL_SIM\20230615_SIM_Mask400\ROI2\ROI_512\结果reconstruction Wiener sim\';
SavePath = 'D:\03_TestData\GTL_SIM\20230615_SIM_Mask400\ROI2\ROI_512\结果reconstruction Wiener sim\';
Name = 'Wiener488';
ParamStr = '_wn6_NF1-10_BG1-0.8-1';
if ~exist(SavePath, 'dir')
    mkdir(SavePath)
end
CropROI = 512;   %1024
DivideNum = 6;   %3
Overlap = 96;   %240
ImgROI = CropROI*DivideNum - (DivideNum-1)*Overlap;
ImgInfo = imfinfo([Path Name '_1_1' ParamStr '.tif']);
NumZ = length(ImgInfo);
ImgROI_x2 = ImgROI*2;
CropROI_x2 = CropROI*2;
Overlap_x2 = Overlap*2;
WienerImg = zeros(ImgROI_x2, ImgROI_x2, NumZ); 
for iX = 1:DivideNum
    for iY = 1:DivideNum
        ImgName = [Name '_' num2str(iX) '_' num2str(iY) ParamStr '.tif'];
        ImgCrop = imreadstack(fullfile(Path, ImgName));
        if iX > 1
            StartCoordinateX = (iX-1)*CropROI_x2 + 1 - (iX-1)*Overlap_x2 + Overlap;
            ROIStartCoordinateX = Overlap + 1;
        else
            StartCoordinateX = 1;
            ROIStartCoordinateX = 1;
        end
        if iX < DivideNum
            EndCoordinateX = iX*CropROI_x2 - (iX-1)*Overlap_x2 - Overlap;
            ROIEndCoordinateX = CropROI_x2 - Overlap;
        else
            EndCoordinateX = ImgROI_x2;
            ROIEndCoordinateX = CropROI_x2;
        end
        if iY > 1
            StartCoordinateY = (iY-1)*CropROI_x2 + 1 - (iY-1)*Overlap_x2 + Overlap;
            ROIStartCoordinateY = Overlap + 1;
        else
            StartCoordinateY = 1;
            ROIStartCoordinateY = 1;
        end
        if iY < DivideNum
            EndCoordinateY = iY*CropROI_x2 - (iY-1)*Overlap_x2 - Overlap;
            ROIEndCoordinateY = CropROI_x2 - Overlap;
        else
            EndCoordinateY = ImgROI_x2;
            ROIEndCoordinateY = CropROI_x2;
        end
        Img(StartCoordinateX:EndCoordinateX,StartCoordinateY:EndCoordinateY, :) = ImgCrop(....
            ROIStartCoordinateX:ROIEndCoordinateX,ROIStartCoordinateY:ROIEndCoordinateY,:);        
    end
end
imwritestack_16(Img, [SavePath Name ParamStr '.tif']);