classdef Embeddings < handle
    properties
        lut
        d_model
    end
    methods
        function obj = Embeddings(d_model, vocab)
            obj.lut = rand(vocab, d_model); % 词嵌入矩阵
            obj.d_model = d_model;
        end
        function embedds = forward(obj, x)
            embedds = obj.lut(x+1, :) * sqrt(obj.d_model); % MATLAB索引从1开始
        end
    end
end