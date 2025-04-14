classdef LayerNorm < handle
    properties
        a_2
        b_2
        eps
    end
    methods
        function obj = LayerNorm(feature_size, eps)
            obj.a_2 = ones(1, feature_size);
            obj.b_2 = zeros(1, feature_size);
            obj.eps = eps;
        end
        function x = forward(obj, x)
            mean = mean(x, 2);
            std = std(x, 0, 2);
            x = obj.a_2 .* (x - mean) ./ (std + obj.eps) + obj.b_2;
        end
    end
end