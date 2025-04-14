function [X_train, Y_train, X_test, Y_test] = prepareData_PV(data, predict_duration, test_split)

    X = data(:,4:8);
    
    % 创建目标数据
    Y = zeros(size(data, 1) - predict_duration, predict_duration);
    for i = 1:predict_duration
        Y(:, i) = data(i : end - predict_duration + i - 1, 3);
    end
    


    % 划分训练集和测试集
    split_idx = floor((1 - test_split) * size(X, 1));
    X_train = X(1:split_idx, :);
    Y_train = Y(1:split_idx, :);
    X_test = X(split_idx+1:end, :);
    Y_test = Y(split_idx+1:end, :);
end
