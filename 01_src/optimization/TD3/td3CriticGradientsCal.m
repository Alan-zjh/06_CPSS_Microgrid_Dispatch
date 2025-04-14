function [critic1_loss, critic2_loss, gradients_1, gradients_2] = td3CriticGradientsCal(critic1, critic2, states, actions, target)
            
            x = cat(1, states, actions);
            q1 = forward(critic1, x);
            q2 = forward(critic2, x);
            
            % 计算损失
            critic1_loss = mean((q1 - target).^2); % 均方误差损失
            critic2_loss = mean((q2 - target).^2);
            gradients_1 = dlgradient(critic1_loss, critic1.Learnables);
            gradients_2 = dlgradient(critic2_loss, critic2.Learnables);
end