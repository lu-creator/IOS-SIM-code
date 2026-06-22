function [SubpixelX, SubpixelY]= Interpolation2D(corr_matrix, method, tol, spi)

%% 整数点处的相关系数
[matchY,matchX] = find(corr_matrix == max(max(corr_matrix)));
Z = corr_matrix(matchY-1:matchY+1,matchX-1:matchX+1);
[X,Y] = meshgrid(matchX-1:matchX+1,matchY-1:matchY+1);
if method == 1
    %% 完全二次曲面插值  f(x,y) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2 + a5*x*y
    %%%%%%%%%%%%%%%%%%%%直接计算亚像素点处的相关系数%%%%%%%%%%%%%%%%%%%%    
    [X1,Y1] = meshgrid(matchX-1:tol:matchX+1,matchY-1:tol:matchY+1);
%     Z1 = interp2(X,Y,Z,X1,Y1,'spline');
    [subX,subY] = find(Z1 == max(max(Z1)));
    fprintf('Matching point in sub-pixel precision by “完全二次曲面插值” is calibrated at [%.4f %.4f].\n',Y1(subX,subY),X1(subX,subY));
    
%     figure,
%     imagesc(Z1);
%     colorbar;
%     axis equal
%     imwritestack(Z1, [pathname_superior '\结果reconstruction Wiener sim\M1' num2str(spi)  filename]);
    SubpixelY = X1(subX,subY);
    SubpixelX = Y1(subX,subY);
elseif method == 2
    %%%%%%%%%%%%%%%%%%%%迭代法计算亚像素点处的相关系数%%%%%%%%%%%%%%%%%%%%
    x = matchX;
    y = matchY;
    step = 1;
    while(step > tol)
        step = step/2;
        [X2,Y2] = meshgrid(x-2*step:step:x+2*step,y-2*step:step:y+2*step);
        
        Z2 = interp2(X,Y,Z,X2,Y2,'spline');
        [subX,subY] = find(Z2 == max(max(Z2)));
        x = X2(subX,subY);
        y = Y2(subX,subY);
        if(subX == 1)&&(subY ~= 5)
            X = X2(subX:subX+1,subY-1:subY+1);
            Y = Y2(subX:subX+1,subY-1:subY+1);
            Z = Z2(subX:subX+1,subY-1:subY+1);
        elseif(subX == 5)&&(subY ~= 1)
            X = X2(subX-1:subX,subY-1:subY+1);
            Y = Y2(subX-1:subX,subY-1:subY+1);
            Z = Z2(subX-1:subX,subY-1:subY+1);
        elseif(subY == 1)&&(subX ~= 5)
            X = X2(subX-1:subX+1,subY:subY+1);
            Y = Y2(subX-1:subX+1,subY:subY+1);
            Z = Z2(subX-1:subX+1,subY:subY+1);
        elseif(subY == 5)&&(subX ~= 1)
            X = X2(subX-1:subX+1,subY-1:subY);
            Y = Y2(subX-1:subX+1,subY-1:subY);
            Z = Z2(subX-1:subX+1,subY-1:subY);
        elseif (subY == 5)&&(subX == 1)
            X = X2(subX:subX+1,subY-1:subY);
            Y = Y2(subX:subX+1,subY-1:subY);
            Z = Z2(subX:subX+1,subY-1:subY);
        else
            X = X2(subX-1:subX+1,subY-1:subY+1);
            Y = Y2(subX-1:subX+1,subY-1:subY+1);
            Z = Z2(subX-1:subX+1,subY-1:subY+1);
        end
    end
    
    fprintf('Matching point in sub-pixel precision by “完全二次曲面插值” is calibrated at [%.4f %.4f].\n',y,x);
    
%     figure,
%     imagesc(Z2);
%     colorbar;
%     axis equal
%     imwritestack(Z2, [pathname_superior '\结果reconstruction Wiener sim\M2' num2str(spi) filename]);
    SubpixelY = x;
    SubpixelX = y;
elseif method == 3
    %% 对称二次曲线插值 f(x,y) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2
    if corr_matrix(matchY+1,matchX) > corr_matrix(matchY-1,matchX)
        corr_subpixel_y = (corr_matrix(matchY+1,matchX) - corr_matrix(matchY-1,matchX))...
            /(corr_matrix(matchY+1,matchX) - corr_matrix(matchY-1,matchX) + corr_matrix(matchY,matchX) - corr_matrix(matchY+2,matchX));
    else
        corr_subpixel_y = (corr_matrix(matchY+1,matchX) - corr_matrix(matchY-1,matchX))...
            /(corr_matrix(matchY-1,matchX) - corr_matrix(matchY+1,matchX) + corr_matrix(matchY,matchX) - corr_matrix(matchY-2,matchX));
    end
    
    if corr_matrix(matchY,matchX+1) > corr_matrix(matchY,matchX-1)
        corr_subpixel_x = (corr_matrix(matchY,matchX+1) - corr_matrix(matchY,matchX-1))...
            /(corr_matrix(matchY,matchX+1) - corr_matrix(matchY,matchX-1) + corr_matrix(matchY,matchX) - corr_matrix(matchY,matchX+2));
    else
        corr_subpixel_x = (corr_matrix(matchY,matchX+1) - corr_matrix(matchY,matchX-1))...
            /(corr_matrix(matchY,matchX-1) - corr_matrix(matchY,matchX+1) + corr_matrix(matchY,matchX) - corr_matrix(matchY,matchX-2));
    end
    
%     fprintf('Matching point in sub-pixel precision by “对称二次曲线插值” is calibrated at [%.4f %.4f].\n',matchY+corr_subpixel_y,matchX+corr_subpixel_x);
%     save([pathname_superior '\结果reconstruction Wiener sim\M6' num2str(spi) filename(1:end-4) '.mat'], 'a_coeffient');
    SubpixelY = matchX+corr_subpixel_x;
    SubpixelX = matchY+corr_subpixel_y;
%     fprintf('X Y is  [%d %d]\n', matchY, matchX);
%     fprintf('subpixel_x subpixel_y is  [%.4f %.4f]', corr_subpixel_y, corr_subpixel_x);
    
elseif method == 4
    %% 对称二次曲面插值1  f(x,y) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2
    tol = 2 * 0.005^2;
    corr_matrix_center = corr_matrix(matchY-2:matchY+2,matchX-2:matchX+2);
    [X_center, Y_center] = meshgrid(-2:2,-2:2);
    
%     figure,
%     surf(X_center,Y_center,corr_matrix_center)
%     title('对称二次曲面插值')
    coeffient = [0 0 0 0 0 0 0 0]';
    % coeffient = unifrnd(-0.1,0.1,8,1);
    % coeffient = [1 -0.5 -0.5 0 0 0 0 0]';
    
    for i = 1 : 50
        diff_1 = ones(5,5);
        diff_2 = abs(X_center-coeffient(7));
        diff_3 = abs(Y_center-coeffient(8));
        diff_4 = (X_center-coeffient(7)).^2;
        diff_5 = (Y_center-coeffient(8)).^2;
        diff_6 = abs(X_center-coeffient(7)) .* abs(Y_center-coeffient(8));
        diff_7 = - coeffient(2) * ((X_center - coeffient(7))./abs(X_center - coeffient(7) + eps)) + ...
            2 * coeffient(4) * (X_center - coeffient(7)) - ...
            coeffient(6) * ((X_center - coeffient(7))./abs(X_center - coeffient(7) + eps)) .* abs(Y_center - coeffient(8));
        diff_8 = - coeffient(3) * ((Y_center - coeffient(8))./abs(Y_center - coeffient(8) + eps)) + ...
            2 * coeffient(5) * (Y_center - coeffient(8)) - ...
            coeffient(6) * ((Y_center - coeffient(8))./abs(Y_center - coeffient(8) + eps)) .* abs(X_center - coeffient(7));
        
        delta_corr =  coeffient(1) * diff_1 + ...
            coeffient(2) * diff_2 + ...
            coeffient(3) * diff_3 + ...
            coeffient(4) * diff_4 + ...
            coeffient(5) * diff_5 + ...
            coeffient(6) * diff_6 - ...
            corr_matrix_center;
        
        diff_matrix = [diff_1(:) diff_2(:) diff_3(:) diff_4(:) diff_5(:) diff_6(:) diff_7(:) diff_8(:)];
        temp = diff_matrix \ delta_corr(:);
        coeffient = coeffient + temp;
        if i>2 && sum(temp(7:8).^2) < tol
            break;
        end
    end
    
    fprintf('Matching point in sub-pixel precision by “对称二次曲面插值” is calibrated at [%.4f %.4f].\n',matchY+coeffient(8),matchX+coeffient(7));
%      save([pathname_superior '\结果reconstruction Wiener sim\M4' num2str(spi) filename(1:end-4) '.mat'], 'coeffient');
    SubpixelY = matchX+coeffient(7);
    SubpixelX = matchY+coeffient(8);    
elseif method == 5
    %% 对称二次曲面插值2 f(x,y) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2
    Z = corr_matrix(matchY-1:matchY+1,matchX-1:matchX+1);
    [X,Y] = meshgrid(-1:1,-1:1);
    
    coeff_0 = ones(3);
    coeff_1 = X;
    coeff_2 = Y;
    coeff_3 = X.^2;
    coeff_4 = Y.^2;
    coeff_matrix = [coeff_0(:) coeff_1(:) coeff_2(:) coeff_3(:) coeff_4(:)];
    a_coeffient = coeff_matrix \ Z(:);
    
%     figure, surf(Y, X, Z), title('对称二次曲面插值 f(x,y) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2')
    fprintf('Matching point in sub-pixel precision by “对称二次曲面插值1” is calibrated at [%.4f %.4f].\n',matchX-a_coeffient(3)/(2*a_coeffient(5)), matchY-a_coeffient(2)/(2*a_coeffient(4)));
%     imwritestack(Z, [pathname_superior '\结果reconstruction Wiener sim\re-M5' num2str(spi) filename]);
    save([pathname_superior '\结果reconstruction Wiener sim\M5' num2str(spi) filename(1:end-4) '.mat'], 'a_coeffient');
    SubpixelY = matchX -a_coeffient(3)/(2*a_coeffient(5));
    SubpixelX = matchY -a_coeffient(2)/(2*a_coeffient(4));      
elseif method == 6
    %% 对称二次曲面插值3 log(f(x,y)) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2
    Z = corr_matrix(matchY-1:matchY+1,matchX-1:matchX+1);
    [X,Y] = meshgrid(matchX-1:matchX+1,matchY-1:matchY+1);
    
    coeff_0 = ones(3);
    coeff_1 = X;
    coeff_2 = Y;
    coeff_3 = X.^2;
    coeff_4 = Y.^2;
    coeff_matrix = [coeff_0(:) coeff_1(:) coeff_2(:) coeff_3(:) coeff_4(:)];
    a_coeffient = coeff_matrix \ log(Z(:));
    
    fprintf('Matching point in sub-pixel precision by “对称二次曲面插值2” is calibrated at [%.4f %.4f].\n',-a_coeffient(3)/(2*a_coeffient(5)),-a_coeffient(2)/(2*a_coeffient(4)));
%     figure, surf(Y, X, Z), title('对称二次曲面插值 log(f(x,y)) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2')
%     save([pathname_superior '\结果reconstruction Wiener sim\M6' num2str(spi) filename(1:end-4) '.mat'], 'a_coeffient');
    SubpixelX = -a_coeffient(3)/(2*a_coeffient(5));
    SubpixelY = -a_coeffient(2)/(2*a_coeffient(4)); 
elseif method == 7
    %% 对称二次曲面插值3 log(f(x,y)) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2
    Z = corr_matrix(matchY-1:matchY+1,matchX-1:matchX+1);
    [X,Y] = meshgrid(-1:+1,-1:+1);
    
    coeff_0 = ones(3);
    coeff_1 = X;
    coeff_2 = Y;
    coeff_3 = X.^2;
    coeff_4 = Y.^2;
    coeff_matrix = [coeff_0(:) coeff_1(:) coeff_2(:) coeff_3(:) coeff_4(:)];
    a_coeffient = coeff_matrix \ log(Z(:));
    
    fprintf('Matching point in sub-pixel precision by “对称二次曲面插值2” is calibrated at [%.4f %.4f].\n',-a_coeffient(3)/(2*a_coeffient(5)),-a_coeffient(2)/(2*a_coeffient(4)));
%     figure, surf(Y, X, Z), title('对称二次曲面插值 log(f(x,y)) = a0 + a1*x + a2*y + a3*x^2 + a4*y^2')
%     save([pathname_superior '\结果reconstruction Wiener sim\M7' num2str(spi) filename(1:end-4) '.mat'], 'a_coeffient');
    SubpixelY = matchX-a_coeffient(3)/(2*a_coeffient(5));
    SubpixelX = matchY-a_coeffient(2)/(2*a_coeffient(4)); 
end