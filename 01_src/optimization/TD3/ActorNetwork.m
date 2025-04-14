classdef ActorNetwork < handle
    properties
        % 网络
        network

        % 优化
        alpha
        iteration
        optimizer

        % 可视化
        monitor
        averageGrad
        averageSqGrad
    end
    
    methods
        function obj = ActorNetwork(actorParams)
            %{
                参数：
                actor_param = struct('alpha',  ,...        % 学习率
                                     'state_dim',  ,...    % 状态空间维度
                                     'action_dim',  ,...   % 动作空间维度
                                     'fc1_dim',  ,...      % 隐藏层1维度
                                     'fc2_dim',  )     % 隐藏层2维度
            %}
            % 网络定义
            layers = [
                featureInputLayer(actorParams.stateDim, 'Normalization', 'none', 'Name', 'input')
                fullyConnectedLayer(actorParams.fc1Dim, 'Name', 'fc1')
                reluLayer('Name', 'relu1')                 % ReLU 激活层
                fullyConnectedLayer(actorParams.fc2Dim, 'Name', 'fc2')
                reluLayer('Name', 'relu2')                 % ReLU 激活层
                fullyConnectedLayer(actorParams.actionDim, 'Name', 'output') % 输出层
                tanhLayer
            ];
            net = dlnetwork(layers);
            obj.network = initialize(net);

            % 学习率
            obj.alpha = actorParams.alpha;
            obj.iteration = 0;
            
            % 设置优化器
            obj.averageGrad = [];
            obj.averageSqGrad = [];

        end
        
        function action = forward(obj, state)
            action = forward(obj.network, state);
        end
        
        function updateParams(obj, gradients)
            % 使用 Adam 更新网络参数
            obj.iteration = obj.iteration + 1;
            [obj.network, obj.averageGrad, obj.averageSqGrad] = adamupdate( ...
                obj.network, gradients, obj.averageGrad, obj.averageSqGrad, obj.iteration, obj.alpha);
        end
        
        function updateTargetNetwork(obj, source_net, tau)
            obj_params = obj.network.Learnables;
            source_net_params = source_net.network.Learnables;
            for i = 1:height(obj_params)
                obj_params.Value{i} = tau * source_net_params.Value{i} + ...
                                 (1 - tau) * obj_params.Value{i};
            end
            obj.network.Learnables = obj_params;
        end

        
        function saveWeightMatrix(obj, checkpointFile)
            % 保存模型参数
            actorNetwork = obj;
            save(checkpointFile, 'actorNetwork');
        end
        
        function loadWeightMatrix(obj, checkpointFile)
            % 加载模型参数
            if isfile(checkpointFile)
                loadedData = load(checkpointFile);
                obj.network = loadedData.actorNetwork.network;
                obj.alpha = loadedData.actorNetwork.alpha; 
            else
                error('Checkpoint file not found.');
            end
        end
    end
end

