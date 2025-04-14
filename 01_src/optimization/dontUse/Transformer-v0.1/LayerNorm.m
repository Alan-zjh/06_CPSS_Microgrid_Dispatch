% 层归一化
function Y = LayerNorm(X)
    epsilon = 1e-6;
    mu = mean(X, 2);
    sigma = std(X, 0, 2);
    Y = (X - mu) ./ (sigma + epsilon);
    gamma = ones(1, size(X, 2));
    beta = zeros(1, size(X, 2));
    Y = gamma .* Y + beta;
end