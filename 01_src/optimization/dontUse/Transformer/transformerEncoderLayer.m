function Y = transformerEncoderLayer(X, num_heads, d_ff)
    % 多头注意力
    attention_output = multiHeadAttention(X, X, X, num_heads);
   
    attention_output = attention_output + X;  % 残差连接
    attention_output = layerNorm(attention_output);
    
    % 前馈网络
    ff_output = feedForwardNetwork(attention_output, d_ff);
    
    Y = ff_output + attention_output;  % 残差连接
    Y = layerNorm(Y);
end
