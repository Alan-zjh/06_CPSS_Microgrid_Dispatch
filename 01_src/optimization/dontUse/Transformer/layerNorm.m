function Y = layerNorm(X)
    % Layer Normalization
    epsilon = 1e-6;  % 防止除零
    mu = mean(X, 2);  % 计算每个样本的均值
    sigma = std(X, 0, 2);  % 计算每个样本的标准差
    
    % 标准化输入
    X_norm = (X - mu) ./ (sigma + epsilon);
    
    % 可学习参数 gamma 和 beta
    gamma = ones(1, size(X, 2));  % 缩放参数
    beta = zeros(1, size(X, 2));  % 平移参数
    
    % 应用缩放和平移
    Y = gamma .* X_norm + beta;
end
