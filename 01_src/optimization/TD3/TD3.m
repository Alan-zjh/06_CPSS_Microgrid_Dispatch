classdef TD3 < handle
    properties
        gamma
        actionOuNoise
        policyNoise
        policyNoiseClip
        delayTime
        updateTime
        checkpointDir
        
        stateDim
        actionDim

        actionSpaceLow
        actionSpaceHigh
        
        actor
        critic1
        critic2
        targetActor
        targetCritic1
        targetCritic2
        memory
    end
    
    methods
        function obj = TD3(td3Params)

            obj.gamma = td3Params.gamma;
            obj.stateDim = td3Params.stateDim;
            obj.actionDim = td3Params.actionDim;
            obj.actionOuNoise = zeros(obj.actionDim, 1);
            obj.policyNoise = td3Params.policyNoise;
            obj.policyNoiseClip = td3Params.policyNoiseClip;
            obj.delayTime = td3Params.delayTime;
            obj.updateTime = 0;
            obj.checkpointDir = td3Params.ckptDir;
            create_directory(obj.checkpointDir, {'Actor', 'Critic1', 'Critic2', 'Target_actor', ...
                             'Target_critic1', 'Target_critic2'});

            obj.actionSpaceLow = td3Params.actionSpaceLow;
            obj.actionSpaceHigh = td3Params.actionSpaceHigh;

            % 初始化网络
            obj.actor = ActorNetwork(td3Params.actorParams);
            obj.critic1 = CriticNetwork(td3Params.criticParams);
            obj.critic2 = CriticNetwork(td3Params.criticParams);
            
            obj.targetActor = ActorNetwork(td3Params.actorParams);
            obj.targetCritic1 = CriticNetwork(td3Params.criticParams);
            obj.targetCritic2 = CriticNetwork(td3Params.criticParams);
            
            obj.memory = ReplayBuffer(td3Params.bufferParams);
            obj.updateNetworkParameters(1.0);

        end
        
        function updateNetworkParameters(obj, tau)
            
            % 更新目标网络参数改
            obj.targetActor.updateTargetNetwork(obj.actor, tau);

            obj.targetCritic1.updateTargetNetwork(obj.critic1, tau);

            obj.targetCritic2.updateTargetNetwork(obj.critic2, tau);
        end
        
        function remember(obj, state, action, reward, next_state, done)
            obj.memory.storeTransition(state, action, reward, next_state, done);
        end
        
        function action = chooseAction(obj, observation, trainingMode)
            state = observation;
            if trainingMode
                if ~obj.memory.ready()
                    action = dlarray((rand(1,2)*2-1)', 'CB');
                    return;
                end
                % 生成OU噪声
                theta = 0.15; 
                sigma = 0.2 * exp(-obj.updateTime/1e4); % 指数衰减
                obj.actionOuNoise = obj.actionOuNoise - theta*obj.actionOuNoise + sigma*randn(size(obj.actionOuNoise));
                
                % 应用噪声
                baseAction = obj.actor.forward(state);
                noisyAction = baseAction + obj.actionOuNoise;
                action =  min(max(noisyAction, -1), 1);
            else
                action = obj.actor.forward(state);
            end
        end

        function action_ = scaleAction(obj, actionIn)
            actionIn = min(max(actionIn, -1), 1); 
            weight = (obj.actionSpaceHigh - obj.actionSpaceLow) / 2;
            bios = (obj.actionSpaceHigh + obj.actionSpaceLow) / 2;
            action_ = actionIn .* weight + bios;
        end
        
        function learn(obj)
            if ~obj.memory.ready()
                return;
            end

            [states, actions, rewards, nextStates, terminals] = obj.memory.sampleBuffer();
            
            % 计算目标策略网络
            nextActions = obj.targetActor.forward(nextStates);
            
            % 生成动作噪声
            noise = obj.policyNoise * randn(size(nextActions,1), 1); 
            noise = min(max(noise, -obj.policyNoiseClip), obj.policyNoiseClip);  % 限制噪声范围
            nextActions = min(max(nextActions + noise, -1), 1);  % 限制动作范围
            
            % 计算目标 Q 值
            q1_ = obj.targetCritic1.forward(nextStates, nextActions);
            q2_ = obj.targetCritic2.forward(nextStates, nextActions);
            
            % 处理终止状态
            q1_(terminals) = 0.0;
            q2_(terminals) = 0.0;
            
            % 计算最小 Q 值和目标
            criticVal = min(q1_, q2_);
            target = rewards + obj.gamma * criticVal;
            
            [~, ~, gradients1, gradients2] = dlfeval(@td3CriticGradientsCal, ...
                                            obj.critic1.network, obj.critic2.network, ...
                                            states, actions, target);

            obj.critic1.updateParams(gradients1);
            obj.critic2.updateParams(gradients2);
            
            % 延迟更新
            obj.updateTime = obj.updateTime + 1;
            
            if mod(obj.updateTime, obj.delayTime) ~= 0
                return;
            end
            
            % 更新 Actor 网络
            [~, gradients] = dlfeval(@td3ActorGradientsCal, obj.actor.network, obj.critic1.network, states);
            obj.actor.updateParams(gradients);
        
            % 更新目标网络参数
            obj.updateNetworkParameters(0.005);
        end
        
        function saveModels(obj, episode)
            % 检查目录并保存模型
            actorPath = fullfile(obj.checkpointDir, 'Actor', sprintf('TD3_actor_%d.mat', episode));
            obj.actor.saveWeightMatrix(actorPath);
            disp('保存 actor 网络成功！');
            
            targetActorPath = fullfile(obj.checkpointDir, 'Target_actor', sprintf('TD3_target_actor_%d.mat', episode));
            obj.targetActor.saveWeightMatrix(targetActorPath);
            disp('保存 target_actor 网络成功！');
            
            critic1Path = fullfile(obj.checkpointDir, 'Critic1', sprintf('TD3_critic1_%d.mat', episode));
            obj.critic1.saveWeightMatrix(critic1Path);
            disp('保存 critic1 网络成功！');
            
            targetCritic1Path = fullfile(obj.checkpointDir, 'Target_critic1', sprintf('TD3_target_critic1_%d.mat', episode));
            obj.targetCritic1.saveWeightMatrix(targetCritic1Path);
            disp('保存 target critic1 网络成功！');
            
            critic2Path = fullfile(obj.checkpointDir, 'Critic2', sprintf('TD3_critic2_%d.mat', episode));
            obj.critic2.saveWeightMatrix(critic2Path);
            disp('保存 critic2 网络成功！');
            
            targetCritic2Path = fullfile(obj.checkpointDir, 'Target_critic2', sprintf('TD3_target_critic2_%d.mat', episode));
            obj.targetCritic2.saveWeightMatrix(targetCritic2Path);
            disp('保存 target critic2 网络成功！');
        end
        
        function loadModels(obj, episode)
            % 检查目录并加载模型
            actorPath = fullfile(obj.checkpointDir, 'Actor', sprintf('TD3_actor_%d.mat', episode));
            obj.actor.loadWeightMatrix(actorPath);
            disp('加载 actor 网络成功！');
            
            targetActorPath = fullfile(obj.checkpointDir, 'Target_actor', sprintf('TD3_target_actor_%d.mat', episode));
            obj.targetActor.loadWeightMatrix(targetActorPath);
            disp('加载 target_actor 网络成功！');
            
            critic1Path = fullfile(obj.checkpointDir, 'Critic1', sprintf('TD3_critic1_%d.mat', episode));
            obj.critic1.loadWeightMatrix(critic1Path);
            disp('加载 critic1 网络成功！');
            
            targetCritic1Path = fullfile(obj.checkpointDir, 'Target_critic1', sprintf('TD3_target_critic1_%d.mat', episode));
            obj.targetCritic1.loadWeightMatrix(targetCritic1Path);
            disp('加载 target critic1 网络成功！');
            
            critic2Path = fullfile(obj.checkpointDir, 'Critic2', sprintf('TD3_critic2_%d.mat', episode));
            obj.critic2.loadWeightMatrix(critic2Path);
            disp('加载 critic2 网络成功！');
            
            targetCritic2Path = fullfile(obj.checkpointDir, 'Target_critic2', sprintf('TD3_target_critic2_%d.mat', episode));
            obj.targetCritic2.loadWeightMatrix(targetCritic2Path);
            disp('加载 target critic2 网络成功！');
        end
    end
end
