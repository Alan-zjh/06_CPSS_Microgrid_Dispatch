function Y = transformer(X, num_layers, num_heads, d_ff)
    for i = 1:num_layers
        X = transformerEncoderLayer(X, num_heads, d_ff);
    end
    Y = X;
end
