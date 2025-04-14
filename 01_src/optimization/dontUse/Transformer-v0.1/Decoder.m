classdef Decoder < DecoderLayer
    properties
        num_layers
    end
    
    methods
        % 构造函数
        function obj = Decoder(d_model, num_heads, d_ff, num_layers)
            obj@DecoderLayer(d_model, num_heads, d_ff);
            obj.num_layers = num_layers;
        end
        
        % 前向传播
        function Y = forward(obj, X_dec, X_enc)
            for i = 1:obj.num_layers
                X_dec = obj.DecoderLayer.forward(X_dec, X_enc);
            end
            Y = X_dec;  % 解码器输出
        end
    end
end
