function [isCTrue, Score] = evaluateC(C)
% 判断幅值c的差异
% intput 
%       C：参数估计C的差异     
%
% output:0 Or 1
%       0：不符合关系要求
%       1：符合关系要求
%
% 判断方法：
% Method：判断每个方向的 C 不大于0.5 不小于0.3
%
% Code
% 判断每个C 不大于0.5 不小于0.3
% standard = 0.5;
yuzhi = 0.3;

% high = find(C>standard);
low = find(C<yuzhi);
% if isempty(high) && isempty(low)
if isempty(low)
    isCTrue = 1;
else 
    isCTrue = 0;
end
Scores = C.*(6/yuzhi);
Scores(Scores>10) = 10;
Scores(Scores<0) = 0;
Score = mean(Scores);
% C
end



