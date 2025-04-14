function Y = feedForwardNetwork(X, d_ff)
    % 前馈神经网络
    W1 = randn(size(X, 2), d_ff);
    W2 = randn(d_ff, size(X, 2));
    Y = max(0, X * W1);  % ReLU 激活
    Y = Y * W2;
end
