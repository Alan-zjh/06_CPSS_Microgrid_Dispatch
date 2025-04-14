classdef EncoderLayer < MultiHeadAttention & FeedForwardNetwork & LayerNorm
    methods
        % 构造函数
        function obj = EncoderLayer(d_model, num_heads, d_ff)
            obj@MultiHeadAttention(d_model, num_heads);
            obj@FeedForwardNetwork(d_model, d_ff);
        end
        
        % 前向传播
        function Y = forward(obj, X)
            % 1. 自注意力
            attention_output = obj.MultiHeadAttention.forward(X, X, X);
            attention_output = attention_output + X;  % 残差连接
            attention_output = obj.LayerNorm.forward(attention_output);
            
            % 2. 前馈网络
            ff_output = obj.FeedForwardNetwork.forward(attention_output);
            Y = ff_output + attention_output;  % 残差连接
            Y = obj.LayerNorm.forward(Y);
        end
    end
end
