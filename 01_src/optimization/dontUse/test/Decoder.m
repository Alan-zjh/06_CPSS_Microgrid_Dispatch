classdef Decoder < handle
    properties
        layers
        norm
    end
    methods
        function obj = Decoder(layer, N)
            obj.layers = repmat(layer, 1, N);
            obj.norm = LayerNorm(layer.size);
        end
        function x = forward(obj, x, memory, src_mask, tgt_mask)
            for layer = obj.layers
                x = layer.forward(x, memory, src_mask, tgt_mask);
            end
            x = obj.norm.forward(x);
        end
    end
end