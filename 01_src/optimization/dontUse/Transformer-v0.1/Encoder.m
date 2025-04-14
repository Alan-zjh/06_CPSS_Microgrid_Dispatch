classdef Encoder < EncoderLayer
    properties
        num_layers
    end
    
    methods
        % 构造函数
        function obj = Encoder(d_model, num_heads, d_ff, num_layers)
            obj@EncoderLayer(d_model, num_heads, d_ff);
            obj.num_layers = num_layers;
        end
        
        % 前向传播
        function Y = forward(obj, X)
            for i = 1:obj.num_layers
                X = obj.EncoderLayer.forward(X);
            end
            Y = X;  % 输出编码器隐藏状态
        end
    end
end
