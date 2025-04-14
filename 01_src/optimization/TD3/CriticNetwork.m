classdef CriticNetwork < handle
      properties
        network      % 网络架构

        optimizer    % 优化器
        beta         % 学习率
        iteration

        monitor
        averageGrad
        averageSqGrad
    end
    
    methods
        function obj = CriticNetwork(criticParams)
            %{
                参数：
                critic_param = struct('beta',  ,...        % 学习率
                                      'state_dim',  ,...    % 状态空间维度
                                      'action_dim',  ,...   % 动作空间维度
                                      'fc1_dim',  ,...      % 隐藏层1维度
                                      'fc2_dim',  )     % 隐藏层2维度
            %}
            layers = [
                featureInputLayer((criticParams.stateDim + criticParams.actionDim), 'Normalization', 'none', 'Name', 'input')
                fullyConnectedLayer(criticParams.fc1Dim, 'Name', 'fc1')
                layerNormalizationLayer('Name', 'in1')  % 归一化层
                reluLayer('Name', 'relu1')                 % ReLU 激活层
                fullyConnectedLayer(criticParams.fc2Dim, 'Name', 'fc2')
                layerNormalizationLayer('Name', 'in2')  % 归一化层
                reluLayer('Name', 'relu2')                 % ReLU 激活层
                fullyConnectedLayer(1, 'Name', 'q') % 输出层
            ];
            net = dlnetwork(layers);
            obj.network = initialize(net);

            obj.beta = criticParams.beta;
            obj.iteration = 0;

            obj.averageGrad = [];
            obj.averageSqGrad = [];
        end
        
        
        function q = forward(obj, state, action)
            x = cat(1, state, action);
            q = forward(obj.network, x);
        end

        function updateParams(obj, gradients)
            % 使用 Adam 更新网络参数
            obj.iteration = obj.iteration + 1;
            [obj.network, obj.averageGrad, obj.averageSqGrad] = adamupdate( ...
                obj.network, gradients, obj.averageGrad, obj.averageSqGrad, obj.iteration, obj.beta);
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


        function saveWeightMatrix(obj, WeightMatrix)
            % 保存模型参数
            criticNetwork = obj;
            save(WeightMatrix, 'criticNetwork');
        end
        
        function loadWeightMatrix(obj, WeightMatrix)
            % 加载模型参数
            if isfile(WeightMatrix)
                loadedData = load(WeightMatrix);
                obj.network = loadedData.criticNetwork.network;
                obj.beta = loadedData.criticNetwork.beta; 
            else
                error('Checkpoint file not found.');
            end
        end
    end
end
