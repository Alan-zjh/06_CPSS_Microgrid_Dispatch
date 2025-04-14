function grads = computeGradients(X, Y_true, Y_pred, params, num_layers, num_heads, d_ff)
    % 计算损失相对于输出的梯度
    dZ = 2 * (Y_pred - Y_true);  % 对MSE损失函数的导数

    grads = struct();

    % 反向传播通过每一层
    for i = num_layers:-1:1
        % 提取当前层的参数
        Wq = params(i).Wq;
        Wk = params(i).Wk;
        Wv = params(i).Wv;
        Wo = params(i).Wo;
        Wff1 = params(i).Wff1;
        Wff2 = params(i).Wff2;

        % 前馈网络的反向传播
        d_ff2 = dZ * Wff2';
        grads(i).Wff2 = X' * dZ;
        
        % ReLU 的反向传播
        d_relu = d_ff2 .* reluDerivative(X * Wff1);
        grads(i).Wff1 = X' * d_relu;

        % 计算注意力机制的梯度
        [dQ, dK, dV] = attentionGradients(dZ, Wq, Wk, Wv, num_heads, size(X, 2));
        
        grads(i).Wq = X' * dQ;
        grads(i).Wk = X' * dK;
        grads(i).Wv = X' * dV;

        % 将梯度传播到上一层
        dZ = dQ + dK + dV;
    end
end
