classdef ElecVehicle < handle & matlab.mixin.Copyable
    properties
        % 电车基本属性
        capRated            % 电池额定容量 (kWh)
        pRated              % 最大充放电功率 (kW)
        capCurrent          % 当前容量 (kWh)
        pCurrent            % 当前功率 (kW)
        isOut               % 是否外出 (1=外出, 0=在家)
        isDispatchable      % 是否用于调度
        % 电池相关参数
        chargeEfficiency    % 充电效率 (0~1)
        dischargeEfficiency % 放电效率 (0~1)
        
        homeConsumption     % 家用部分耗电量
    end
    
    methods
        
        % 构造函数（接受结构体参数）
        function obj = ElecVehicle(evParams)
            % 使用结构体字段初始化
            obj.capRated = evParams.capRated;
            obj.pRated = evParams.pRated;
            obj.capCurrent = evParams.capRated * 0.7; % 初始电量为额定容量的70%
            obj.pCurrent = 0;
            obj.isOut = 0;
        end
        
        % 更新电车状态
        function obj = updateState(obj, EVData, timescale)
            % 更新外出状态
            obj.isOut = EVData.isOut;

            % 更新功率
            obj.pCurrent = min(max(EVData.pCurrent, -obj.pRated), obj.pRated); % 限制在额定功率范围
            if obj.isOut
                % 更新当前容量 (考虑充放电)
                obj.capCurrent = obj.capCurrent - EVData.capCost;
            else
                obj.capCurrent = obj.capCurrent + (obj.pCurrent * timescale / 60); % dt为分钟，需换算为小时
            end
            obj.isDispatchable = obj.capCurrent / obj.capRated >= 50;
            % 限制容量范围
            obj.capCurrent = max(min(obj.capCurrent, obj.capRated), 0);
            
        end
        
    end
end
