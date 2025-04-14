classdef Trainer
    methods
        function train(model, X_train, Y_train, num_epochs, learning_rate)
            for epoch = 1:num_epochs
                epoch_loss = 0;
                for i = 1:size(X_train, 1)
                    % 获取当前样本
                    X_enc = X_train{i, 1};
                    X_dec = X_train{i, 2};
                    Y_true = Y_train{i};
                    
                    % 前向传播
                    Y_pred = model.forward(X_enc, X_dec);
                    
                    % 计算损失（均方误差）
                    loss = mean((Y_pred - Y_true).^2, 'all');
                    epoch_loss = epoch_loss + loss;
                    
                    % 反向传播和更新参数 (占位符，实际需要实现每层的梯度更新)
                    % 例如：model.encoder_layers{i}.attention.Wq = model.encoder_layers{i}.attention.Wq - learning_rate * dWq;
                    % 这里是简化的示例，你需要在各层实现反向传播逻辑
                end
                
                fprintf('Epoch %d/%d, Loss: %.4f\n', epoch, num_epochs, epoch_loss / size(X_train, 1));
            end
        end
    end
end
