classdef Encoder < handle
    properties
        layers
        norm
    end
    methods
        function obj = Encoder(layer, N)
            obj.layers = repmat(layer, 1, N);
            obj.norm = LayerNorm(layer.size);
        end
        function x = forward(obj, x, mask)
            for layer = obj.layers
                x = layer.forward(x, mask);
            end
            x = obj.norm.forward(x);
        end
    end
end