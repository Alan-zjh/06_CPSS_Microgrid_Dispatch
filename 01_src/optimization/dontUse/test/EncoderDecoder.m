classdef EncoderDecoder < handle
    properties
        encoder
        decoder
        src_embed
        tgt_embed
        generator
    end
    methods
        function obj = EncoderDecoder(encoder, decoder, src_embed, tgt_embed, generator)
            obj.encoder = encoder;
            obj.decoder = decoder;
            obj.src_embed = src_embed;
            obj.tgt_embed = tgt_embed;
            obj.generator = generator;
        end
        function res = forward(obj, src, tgt, src_mask, tgt_mask)
            memory = obj.encode(src, src_mask);
            res = obj.decode(memory, src_mask, tgt, tgt_mask);
        end
        function memory = encode(obj, src, src_mask)
            src_embedds = obj.src_embed.forward(src);
            memory = obj.encoder.forward(src_embedds, src_mask);
        end
        function res = decode(obj, memory, src_mask, tgt, tgt_mask)
            target_embedds = obj.tgt_embed.forward(tgt);
            res = obj.decoder.forward(target_embedds, memory, src_mask, tgt_mask);
        end
    end
end