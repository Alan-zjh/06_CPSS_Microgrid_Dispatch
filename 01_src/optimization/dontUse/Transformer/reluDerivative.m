function dA = reluDerivative(A)
    % ReLU 激活函数的导数
    dA = double(A > 0);  % 当 A > 0 时，导数为 1；否则为 0
end
