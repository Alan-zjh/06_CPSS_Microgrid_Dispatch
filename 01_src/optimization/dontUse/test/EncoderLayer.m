classdef EncoderLayer < handle
    properties
        self_attn
        feed_forward
        sublayer
        size
    end
    methods
        function obj = EncoderLayer(size, self_attn, feed_forward, dropout)
            obj.self_attn = self_attn;
            obj.feed_forward = feed_forward;
            obj.sublayer = {SublayerConnection(size, dropout), SublayerConnection(size, dropout)};
            obj.size = size;
        end
        function z = forward(obj, x, mask)
            x = obj.sublayer{1}.forward(x, @(x)obj.self_attn.forward(x, x, x, mask));
            z = obj.sublayer{2}.forward(x, @(x)obj.feed_forward.forward(x));
        end
    end
end