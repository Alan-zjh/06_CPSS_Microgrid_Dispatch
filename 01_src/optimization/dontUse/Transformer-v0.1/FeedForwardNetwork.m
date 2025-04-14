classdef FeedForwardNetwork
    properties
        W1
        W2
        d_model
        d_ff
    end
    
    methods
        % 构造函数
        function obj = FeedForwardNetwork(d_model, d_ff)
            obj.d_model = d_model;
            obj.d_ff = d_ff;
            obj.W1 = randn(d_model, d_ff);  % 第一层权重
            obj.W2 = randn(d_ff, d_model);  % 第二层权重
        end
        
        % 前向传播
        function Y = forward(obj, X)
            Y = max(0, X * obj.W1);  % ReLU 激活
            Y = Y * obj.W2;
        end
    end
end
