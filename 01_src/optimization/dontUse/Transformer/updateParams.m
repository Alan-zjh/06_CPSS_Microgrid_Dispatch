function params = updateParams(params, grads, learning_rate)
    % 根据梯度更新参数
    for i = 1:length(params)
        params(i).Wq = params(i).Wq - learning_rate * grads(i).Wq;
        params(i).Wk = params(i).Wk - learning_rate * grads(i).Wk;
        params(i).Wv = params(i).Wv - learning_rate * grads(i).Wv;
        params(i).Wo = params(i).Wo - learning_rate * grads(i).Wo;
        params(i).Wff1 = params(i).Wff1 - learning_rate * grads(i).Wff1;
        params(i).Wff2 = params(i).Wff2 - learning_rate * grads(i).Wff2;
    end
end
