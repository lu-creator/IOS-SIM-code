function [x, y] = ParabolicInterpolation2D(lihe)
% 二维抛物线插值求解极大值
[xx2, yy2] = ind2sub(size(lihe),find(lihe==max(lihe(:)))); % 整像素的互相关peak的位置
F = [lihe(xx2-1, yy2), lihe(xx2, yy2), lihe(xx2+1, yy2), lihe(xx2, yy2-1), lihe(xx2, yy2+1)];

% 将x y转换到-1 0 1
x1 = - 1;
x2 = 0;
x3 = 1;
y1 = - 1;
y2 = 0;
y3 = 1;
% Ax = F
XY = [1, 1, 1, 1, 1; 
     x1, x2, x3, x2, x2;
     y2, y2, y2, y1, y3;
     x1*y2, x2*y2, x3*y2, x2*y1, x2*y3;
     x1^2, x2^2, x3^2, x2^2, x2^2;
     y2^2, y2^2, y2^2, y1^2, y3^2];
XY = pinv(XY);
A = F*XY;
X = [x1, x2, x3] + A(4)/(2*A(5)).*[y1, y2, y3];
Y = [y1, y2, y3];

if A(5)* (A(6) - (A(4)*A(4))/(4*A(5))) > 0
    y = ( A(3) - (A(2)*A(3))/(2*A(5)) ) / (2*( A(6) - (A(4)*A(4))/(4*A(5)) ));
    x = A(2)/(2*A(5)) - A(4)/(2*A(5))*y;    
else
    % 极值在边界,对比边界的值
    f =  @(x, y, A) A(1) + A(2).*x +  A(5).*x.^2 + (A(3) - ((A(2)*A(4))/(2*A(5))) ).*y +  ( A(6) - (A(4)*A(4))/(4*A(5)) ).*y.*y;
    f_12 = f(X(1), Y(2), A);
    f_22 = f(X(2), Y(2), A);
    f_32 = f(X(3), Y(2), A);
    f_21 = f(X(2), Y(1), A);
    f_23 = f(X(2), Y(3), A);
    F = [f_12, f_22, f_32, f_21, f_23];
    [~, index] = max(F);
    if index < 4
       y = y2;
       if index == 1
           x = x1;
       elseif index == 2
           x = x2;
       else
           x = x3;
       end
    elseif index == 4
       y = y1;
       x = x2;
    else
       y = y3;
       x = x2;
    end
     
end

x = x + xx2;
y = y + yy2;

end
