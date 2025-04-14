        
%================================================================
% 功能： Load 类用于存放家用负载实时参数
% 参数： loadType 、 loadName 、 pCurrent 、 pCurve 、 isNeed 、 isEnable 、
%        dispatchDelayTime 、 elapsedRunTime
% 备注： 无
% 调用方法： 直接调用
%================================================================
classdef Load < handle & matlab.mixin.Copyable
    properties
        loadType            % 负荷类型 ('uncontrollable', 'interruptible')
        loadName            % 电器名称
        pCurrent            % 当前功率 (kW)
        pCurve              % 用电功率曲线 (数组)

        isNeed              % 用户是否想要用该电器 (0=关闭, 1=想要)
        isEnable            % 是否启用

        dispatchDelayTime   % 调度延迟启用时间
        elapsedRunTime      % 已运行时间 (分钟), 仅对不可中断负荷有效
    end
    
    methods
        % 构造函数：接受结构体参数初始化
        function obj = Load(loadParams)

            % 参数：
            % loadParams = struct( ...
            %     'loadType', 'non_interruptible', ...
            %     'currentPower', 2.5, ...
            %     'isActive', 0, ...
            %     'minRunTime', 30, ...
            %     'elapsedRunTime', 0);

            % 参数验证：
            % arguments
            %     loadParams.loadType (1,1) string {mustBeMember(loadParams.loadType, ["uncontrollable", "interruptible", "non_interruptible"])}
            %     loadParams.pCurve (1,:) double = []  % 默认值 []
            %     loadParams.pCurrent (1,1) double = 0  % 默认值 0
            % end

            % 初始化属性
            obj.loadType = loadParams.loadType;
            obj.loadName = loadParams.loadName;
            obj.pCurve = [];
            obj.pCurrent = 0;
            
            obj.isNeed = 0;
            obj.isEnable = 0;

            obj.dispatchDelayTime = -1;
            obj.elapsedRunTime = 0;
        end
        
        % 更新负荷功率
        function obj = updateState(obj, loadData)
            % 参数:
            % - enable: 调度是否允许启用 (0/1)
            % - isNeed: 用户是否需要启用 (0/1)
            % - pCurve: 用电功率曲线 (数组)

            % 更新用户需求

            if loadData.isNeed
                obj.isNeed = 1;
                obj.dispatchDelayTime = 0;
                obj.pCurve = loadData.pCurve;
            end

             % 根据设备类型更新状态和功率
            switch obj.loadType
                case 'uncontrollable'
                    % 不可控负荷始终开启
                    obj.isEnable = 1;
                    obj.pCurrent = obj.pCurve;

                case 'interruptible'
                    % 可中断负荷：后续看需求要不要扩展
                    error('未定义该值');

                case 'non_interruptible'
                    % 不可中断负荷：一旦启动必须完成任务
                    if obj.isNeed
                        if ~obj.isEnable && loadData.enable
                            % 启动任务
                            obj.isEnable = 1;
                            obj.elapsedRunTime = 1;
                            obj.isNeed = 0;
                            obj.dispatchDelayTime = -1;
                        else
                            % 启动前增加等待时间
                            obj.dispatchDelayTime = obj.dispatchDelayTime + 1;
                        end
                    end
                    % 任务已启动
                    if obj.isEnable
                        if obj.elapsedRunTime <= length(obj.pCurve)
                            obj.pCurrent = obj.pCurve(obj.elapsedRunTime);
                            obj.elapsedRunTime = obj.elapsedRunTime + 1;
                        else
                            % 任务完成后自动关闭
                            obj.pCurrent = 0;
                            obj.isEnable = 0;
                            obj.pCurve = [];
                        end
                    else
                        obj.pCurrent = 0;
                    end
            end
            
        end
    end
end
