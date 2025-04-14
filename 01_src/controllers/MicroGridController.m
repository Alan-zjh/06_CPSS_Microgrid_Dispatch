classdef MicroGridController < handle
     
    properties 

        microGridModel
        updateData
        simulation

        commOptimizer
        homeOptimizer
        hvacOptimizer

    end
    
    methods
        function obj = MicroGridController(controllerParams)
            if isfield(controllerParams, 'model')
                obj.microGridModel = controllerParams.model;
                homeDataArray = arrayfun(@(homeIdx) struct( ...
                    'loadsData', repmat(struct(), length(obj.microGridModel.microHomeGrid(homeIdx).loadArray), 1),...
                    'evData', struct(), ...
                    'hvacData', struct() ...
                ), 1:length(obj.microGridModel.microHomeGrid), 'UniformOutput', false);
                obj.updateData = struct( ...
                    'homeData', [homeDataArray{:}]', ...  % 家庭数据
                    'bessData', struct(), ...  % 储能数据
                    'pvData', struct(), ...  % 光伏数据
                    'timeLine', struct() ...
                );
            else
                error('无模型');
            end

            if isfield(controllerParams, 'simulation')
                obj.simulation = controllerParams.simulation;
            end
            
            if isfield(controllerParams, 'commParams')
                disp("For Community Optimizer");
                obj.commOptimizer = TD3(controllerParams.commParams);
            end
            
            if isfield(controllerParams, 'homeParams')
                disp("For Home Optimizer");
                if isfield(controllerParams.homeParams, 'homeLoadParams')
                % obj.homeOptimizer = Optimizer();
                end
                if isfield(controllerParams.homeParams, 'homeTd3Params')
                    obj.hvacOptimizer = arrayfun(@(x) TD3(x), controllerParams.homeParams.homeTd3Params);
                end
            end
        end
        
        function resultArray = runLoadOptimization(obj,selectedIndices)

            resultArray = struct(...
                'microGrid', repmat(obj.microGridModel.copy(), obj.simulation.timeLine.totalTimeslot, 1) ...
            );

            % 初始化状态
            numLoads = length(obj.microGridModel.microHomeGrid(1).loadArray);
            maxDelay = 144; % 最大推迟时隙数
            
            loadQueues = struct(...
                'demands', cell(length(selectedIndices),numLoads), ...    % 待处理需求队列
                'lossMatrix', cell(length(selectedIndices),numLoads), ... % 损失矩阵
                'optSlots', cell(length(selectedIndices),numLoads), ...    % 最优时隙数组
                'startSlots', cell(length(selectedIndices),numLoads) ...    % 需求起始时隙数组
            );
            obj.microGridModel.reset();
            obj.resetUpdateData();
            obj.simulation.timeLine.currentTimeslot = 1;

            done = false;
            while(~done)
                currentTimeslot = obj.simulation.timeLine.currentTimeslot;
                for hIdx = 1:length(selectedIndices)
                    homeNo = selectedIndices(hIdx);
                    newLoadDemand = obj.simulation.getLoadDemand(homeNo, currentTimeslot);
                    for loadIdx = 1:length(newLoadDemand)
                        if ~isempty(newLoadDemand(loadIdx).pCurve)
                            % 步骤1：计算该需求的损失矩阵和初始最优时隙
                            [optSlot, lossVec] = computeLoss( ...
                                obj, newDemand(loadIdx), currentTimeslot, maxDelay ...
                                );
                            
                            % 步骤2：更新负载队列
                            if ~isempty(loadQueues(hIdx, loadIdx).demands)
                                % 队列为空时直接加入
                                loadQueues(hIdx,loadIdx).demands = newDemand(loadIdx);
                                loadQueues(hIdx,loadIdx).lossMatrix = lossVec;
                                loadQueues(hIdx,loadIdx).optSlots = optSlot;
                                loadQueues(hIdx,loadIdx).startSlots = currentTimeslot;
                            else
                                % 队列非空时的追加操作
                                loadQueues(hIdx, loadIdx).demands(end+1) = newDemands(loadIdx);
                                loadQueues(hIdx, loadIdx).lossMatrix(end+1, :) = lossVec;
                                loadQueues(hIdx, loadIdx).startSlots(end+1) = currentTimeslot;

                                [optSlots] = optimizeMultiLoadDP(...
                                    loadQueues(hIdx, loadIdx).lossMatrix,...
                                    [loadQueues(hIdx, loadIdx).demands.duration],...
                                    maxDelay...
                                );

                                loadQueues(hIdx, loadIdx).optSlots = optSlots;
                            end

                        end
                    end
                end

                for hIdx = 1:numHomes
                    homeData = struct('load', []);
                    for loadIdx = 1:numLoadsPerHome
                        % 获取当前负载的最优时隙
                        optSlot = loadQueues(hIdx, loadIdx).optSlots(1);
                        
                        % 检查是否到达执行时隙
                        if optSlot == currentTimeslot
                            % 应用该负载的电力曲线
                            duration = loadQueues(hIdx, loadIdx).demands(1).duration;
                            homeData.load(loadIdx).power = ...
                                loadQueues(hIdx, loadIdx).demands(1).pCurve;
                            
                            % 更新队列（移除已执行的需求）
                            loadQueues(hIdx, loadIdx).demands(1) = [];
                            loadQueues(hIdx, loadIdx).lossMatrix(1,:) = [];
                            loadQueues(hIdx, loadIdx).optSlots(1) = [];
                            loadQueues(hIdx, loadIdx).startSlots(1) = [];
                        else
                            homeData.load(loadIdx).power = [];
                        end
                    end
                    obj.updateData.home(hIdx) = homeData;
                end


                obj.microGridModel.updateState(obj.updateData);
                resultArray.microGrid(currentTimeslot) = deepCopy(obj.microGridModel);
                obj.simulation.timeLine.currentTimeslot = obj.simulation.timeLine.currentTimeslot + 1;
                isTimeOut = obj.simulation.timeLine.currentTimeslot > obj.simulation.timeLine.totalTimeslot;

                if isTimeOut
                    done = 1;
                end
            end
                        % 动态规划优化
            % function [optSlots, totalLoss] = optimizeWithDP(lossMatrix, durations)
            %     % 输入：
            %     %   lossMatrix - N×T矩阵，N个需求在T个时隙的损失值
            %     %   durations  - N-1个元素的数组，前N-1个需求的持续时间
            % 
            %     [N, T] = size(lossMatrix);
            %     dp = zeros(N, T) + inf;    % DP矩阵
            %     path = zeros(N, T);        % 路径记录
            % 
            %     % 初始化第一行
            %     dp(1, :) = lossMatrix(1, :);
            % 
            %     % 递推计算
            %     for n = 2:N
            %         prevDuration = durations(n-1);
            %         for t = 1:T
            %             % 允许的起始时间范围（前一个需求结束后）
            %             validStart = max(1, t - prevDuration + 1);
            %             [minVal, idx] = min(dp(n-1, 1:validStart) + lossMatrix(n, t));
            %             if ~isempty(minVal)
            %                 dp(n, t) = minVal;
            %                 path(n, t) = idx;
            %             end
            %         end
            %     end
            % 
            %     % 回溯路径
            %     [totalLoss, lastT] = min(dp(N, :));
            %     optSlots = zeros(1, N);
            %     optSlots(N) = lastT;
            % 
            %     for n = N-1:-1:1
            %         optSlots(n) = path(n+1, optSlots(n+1));
            %     end
            % end
            % % 计算损失值
            % function [optSlot, lossVec] = computeLoss(obj, demand, currentSlot)
            %     % 获取预测时间范围
            %     forecastHorizon = obj.simulation.timeLine.totalTimeslot - currentSlot + 1;
            % 
            %     % 预分配损失向量
            %     lossVec = zeros(1, forecastHorizon);
            % 
            %     % 遍历每个可能的启动时隙
            %     for offset = 0:forecastHorizon-1
            %         startSlot = currentSlot + offset;
            %         endSlot = startSlot + demand.duration - 1;
            % 
            %         % 检查是否越界
            %         if endSlot > obj.simulation.timeLine.totalTimeslot
            %             lossVec(offset+1) = inf;
            %             continue;
            %         end
            % 
            %         % 计算该时隙的损失值（示例计算，需根据实际模型实现）
            %         lossVec(offset+1) = sum(...
            %             obj.microGridModel.predictPowerCost(startSlot:endSlot) .* demand.powerProfile ...
            %         );
            %     end
            % 
            %     % 找到最小损失时隙
            %     [~, optSlot] = min(lossVec);
            %     optSlot = currentSlot + optSlot - 1;
            % end

        end
        
        function resultArray = runBessOptimization(obj)
            resultArray = struct(...
                'microGrid', repmat(obj.microGridModel.copy(), obj.simulation.timeLine.totalTimeslot, 1) ...
            );
            obj.microGridModel.reset();
            obj.resetUpdateData();
            obj.simulation.timeLine.currentTimeslot = 1;
            done = false;
            while(~done)
                currentTimeslot = obj.simulation.timeLine.currentTimeslot;
                obj.updateData.timeLine = obj.simulation.timeLine;
                newload = obj.simulation.getLoadDemand(homeNo, currentTimeslot);
                
                resultArray.microGrid(currentTimeslot) = deepCopy(obj.microGridModel);
                obj.simulation.timeLine.currentTimeslot = obj.simulation.timeLine.currentTimeslot + 1;
                isTimeOut = obj.simulation.timeLine.currentTimeslot >= obj.simulation.timeLine.totalTimeslot;
                if isTimeOut
                    done = 1;
                end
            end
        end
                                                                           
        function resultArray = trainHvac(obj, maxEpisodes,selectedIndices)
            
            numAgents = length(obj.hvacOptimizer);
            totalTimeslot = obj.simulation.timeLine.totalTimeslot;
            resultArray = struct(...
                'microGridParams',   cell(maxEpisodes,1), ... 
                'reward',            cell(maxEpisodes,1), ... 
                'loss',             cell(maxEpisodes,1), ... 
                'PMV',              cell(maxEpisodes,1), ... 
                'lastMicroGrid',    [] ...                   
            );

            % 2. 预分配优化 
            for ep = 1:maxEpisodes
                resultArray(ep).reward = zeros(totalTimeslot, numAgents, 'single');
                resultArray(ep).PMV = zeros(totalTimeslot, numAgents, 'single');
                resultArray(ep).microGridParams = repmat( ...
                    struct('pCurrentAC', 0, 'tempInd', 0, 'tempOut', 0) ...
                    , totalTimeslot, numAgents);

            end
            
            function params = extractMicroGridParams(mg, selectedIndices)
                params = struct(...
                    'pCurrentAC',   single(arrayfun(@(x) x.hvac.pCurrentAC, mg.microHomeGrid(selectedIndices))), ...
                    'tempInd',  single(arrayfun(@(x) x.hvac.tempInd, mg.microHomeGrid(selectedIndices))), ...
                    'tempOut',  single(arrayfun(@(x) x.hvac.tempOut, mg.microHomeGrid(selectedIndices))) ...
                );
            end
            
            state = cell(numAgents, 1);
            action = cell(numAgents, 1);
            reward = zeros(numAgents, 1);
            nextState = cell(numAgents, 1);
            Mode = zeros(numAgents, 2); % 1：制冷，0：制热
            for episode = 1:maxEpisodes
                % 初始化环境
                obj.microGridModel.reset();
                obj.resetUpdateData();
                obj.simulation.timeLine.currentTimeslot = 1;
                done = false;
                resultArray(episode).microGridParams(1) = extractMicroGridParams(obj.microGridModel, selectedIndices);
                while(~done)
                    currentTimeslot = obj.simulation.timeLine.currentTimeslot;
                    obj.updateData.timeLine = obj.simulation.timeLine;
                    weatherData = obj.simulation.getWeather(currentTimeslot);
                    rhIn = weatherData(4) - 5;
                    elecPrice = obj.simulation.getElecPrice(mod(currentTimeslot - 1, 144) + 1);
                    for idx = selectedIndices
                        agent = obj.hvacOptimizer(idx);
                        home = obj.microGridModel.microHomeGrid(idx);
                        state{idx} = dlarray( ...
                            [home.hvac.tempInd; weatherData([2,5])'; rhIn; elecPrice; Mode(idx,1)], ...
                            'CB');
                        action{idx} = agent.chooseAction(state{idx}, true);
                        scaledAction = agent.scaleAction(action{idx}(1,1));
                        Mode(idx,2) = action{idx}(2,1) >= 0;
                        obj.updateData.homeData(idx).hvacData = struct( ...
                                'pAC', extractdata((Mode(idx,2)*2-1)*scaledAction), ...
                                'pIns', weatherData(2), ...    % 当前时段的辐照度
                                'tempOut', weatherData(5) ... % 当前时段的外界温度
                            );
                        % obj.updateData.homeData(idx).hvacData = struct( ...
                        %         'pAC', 0, ...
                        %         'pIns', weatherData(2), ...    % 当前时段的辐照度
                        %         'tempOut', weatherData(5) ... % 当前时段的外界温度
                        %     );
                    end

                    obj.microGridModel.updateState(obj.updateData);
                    weatherData = obj.simulation.getWeather(currentTimeslot + 1);

                    for idx = selectedIndices
                        agent = obj.hvacOptimizer(idx);
                        home = obj.microGridModel.microHomeGrid(idx);

                        PMV = calcPmv(home.hvac.tempInd, home.hvac.tempInd, 0.1, ...
                            rhIn, 1.2, 0.6);
                        if abs(PMV) < 0.5
                            reward1 = 0;
                        else
                            reward1 = -(abs(PMV)-0.5);
                        end

                        if Mode(idx,1) ~= Mode(idx,2)
                            reward2 = 0;
                        else
                            reward2 = 1;
                        end
                        if abs(PMV) > 1
                            if (resultArray(episode).microGridParams(currentTimeslot).pCurrentAC * PMV) < 0 
                                reward2 = reward2 - 2;
                            else
                                reward2 = reward2 - 0.5;
                            end
                        end
                        reward3 = -abs(home.hvac.pCurrentAC) * elecPrice / 1000;
                        reward(idx) = reward1 + 0.2 * reward2 + reward3 * 0.04;
                        resultArray(episode).reward(currentTimeslot,idx) = reward(idx);
                        resultArray(episode).PMV(currentTimeslot,idx) = PMV;
                        Mode(idx,1) =Mode(idx,2);
                        elecPrice = obj.simulation.getElecPrice(mod(currentTimeslot - 1, 144) + 1);
                        rhIn = weatherData(4) - 5;
                        nextState{idx} = dlarray( ...
                            [home.hvac.tempInd; weatherData([2,5])'; rhIn; elecPrice; Mode(idx,1)], ...
                            'CB');
                        
                        agent.memory.storeTransition( ...
                            state{idx}, action{idx}, reward(idx), nextState{idx}, done);

                        agent.learn();
                        if mod(episode, 200) == 0
                            if currentTimeslot == obj.simulation.timeLine.totalTimeslot - 1
                                agent.saveModels(episode);
                            end
                        end
                    end
                
                    obj.simulation.timeLine.currentTimeslot = obj.simulation.timeLine.currentTimeslot + 1;
                     resultArray(episode).microGridParams(currentTimeslot) = extractMicroGridParams(obj.microGridModel, selectedIndices);
                    isTimeOut = obj.simulation.timeLine.currentTimeslot >= obj.simulation.timeLine.totalTimeslot;
                    if isTimeOut
                        done = 1;
                    end
                end
                
            end

        end

        function resetUpdateData(obj)
            homeDataArray = arrayfun(@(homeIdx) struct( ...
                'loadsData', repmat(struct(), length(obj.microGridModel.microHomeGrid(homeIdx).loadArray), 1),...
                'evData', struct(), ...
                'hvacData', struct() ...
            ), 1:length(obj.microGridModel.microHomeGrid), 'UniformOutput', false);
            
            obj.updateData = struct( ...
                'homeData', [homeDataArray{:}]', ...  % 家庭数据
                'bessData', struct(), ...  % 储能数据
                'pvData', struct(), ...  % 光伏数据
                'timeLine', struct() ...
            );
        end
    end
end
