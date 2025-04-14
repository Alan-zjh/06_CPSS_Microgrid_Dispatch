function pe = positionalEncoding(max_len, d_model)
    % 生成位置编码矩阵
    pe = zeros(max_len, d_model);
    for pos = 1:max_len
        for i = 1:2:d_model
            pe(pos, i) = sin(pos / (10000^(i/d_model)));
            pe(pos, i+1) = cos(pos / (10000^(i/d_model)));
        end
    end
end
