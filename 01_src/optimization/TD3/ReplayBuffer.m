classdef ReplayBuffer < handle
    properties
        memSize
        batchSize
        memCnt
        stateMemory
        actionMemory
        rewardMemory
        nextStateMemory
        terminalMemory
    end
    
    methods
        function obj = ReplayBuffer(bufferParams)
            %{
                参数：
                buffer_param = struct('max_size',  ,...        % 学习率
                                      'state_dim',  ,...       % 状态空间维度
                                      'action_dim',  ,...      % 动作空间维度
                                      'batch_size',  )         % 隐藏层2维度
            %}
            % 参数检查
            if bufferParams.maxSize <= 0 || bufferParams.stateDim <= 0 ...
                || bufferParams.actionDim <= 0 || bufferParams.batchSize <= 0
                error('All parameters must be positive integers.');
            end
            
            obj.memSize = bufferParams.maxSize;
            obj.batchSize = bufferParams.batchSize;
            obj.memCnt = 0;
            obj.stateMemory = dlarray(zeros(bufferParams.stateDim, bufferParams.maxSize),'CB');
            obj.actionMemory = dlarray(zeros(bufferParams.actionDim, bufferParams.maxSize),'CB');
            obj.rewardMemory = zeros(1, bufferParams.maxSize);
            obj.nextStateMemory = dlarray(zeros(bufferParams.stateDim, bufferParams.maxSize),'CB');
            obj.terminalMemory = false(1, bufferParams.maxSize);
            disp('ReplayBuffer initialized');
        end

        function obj = storeTransition(obj, state, action, reward, nextStates, done)
            % 存储经验
            memIdx = mod(obj.memCnt, obj.memSize) + 1;
            obj.stateMemory(:, memIdx) = state(:);
            obj.actionMemory(:, memIdx) = action(:);
            obj.rewardMemory(memIdx) = reward;
            obj.nextStateMemory(:, memIdx) = nextStates(:);
            obj.terminalMemory(memIdx) = done;
            obj.memCnt = obj.memCnt + 1;
        end
        
        function [states, actions, rewards, nextStates, terminals] = sampleBuffer(obj)
            if ~obj.ready()
                error('Not enough samples in the buffer to sample.');
            end
            
            memLen = min(obj.memCnt, obj.memSize);
            batch = randperm(memLen, obj.batchSize);
            states = obj.stateMemory(:, batch);
            actions = obj.actionMemory(:, batch);
            rewards = obj.rewardMemory(batch);
            nextStates = obj.nextStateMemory(:, batch);
            terminals = obj.terminalMemory(batch);
        end
        
        function isReady = ready(obj)
            isReady = obj.memCnt >= 1e4;
        end
    end
end
