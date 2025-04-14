function Z = scaledDotProductAttention(Q, K, V)
    % 计算缩放的点积注意力
    d_k = size(K, 2);
    scores = (Q * K') / sqrt(d_k);
    attention_weights = softmax(scores, 2);  % 按行计算 softmax
    Z = attention_weights * V;
end