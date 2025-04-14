function params = initializeParams(seq_len, d_model, d_ff, num_heads, num_layers)
    % 初始化 Transformer 模型的所有参数
    params = struct();
    
    % 对于每一层的多头注意力和前馈网络，初始化权重
    for i = 1:num_layers
        params(i).Wq = randn(d_model, d_model);  % 查询权重
        params(i).Wk = randn(d_model, d_model);  % 键权重
        params(i).Wv = randn(d_model, d_model);  % 值权重
        params(i).Wo = randn(d_model, d_model);  % 输出权重
        params(i).Wff1 = randn(d_model, d_ff);   % 前馈层 1
        params(i).Wff2 = randn(d_ff, d_model);   % 前馈层 2
    end
end
