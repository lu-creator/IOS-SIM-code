function [isKurt, kut, Score] = evaluatePeak(data) 
% 判断angle的fitting结果，对拟合曲线峰度进行判断：尖峰、正态、平坦
% input
%      data: angle的拟合曲线
%
% output
%      isKurt:0 OR 1 是否全为尖峰:1-尖峰,0-平坦
% Method: 计算峰度  四阶中心矩 / 二阶中心矩(样本方差平方)
[num, ~] = size(data);  % 最后一个元素为0
norml = 3;   % 正态分布
good = 7;   % 较好数据的峰度分布
bad = 1.8;   % 较差数据的峰度分布
for i = 1:num
    kut(i) = kurtosis(data(i,:));
%    kut(i) = kt(data(i,:));
end
isSharp = find(kut<norml);   % 是否小于正态分布的峰度(3)
if isempty(isSharp)
    isKurt = 1;
else
    isKurt = 0;
end
Scores = (kut-bad).*(10/(good-bad));
Scores(Scores>10) = 10;
Scores(Scores<0) =0;
Score = mean(Scores);
end

 
function k = kt(data)
% 计算一维数据的峰度
% input
%      data:一维数据
% output
%      k:数据的峰度
n = numel(data);
xbar = mean(data);
s = data - xbar;
k = (sum(s.^4)/n) / (sum(s.^2)/n).^2;
end


