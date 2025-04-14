function [actor_loss, gradients] = td3ActorGradientsCal(actor,critic1, states)

            % 更新 Actor 网络
            new_actions = forward(actor, states);
            x = cat(1, states, new_actions);
            q1 = forward(critic1, x);
            
            % 计算 Actor 损失
            actor_loss = -mean(q1);
            gradients = dlgradient(actor_loss, actor.Learnables);
end