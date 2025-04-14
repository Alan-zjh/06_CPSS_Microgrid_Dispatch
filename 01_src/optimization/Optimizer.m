classdef Optimizer < handle
    properties
        Algorithm        % 存储优化算法（如TD3、PPO等）
    end
    
    methods
        function obj = Optimizer(algorithmType, algorithmParams)
            switch algorithmType
                case 'TD3'
                    obj.Algorithm = TD3(algorithmParams);  % 例如TD3
                case 'Load'
                    obj.Algorithm = ;
                otherwise
                    error('Unknown algorithm type');
            end
        end
        
        function action = getAction(obj, state, train)
            action = obj.Algorithm.chooseAction(state, train);  % 根据状态选择最优动作
        end

        function train(obj, state, action, reward, nextState, done)
            
            % 存储当前经验到经验池
            obj.Algorithm.remember(state, action, reward, nextState, done);
            
            % 从经验池中采样并进行学习
            obj.Algorithm.learn();
        end
    end
end
