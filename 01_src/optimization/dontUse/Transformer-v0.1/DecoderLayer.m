classdef DecoderLayer < MultiHeadAttention & FeedForwardNetwork & LayerNorm
    methods
        % 构造函数
        function obj = DecoderLayer(d_model, num_heads, d_ff)
            obj@MultiHeadAttention(d_model, num_heads);
            obj@FeedForwardNetwork(d_model, d_ff);
        end
        
        % 前向传播
        function Y = forward(obj, X_dec, X_enc)
            % 1. 自注意力
            self_attention_output = obj.MultiHeadAttention.forward(X_dec, X_dec, X_dec);
            self_attention_output = self_attention_output + X_dec;  % 残差连接
            self_attention_output = obj.LayerNorm.forward(self_attention_output);
            
            % 2. 编码器-解码器注意力
            cross_attention_output = obj.MultiHeadAttention.forward(self_attention_output, X_enc, X_enc);
            cross_attention_output = cross_attention_output + self_attention_output;  % 残差连接
            cross_attention_output = obj.LayerNorm.forward(cross_attention_output);
            
            % 3. 前馈网络
            ff_output = obj.FeedForwardNetwork.forward(cross_attention_output);
            Y = ff_output + cross_attention_output;  % 残差连接
            Y = obj.LayerNorm.forward(Y);
        end
    end
end
