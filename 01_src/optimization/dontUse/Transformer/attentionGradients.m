function [dQ, dK, dV] = attentionGradients(dZ, Wq, Wk, Wv, num_heads, d_model)
    % dZ 是损失梯度，Wq, Wk, Wv 是查询、键、值的权重矩阵
    % num_heads 是多头注意力中的头的数量
    % d_model 是模型的维度
    
    head_dim = d_model / num_heads;  % 每个注意力头的维度

    dQ = zeros(size(Wq));  % 初始化 dQ 的大小和 Wq 相同
    dK = zeros(size(Wk));  % 初始化 dK
    dV = zeros(size(Wv));  % 初始化 dV

    % 对每个头分别计算梯度
    for h = 1:num_heads
        % 提取当前头的权重
        Wq_h = Wq(:, (h-1)*head_dim+1:h*head_dim);  % 当前头的 Wq 块
        Wk_h = Wk(:, (h-1)*head_dim+1:h*head_dim);  % 当前头的 Wk 块
        Wv_h = Wv(:, (h-1)*head_dim+1:h*head_dim);  % 当前头的 Wv 块
        
        % 确保 dZ 和权重块维度匹配
        dZ_h = dZ(:, (h-1)*head_dim+1:h*head_dim);  % 对应头的损失梯度
        
        % 使用矩阵乘法传播梯度
        dQ(:, (h-1)*head_dim+1:h*head_dim) = dZ_h * Wq_h;  % 乘以权重矩阵 Wq_h
        dK(:, (h-1)*head_dim+1:h*head_dim) = dZ_h * Wk_h;  % 乘以 Wk_h
        dV(:, (h-1)*head_dim+1:h*head_dim) = dZ_h * Wv_h;  % 乘以 Wv_h
    end
end
