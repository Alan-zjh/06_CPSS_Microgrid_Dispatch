classdef SublayerConnection < handle
    properties
        norm
        dropout
    end
    methods
        function obj = SublayerConnection(size, dropout)
            obj.norm = LayerNorm(size);
            obj.dropout = dropout;
        end
        function x = forward(obj, x, sublayer)
            x = obj.norm.forward(x + (sublayer.forward(x) * (1 - obj.dropout)));
        end
    end
end