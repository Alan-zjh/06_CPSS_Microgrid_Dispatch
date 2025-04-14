classdef BESS < handle & matlab.mixin.Copyable
    properties
        % 电池物理属性
        capRated      % 额定容量 (kWh)
        pRated         % 最大充放电功率 (kW)
        chargeEfficiency   % 充电效率 (%)
        dischargeEfficiency% 放电效率 (%)
        degradationRate    % 单位退化成本 (￥/kWh)

        % 电池运行状态
        capCurrent    % 当前容量 (kWh)
        pCurrent       % 当前充放电功率 (kW)
        degradationCost    % 累计退化成本 ($)
    end

    methods
        % 构造函数
        function obj = BESS(BessParams)
            % 初始化电池参数
            obj.capRated = BessParams.capRated;
            obj.pRated = BessParams.pRated;
            obj.chargeEfficiency = BessParams.chargeEfficiency;
            obj.dischargeEfficiency = BessParams.dischargeEfficiency;
            obj.degradationRate = BessParams.degradationRate;

            % 初始化运行状态
            obj.capCurrent = BessParams.capRated * 0.5; % 默认初始电量为50%
            obj.pCurrent = 0;
            obj.degradationCost = 0;
        end

        % 更新电池状态（充放电操作）
        function obj = updateState(obj, pCurrent, dt)
            % power_input: 外部输入功率 (kW，正值为充电，负值为放电)
            % dt: 时间步长

            % 限制输入功率在额定范围内
            obj.pCurrent = max(min(pCurrent, obj.pRated), -obj.pRated);

            % 根据效率计算实际充放电量
            if obj.pCurrent > 0
                % 充电
                energy_change = obj.pCurrent * obj.chargeEfficiency * dt;
            else
                % 放电
                energy_change = obj.pCurrent / obj.dischargeEfficiency * dt;
            end

            % 更新电池容量
            obj.capCurrent = obj.capCurrent + energy_change;

            % 限制电池容量在物理范围内
            obj.capCurrent = max(min(obj.capCurrent, obj.capRated), 0);

            % 累计退化成本（与充放电能量相关）
            obj.degradationCost = obj.degradationCost + abs(energy_change) * obj.degradationRate;
        end

    end
end
