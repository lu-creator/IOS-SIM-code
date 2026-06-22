function [isPTrue, p, ang, Score] = evaluateP(zuobiaox, zuobiaoy)
% 判断zuobiao判断位置是否符合 正确频谱的位置关系
% intput
%       zuobiaox： P的x坐标
%       zuobiaoy： P的y坐标
%
% output:0 Or 1
%       0：不符合关系要求
%       1：符合关系要求
%
% 判断方法：
% Method1：坐标与原点距离是否符合长度plong
% Method2：坐标位置角度是否符合要求，相隔60
%
% Code
% Method1：判断长度
Pyuzhi = 1;
Angyuzhi = 1;
plong = sum(((zuobiaox-zuobiaox(1,1)).^2+(zuobiaoy-zuobiaoy(1,1)).^2).^0.5)./6;
p = sqrt((zuobiaox-zuobiaox(1,1)).^2+(zuobiaoy-zuobiaoy(1,1)).^2);
NoneZeros = p~=0;
NZ = p(NoneZeros);
diffP = abs((NZ - plong));
index = find(diffP>Pyuzhi); % 每个分量距离0频 长度差异不超过1个像素的差异
if size(index,1)~=0
    isPTrue = 0;             % 长度不符合要求
else
    isPTrue = 1;             % 长度符合要求
end
% p 差异0—10 差异1-6
ScoreP = mean( 10 - diffP.*((10-6)./Pyuzhi) );
ScoreP(ScoreP>10) = 10;
ScoreP(ScoreP<0) = 0;

% 向量计算相差角度——相对于2 3坐标索引形成的向量 的 角度
Horizon = [zuobiaox(2) - zuobiaox(3), zuobiaoy(2) - zuobiaoy(3) ];
Rot1 = [zuobiaox(5) - zuobiaox(6), zuobiaoy(5) - zuobiaoy(6) ];
Rot2 = [zuobiaox(8) - zuobiaox(9), zuobiaoy(8) - zuobiaoy(9) ];

ang(1) = acos(dot(Horizon,Rot1)/(norm(Horizon)*norm(Rot1))) /pi *180;
ang(2) = acos(dot(Horizon,Rot2)/(norm(Horizon)*norm(Rot2))) /pi *180;
ang(3) = acos(dot(Rot1,Rot2)/(norm(Rot1)*norm(Rot2))) /pi *180;
angT = min(180-ang, ang);  % 转换到90度范围
diffA = abs(angT - 60);
if all( diffA < Angyuzhi)
    ;
else                   % 角度相差1度，就认为有问题
    isPTrue = 0;
end
ScoreA = mean( 10 - diffA.*((10-6)./Angyuzhi) );
ScoreA(ScoreA>10) = 10;
ScoreA(ScoreA<0) = 0;
Score = 0.5*(ScoreP + ScoreA);

end


