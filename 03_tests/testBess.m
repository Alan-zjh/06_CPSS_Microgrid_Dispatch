function testBess()
    % 数据加载
    load("02_data\01_input\Load\loadDataSet.mat","loadDataSet");
    load("02_data\01_input\PV\pvDataSet_26.5kW.mat","PV_Data");
    
    % 负荷数据整合
    homeLoad1 = loadDataSet{1:1008,1};
    homeLoad2 = loadDataSet{1009:2016,1};
    homeLoad3 = loadDataSet{2017:3024,1};
    homeAll = homeLoad1 + homeLoad2 + homeLoad3;
    
    % 光伏数据提取
    pvPower = PV_Data.mean_Active_Power(1:1008);
    
    % 初始化变量
    numSlots = 1008;
    pBess = zeros(numSlots,1);     % 储能功率（+充，-放）
    pGrid = zeros(numSlots,1);     
    
    % 储能系统参数
    capMin = 20;                 % kWh
    capMax = 100;
    capCurrent = 60;             
    pChargeMax = 30;            % kW
    pDischargeMax = 30;
    etaCharge = 0.95;            
    etaDischarge = 0.90;         
    deltaT = 1/6;                % 10分钟=1/6小时

    % 滚动时间窗配置（2小时窗口）
    windowSize = 12;             % 10分钟×12=120分钟
    peakWindow = [];              % 历史功率窗口存储器

    % 主优化循环
    for timeslot = 1:numSlots
        currentLoad = homeAll(timeslot)/1000;
        currentPv = pvPower(timeslot);
        netLoad = currentLoad - currentPv;
        
        % 获取窗口内历史峰值（前2小时）
        if timeslot > 1
            current_peak = max(peakWindow);
        else
            current_peak = 0;
        end
        
        % 统一优化
        [pBessOpt, ~] = unifiedOptimization(...
            netLoad, capCurrent, current_peak, ...
            pChargeMax, pDischargeMax, ...
            capMin, capMax, ...
            etaCharge, etaDischarge, ...
            deltaT);
        
        % 状态更新
        pBess(timeslot) = pBessOpt;
        pGrid(timeslot) = netLoad + pBessOpt;
        
        % SOC更新（考虑10分钟时隙）
        if pBessOpt > 0  % 充电
            capCurrent = capCurrent + pBessOpt * etaCharge * deltaT;
        elseif pBessOpt < 0  % 放电
            capCurrent = capCurrent + pBessOpt * etaDischarge * deltaT;
        end
        capCurrent = max(min(capCurrent, capMax), capMin);
        
        % 更新峰值窗口（保留最近2小时数据）
        peakWindow = [peakWindow, pGrid(timeslot)];
        if length(peakWindow) > windowSize
            peakWindow(1) = [];
        end
    end
    
    % 可视化
    figure;
    subplot(3,1,1);
    plot(homeAll), title('原始负荷');
    subplot(3,1,2);
    plot(pGrid), title('电网功率');
    subplot(3,1,3);
    plot(cumsum(pBess*deltaT)), title('储能SOC演化');
end

function [pBessOpt, newPeak] = unifiedOptimization(...
    netLoad, SOC, histPeak, ...
    pCMax, pDMax, socMin, socMax, ...
    etaC, etaD, dt)

    % 修正后的充放电能力计算
    chargeCapacity = min(pCMax, socMax - SOC)*etaC;
    dischargeCapacity = min(pDMax, SOC - socMin)*etaD;
    
    % 动态边界设置
    
    lb = -dischargeCapacity;  % 允许放电
    ub = chargeCapacity;      % 允许充电
    
    cvx_begin quiet
        variables pBess newPeak % 有符号变量
        minimize( newPeak )
        subject to:
            % pGridsum == pGridsum + net_load + pBess; % 过往功率约束
            pBess >= lb;                              % 充电/放电下界
            pBess <= ub;                              % 充电/放电上界
            newPeak >= netLoad + pBess;
            newPeak >= histPeak;
            newPeak >= 0;
            SOC + pBess*etaC*dt <= socMax;
            SOC + pBess*etaD*dt >= socMin;
    cvx_end
    
    % 异常处理
    if ~strcmp(cvx_status, 'Solved')
       % 安全策略：优先维持SOC在中间区域
        if SOC > (socMax + socMin)/2
            pBessOpt = min(charge_capacity, (socMax - SOC)*etaC/dt);
        else
            pBessOpt = -min(discharge_capacity, (SOC - socMin)*etaD/dt);
        end
        newPeak = max(histPeak, netLoad + pBessOpt);
    else
        pBessOpt = pBess;
    end
end
