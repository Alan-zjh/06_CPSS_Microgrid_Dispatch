function Y_pred = predict(X_test, params, num_layers, num_heads, d_ff)
    num_samples = size(X_test, 1);
    Y_pred = zeros(num_samples, 1);

    for i = 1:num_samples
        X = X_test(i, :);
        Y_pred(i) = transformer(X, num_layers, num_heads, d_ff);
    end
end
