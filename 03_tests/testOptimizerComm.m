% 生成8个家庭的完整参数集（建筑+EV）并导出CSV
clear; clc;

% 基础参数模板
baseParams = struct(...
    'FamilyID', 0, ...          % 家庭编号
    'c', 1005, ...              % 空气比热容 [J/kg·K]
    'rho', 1.205, ...           % 空气密度 [kg/m³]
    'volumeRoom', 300, ...      % 房间体积 [m³]
    'areaRoom', 100, ...        % 房间面积 [m²]
    'areaWindow', 10, ...       % 窗户面积 [m²]
    'areaSurface', 120, ...     % 传热表面积 [m²]
    'k', 0.6, ...              % 传热系数 [W/m²·K]
    'ventilationRate', 1, ...   % 空气交换率 [ACH]
    'epsilon', 2.1, ...         % 人员产热 [W/m²]
    'solarGainCoeff', 0.3, ...  % 太阳得热系数
    'AC_pRated', 3800, ...     % 空调额定功率 [W] (添加AC前缀避免冲突)
    'AC_pStandby', 30, ...      % 空调待机功率 [W]
    'tempOut', 35, ...          % 室外温度 [℃]
    'tempInd', 25, ...          % 初始室内温度 [℃]
    'EV_Capacity', 60, ...      % 电池容量 [kWh]
    'EV_pMax', 50, ...          % 最大充放电功率 [kW]
    'EV_DegCost', 0.1, ...      % 退化成本 [$/cycle]
    'EV_EffCharge', 0.95, ...   % 充电效率
    'EV_EffDischarge', 0.95 ...% 放电效率
);

families(8) = baseParams;

for i = 1:8
    f = baseParams;
    f.FamilyID = i;
    
    %% 生成建筑参数
    % 体积-面积关联生成
    f.volumeRoom = 200 + 200*rand(); 
    f.areaRoom = f.volumeRoom / 3;
    f.areaWindow = f.areaRoom * (0.08 + 0.07*rand());
    
    % 传热表面积（基于立方体模型）
    edgeLength = (f.volumeRoom)^(1/3);
    f.areaSurface = 6*edgeLength^2 * (0.9 + 0.2*rand());
    
    % 热力学参数
    f.k = 0.5 + 0.2*rand(); 
    f.rho = 1.225 - 0.01*(f.tempOut-20); % 密度与温度关联
    f.c = 1005 + 20*randn(); 
    f.ventilationRate = 0.5 + rand();
    f.epsilon = 2.0 + 0.5*rand();
    f.solarGainCoeff = 0.25 + 0.1*rand();
    f.AC_pRated = randi([3000,4500]);
    f.AC_pStandby = 25 + 10*rand();
    f.tempOut = 33 + 4*rand();
    f.tempInd = 24 + 2*rand();
    
    %% 生成EV参数（带工程约束）
    % 电池容量与功率关联
    baseCapacity = 60*(0.9 + 0.2*rand());  % 54-66 kWh
    f.EV_Capacity = round(baseCapacity/2)*2; % 取偶数
    
    % 最大功率按C-rate生成（0.8-1.1C）
    C_rate = 0.8 + 0.3*rand();
    f.EV_pMax = min(round(baseCapacity * C_rate), 70); % 限制70kW
    
    % 退化成本与容量反比
    f.EV_DegCost = 0.08 + (60/baseCapacity)*0.04*rand(); 
    
    % 效率参数（充电放电独立）
    f.EV_EffCharge = 0.95 + 0.04*rand(); 
    f.EV_EffDischarge = 0.96 + 0.03*rand(); 
    
    families(i) = f;
end

% 转换为表格并格式化
familyTable = struct2table(families);

% 数值精度处理
roundConfig = {
    'volumeRoom',1; 'areaRoom',1; 'areaWindow',1; 'areaSurface',1;
    'rho',2; 'c',0; 'epsilon',2;
    'EV_Capacity',1; 'EV_pMax',1; 'EV_DegCost',2
    };

for cfg = 1:size(roundConfig,1)
    col = roundConfig{cfg,1};
    dec = roundConfig{cfg,2};
    familyTable.(col) = round(familyTable.(col), dec);
end

% 导出CSV文件
writetable(familyTable, './02_data/01_input/Params/household_parameters.csv');
