classdef PositionalEncoding < handle
    properties
        pe
        dropout
    end
    methods
        function obj = PositionalEncoding(d_model, dropout, max_len)
            obj.dropout = dropout;
            obj.pe = zeros(max_len, d_model);
            for pos = 1:max_len
                for i = 1:2:d_model
                    obj.pe(pos, i) = sin((pos-1) / (10000 ^ ((2 * i - 1) / d_model)));
                    if i + 1 <= d_model
                        obj.pe(pos, i + 1) = cos((pos-1) / (10000 ^ ((2 * i) / d_model)));
                    end
                end
            end
        end
        function x = forward(obj, x)
            x = x + obj.pe(1:size(x, 1), :);
            x = x * (1 - obj.dropout); % Dropout处理
        end
    end
end