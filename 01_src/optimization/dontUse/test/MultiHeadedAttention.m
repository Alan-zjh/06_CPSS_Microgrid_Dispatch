classdef MultiHeadedAttention < handle
    properties
        h
        d_k
        linears
        attn
        dropout
    end
    methods
        function obj = MultiHeadedAttention(h, d_model, dropout)
            assert(mod(d_model, h) == 0);
            obj.d_k = d_model / h;
            obj.h = h;
            obj.linears = cell(1, 4);
            for i = 1:4
                obj.linears{i} = rand(d_model, d_model); % 线性层
            end
            obj.attn = [];
            obj.dropout = dropout;
        end
        function x = forward(obj, query, key, value, mask)
            nbatches = size(query, 1);
            mask = mask + 1; % 扩展mask维度
            query = reshape(query * obj.linears{1}, nbatches, -1, obj.h, obj.d_k);
            key = reshape(key * obj.linears{2}, nbatches, -1, obj.h, obj.d_k);
            value = reshape(value * obj.linears{3}, nbatches, -1, obj.h, obj.d_k);
            % Attention计算
            scores = (query * permute(key, [1, 2, 4, 3])) / sqrt(obj.d_k);
            if ~isempty(mask)
                scores = scores + mask; % 应用mask
            end
            p_attn = softmax(scores, 4);
            if ~isempty(obj.dropout)
                p_attn = p_attn * (1 - obj.dropout);
            end
            x = sum(p_attn .* value, 3);
            x = reshape(x, nbatches, [], obj.h * obj.d_k);
            x = x * obj.linears{4}; % 最后线性层
        end
    end
end