classdef PositionwiseFeedForward < handle
    properties
        w_1
        w_2
        dropout
    end
    methods
        function obj = PositionwiseFeedForward(d_model, d_ff, dropout)
            obj.w_1 = rand(d_model, d_ff);
            obj.w_2 = rand(d_ff, d_model);
            obj.dropout = dropout;
        end
        function x = forward(obj, x)
            x = relu(x * obj.w_1);
            x = x * (1 - obj.dropout);
            x = x * obj.w_2;
        end
    end
end