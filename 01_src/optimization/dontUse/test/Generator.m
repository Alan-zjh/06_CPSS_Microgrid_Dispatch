classdef Generator < handle
    properties
        proj
    end
    methods
        function obj = Generator(d_model, vocab)
            obj.proj = rand(d_model, vocab); % 线性层
        end
        function output = forward(obj, x)
            output = log(softmax(x * obj.proj, 2)); % 线性变换和softmax
        end
    end
end