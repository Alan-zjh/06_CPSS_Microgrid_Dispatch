classdef MultiHeadAttention
    properties
        Wq % 查询的权重矩阵
        Wk % 键的权重矩阵
        Wv % 值的权重矩阵
        Wo % 输出的权重矩阵
        num_heads
        d_model
    end
    
    methods
        % 构造函数
        function obj = MultiHeadAttention(d_model, num_heads)
            obj.d_model = d_model;
            obj.num_heads = num_heads;
            head_dim = d_model / num_heads;  % 每个头的维度

            % 初始化查询、键、值和输出的权重
            obj.Wq = randn(d_model, d_model);
            obj.Wk = randn(d_model, d_model);
            obj.Wv = randn(d_model, d_model);
            obj.Wo = randn(d_model, d_model);
        end
        
        % 前向传播
        function Z = forward(obj, Q, K, V)
            head_dim = obj.d_model / obj.num_heads;
            Z = [];

            % 遍历每个注意力头
            for h = 1:obj.num_heads
                Q_h = Q * obj.Wq(:, (h-1)*head_dim+1:h*head_dim);
                K_h = K * obj.Wk(:, (h-1)*head_dim+1:h*head_dim);
                V_h = V * obj.Wv(:, (h-1)*head_dim+1:h*head_dim);

                % 计算缩放点积注意力
                scores = (Q_h * K_h') / sqrt(head_dim);
                attention_weights = softmax(scores, 2);
                Z_h = attention_weights * V_h;

                Z = [Z Z_h];  % 拼接每个头的结果
            end

            % 线性变换输出
            Z = Z * obj.Wo;
        end

        % Softmax 函数
        function A = softmax(~, X, dim)
            exp_X = exp(X - max(X, [], dim));  % 防止数值溢出
            A = exp_X ./ sum(exp_X, dim);
        end
    end
end
