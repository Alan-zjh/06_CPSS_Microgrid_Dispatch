function params = trainModel(X_train, Y_train, num_epochs, learning_rate, num_layers, d_model, num_heads, d_ff)
    [num_samples, seq_len] = size(X_train);
    
    params = initializeParams(seq_len, d_model, d_ff, num_heads, num_layers);

    for epoch = 1:num_epochs
        epoch_loss = 0;
        for i = 1:num_samples
            X = X_train(i, :);
            Y_true = Y_train(i);
            
            % 前向传播
            Y_pred = transformer(X, num_layers, num_heads, d_ff);
            
            % 计算损失，按元素平方
            loss = (Y_pred - Y_true).^2; 
            epoch_loss = epoch_loss + sum(loss);  % 累加损失
            
            % 计算梯度并更新参数
            grads = computeGradients(X, Y_true, Y_pred, params, num_layers, num_heads, d_ff);
            params = updateParams(params, grads, learning_rate);
        end
        fprintf('Epoch %d/%d, Loss: %.4f\n', epoch, num_epochs, epoch_loss / num_samples);
    end
end
