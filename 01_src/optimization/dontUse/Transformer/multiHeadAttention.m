function Z = multiHeadAttention(Q, K, V, num_heads)
    [seq_len, d_model] = size(Q);
    
    head_dim = floor(d_model / num_heads);  % 确保 head_dim 是整数
    
    Z = [];
    for h = 1:num_heads
        % 确保索引为整数
        start_idx = (h-1)*head_dim + 1;
        end_idx = h*head_dim;
        
        Q_h = Q(:, start_idx:end_idx);
        K_h = K(:, start_idx:end_idx);
        V_h = V(:, start_idx:end_idx);
        
        Z_h = scaledDotProductAttention(Q_h, K_h, V_h);
        Z = [Z Z_h];  % 将多个头的输出拼接
    end
end
