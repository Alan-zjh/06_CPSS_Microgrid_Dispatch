classdef DecoderLayer < handle
    properties
        self_attn
        src_attn
        feed_forward
        sublayer
        size
    end
    methods
        function obj = DecoderLayer(size, self_attn, src_attn, feed_forward, dropout)
            obj.size = size;
            obj.self_attn = self_attn;
            obj.src_attn = src_attn;
            obj.feed_forward = feed_forward;
            obj.sublayer = {SublayerConnection(size, dropout), SublayerConnection(size, dropout), SublayerConnection(size, dropout)};
        end
        function x = forward(obj, x, memory, src_mask, tgt_mask)
            x = obj.sublayer{1}.forward(x, @(x)obj.self_attn.forward(x, x, x, tgt_mask));
            x = obj.sublayer{2}.forward(x, @(x)obj.src_attn.forward(x, memory, memory, src_mask));
            x = obj.sublayer{3}.forward(x, @(x)obj.feed_forward.forward(x));
        end
    end
end