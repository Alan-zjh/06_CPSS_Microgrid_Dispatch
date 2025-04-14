 classdef HvacSystem < handle & matlab.mixin.Copyable
    properties
        % 房间和物理属性
        c                   % 空气的比热容 (J/kg·K)
        rho                 % 空气密度 (kg/m^3)
        volumeRoom          % 房间体积 (m^3)
        areaRoom            % 房间表面积 (m^2)
        areaWindow          % 窗户面积 (m^2)
        areaSurface         % 传热表面积（墙壁等）(m^2)
        k                   % 建筑外围护结构的传热系数 (W/m^2·K)
        ventilationRate     % 空气交换率
        epsilon             % 人员活动每平方米产生的热量
        solarGainCoeff      % 窗户辐射折射率

        % 空调属性
        pRated              % 空调的额定功率 (W)
        pStandby            % 空调待机功率 (W)
        COP                 % 空调性能系数 (基于温差)

        % 环境条件
        tempOut             % 室外温度 (℃)
        tempInd             % 室内温度 (℃)

        % 空调状态
        isACOn              % 空调开关状态 (1=开启，0=关闭)
        mode                % 空调模式 (1=制冷，0=制热)
        pCurrentAC          % 空调实时功耗 (W)
    end

    methods
        % 构造函数，接受结构体参数初始化类
        function obj = HvacSystem(HvacParams)
            
            %{ 
                参数：
                hvacParams = struct( ...
                    'c', 1005, ...                  % 空气的比热容 (J/kg·K)
                    'rho', 1.205, ...               % 空气密度 (kg/m^3)
                    'volumeRoom', 300, ...              % 房间体积 (m^3)
                    'areaRoom', 100, ...              % 房间表面积 (m^2)
                    'areaWindow', 10, ...             % 窗户面积 (m^2)
                    'areaS', 120, ...                 % 传热表面积（墙壁等）(m^2)
                    'K', 3.3, ...                   % 建筑外围护结构的传热系数 (W/m^2·K)
                    'n_ex', 1, ...                  % 空气交换率
                    'Epsilon', 2.1, ...             % 人员活动每平方米产生的热量 (W/m^2)
                    'solar_gain_coeff', 0.5, ...    % 辐射衰减率
                    'pRated', 3800, ...             % 空调的额定功率 (W)
                    'P_stdb', 30, ...               % 空调待机功率 (W)
                    'T_out', 35, ...                % 室外温度 (℃)
                    'T_ind', 25 ...                 % 室内初始温度 (℃)
                );
            %}

            % 使用结构体中的参数初始化
            obj.c = HvacParams.c;
            obj.rho = HvacParams.rho;
            obj.volumeRoom = HvacParams.volumeRoom;
            obj.areaRoom = HvacParams.areaRoom;
            obj.areaWindow = HvacParams.areaWindow;
            obj.areaSurface = HvacParams.areaSurface;
            obj.k = HvacParams.k;
            obj.ventilationRate = HvacParams.ventilationRate;
            obj.epsilon = HvacParams.epsilon;
            obj.solarGainCoeff = HvacParams.solarGainCoeff;

            % 初始化空调属性
            obj.pRated = HvacParams.pRated;
            obj.pStandby = HvacParams.pStandby;
            obj.COP = 4.5;

            % 环境温度和初始状态
            obj.tempOut = HvacParams.tempOut;
            obj.tempInd = HvacParams.tempInd; 
            obj.isACOn = 0;              % 默认空调初始为关闭状态
            obj.mode = 1;
            obj.pCurrentAC = 0;              % 初始空调功耗为0
        end

        % 更新室内温度
        function updateTemperature(obj, hGain)
            % 房间的热量损失
            hLoss = obj.k * obj.areaSurface * (obj.tempInd - obj.tempOut) + ...
                     obj.c * obj.rho * obj.volumeRoom * obj.ventilationRate * (obj.tempInd - obj.tempOut) / 3600;
            
            % 计算室内温度变化率 (K/s)
            dT_dt = (hGain - hLoss) / (obj.c * obj.rho * obj.volumeRoom);
            
            % 更新室内温度，使用时间步长 dt (秒)
            obj.tempInd = obj.tempInd + dT_dt;
        end

        % 计算空调功耗和性能系数 COP
        function updateAC(obj, pAC)
            % 计算空调性能系数 COP，根据室内外温差动态调整
            % deltaT = abs(obj.T_ind - obj.T_out);
            % obj.COP = max(2.5, 4 - 0.05 * deltaT);  % 基于温差调整COP

            % 判断空调状态并计算功耗
            if obj.isACOn == 1
                % 空调开启时
                obj.pCurrentAC = min(max(pAC, -obj.pRated), obj.pRated); % 考虑空调的能效
            else
                % 空调关闭或待机时
                obj.pCurrentAC = obj.pStandby;
            end
        end

        % 计算总热量增益
        function H_gain = calculateHeatGain(obj, pIns)
            % 由空调带来的冷却或制热效果
            hAC = obj.isACOn .* ( -obj.pCurrentAC) * obj.COP; % 空调带来的冷量，负值表示移除热量
            
            % 由室内活动产生的热量
            hApo = obj.epsilon * obj.areaRoom;
            
            % 太阳辐射产生的热量
            hSolar = pIns * obj.areaWindow * obj.solarGainCoeff;
            
            % 总热量增益
            H_gain = hAC + hApo + hSolar;
        end

        % 更新系统状态
        function updateState(obj, hvacData,timeLine)

            obj.tempOut = hvacData.tempOut;
            obj.isACOn = abs(hvacData.pAC) > 50;
            obj.mode = hvacData.pAC > 0 && obj.isACOn;
            % 计算空调功耗和COP
            obj.updateAC(hvacData.pAC);

            % 计算热量增益
            H_gain = obj.calculateHeatGain(hvacData.pIns);
            
            % 更新室内温度
            for i = 1 : timeLine.timeslotDuration
                obj.updateTemperature(H_gain);
            end

        end
    end
end
