function [isATrue, diff] = evaluateAngle(Angle)
% 判断初始相位的差异
% intput 
%       Angle：角度     
%
% output:0 Or 1
%       0：不符合关系要求
%       1：符合关系要求
%
% 判断方法：
% Method：判断每个方向的 互为相反数的初始相位 差异是否<0.2
%a 
% Code
% Method：判断差异
num = size(Angle, 3);
num = num/2;
diff = zeros(1,num);
for i = 1:num
    diff(i) = abs(Angle(i*2 - 1)) -abs(Angle(i*2));
    if abs(diff(i)) > 0.2
        isATrue = 0;             % 如果差异大于0.2，则不正常
    else 
        isATrue = 1;
    end
end
% Angle
end


