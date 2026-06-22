%--------------------------------------------------------------------------
% Title: 获取调制深度参数
% Date: 20230618
% Author: WenJy
%--------------------------------------------------------------------------

Path = 'D:\03_TestData\GTL_SIM\20230615_SIM_Mask400\ROI2\ROI_512\结果reconstruction Wiener sim\';
Files = dir([Path '*.mat']);

C488 = cell(1,numel(Files)/3/2);
C561 = cell(1,numel(Files)/3/2);
C637 = cell(1,numel(Files)/3/2);
Angle488 = cell(1,numel(Files)/3/2);
Angle561 = cell(1,numel(Files)/3/2);
Angle637 = cell(1,numel(Files)/3/2);
i488 = 1;
i561 = 1;
i637 = 1;
CoordinateX488 = cell(1,numel(Files)/3/2);
CoordinateX561 = cell(1,numel(Files)/3/2);
CoordinateX637 = cell(1,numel(Files)/3/2);
CoordinateY488 = cell(1,numel(Files)/3/2);
CoordinateY561 = cell(1,numel(Files)/3/2);
CoordinateY637 = cell(1,numel(Files)/3/2);
iCoord488 = 1;
iCoord561 = 1;
iCoord637 = 1;
for iFile = 1:numel(Files)
    FileName = Files(iFile).name;
    if contains(FileName, 'samec_angle')
        load(fullfile(Path, FileName))
        if contains(FileName, '488')
            C488{1, i488} = c6(:);
            Angle488{1, i488} = angle6(:);
            i488 = i488 + 1;
        elseif contains(FileName, '561')
            C561{1, i561} = c6(:);
            Angle561{1, i561} = angle6(:);
            i561 = i561 + 1;
        elseif contains(FileName, '637')
            C637{1, i637} = c6(:);
            Angle637{1, i637} = angle6(:);
            i637 = i637 + 1;
        end
    elseif contains(FileName, 'zuobiao')
        load(fullfile(Path, FileName))
        if contains(FileName, '488')
            CoordinateX488{1, iCoord488} = zuobiaox(:);
            CoordinateY488{1, iCoord488} = zuobiaoy(:);
            iCoord488 = iCoord488 + 1;
        elseif contains(FileName, '561')
            CoordinateX561{1, iCoord561} = zuobiaox(:);
            CoordinateY561{1, iCoord561} = zuobiaoy(:);
            iCoord561 = iCoord561 + 1;
        elseif contains(FileName, '637')
            CoordinateX637{1, iCoord637} = zuobiaox(:);
            CoordinateY637{1, iCoord637} = zuobiaoy(:);
            iCoord637 = iCoord637 + 1;
        end
    end
end

Angle637mat = cell2mat(Angle637);
Angle1 = sign(Angle637mat(1,:)).*0.5.*(abs(Angle637mat(1,:)) + abs(Angle637mat(2,:)));
Angle2 = sign(Angle637mat(3,:)).*0.5.*(abs(Angle637mat(3,:)) + abs(Angle637mat(4,:)));
Angle3 = sign(Angle637mat(5,:)).*0.5.*(abs(Angle637mat(5,:)) + abs(Angle637mat(6,:)));
figure
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(Angle1, 'color', [0.9,0,0], 'LineWidth', 1.5)
ylabel('Phase(rad)', 'FontSize', 20);
clc
figure
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(Angle2, 'color', [0.9,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Phase(rad)', 'FontSize', 20);
figure
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(Angle3, 'color', [0.9,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Phase(rad)', 'FontSize', 20);

C637mat = cell2mat(C637);
C1 = 0.5.*(C637mat(1,:) + C637mat(2,:));
C2 = 0.5.*(C637mat(3,:) + C637mat(4,:));
C3 = 0.5.*(C637mat(5,:) + C637mat(6,:));
figure
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(C1, 'color', [0,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Modulation depth of the illumination', 'FontSize', 20);
clc
figure
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(C2, 'color', [0,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Modulation depth of the illumination', 'FontSize', 20);
figure
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(C3, 'color', [0,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Modulation depth of the illumination', 'FontSize', 20);



C488mat = cell2mat(C488);
C1 = 0.5.*(C488mat(1,:) + C488mat(2,:));
C2 = 0.5.*(C488mat(3,:) + C488mat(4,:));
C3 = 0.5.*(C488mat(5,:) + C488mat(6,:));
figure
set(gcf,'unit','centimeters','position',[10 10 23 15]);
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(C1, 'color', [0,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Modulation depth of the illumination', 'FontSize', 20);
print(gcf, '-dpng', '-r300', [Path '488_C1.png'])
figure
set(gcf,'unit','centimeters','position',[10 10 23 15]);
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(C2, 'color', [0,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Modulation depth of the illumination', 'FontSize', 20);
print(gcf, '-dpng', '-r300', [Path '488_C2.png'])
figure
set(gcf,'unit','centimeters','position',[10 10 23 15]);
set(gca, 'LineWidth', 1.25, 'FontSize', 15)
set(get(gca, 'XLabel'), 'FontSize', 15)
set(get(gca, 'YLabel'), 'FontSize', 15)
hold on
plot(C3, 'color', [0,0,0], 'LineWidth', 1.5)
xlabel('Different ROI', 'FontSize', 20);
ylabel('Modulation depth of the illumination', 'FontSize', 20);
print(gcf, '-dpng', '-r300', [Path '488_C3.png'])