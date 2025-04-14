clc;
clear;
data = readmatrix("e.xlsx");
result = zeros(ceil(size(data, 1) / 12), size(data, 2)); 
for i = 1:12:size(data, 1)-11  
    result((i-1)/12 + 1, :) = mean(data(i:i+11, :), 1);  
end
P_ins = result(:,7);
Tem = result(:,6);

% 定义结构体包含初始化参数
HVAC_params = struct( ...
    'c', 1005, ...            % 空气的比热容 (J/kg·K)
    'rho', 1.205, ...         % 空气密度 (kg/m^3)
    'V_room', 300, ...        % 房间体积 (m^3)
    'A_room', 100, ...        % 房间表面积 (m^2)
    'A_window', 10, ...       % 窗户面积 (m^2)
    'A_s', 120, ...           % 传热表面积（墙壁等）(m^2)
    'K', 0.6, ...             % 建筑外围护结构的传热系数 (W/m^2·K)
    'n_ex', 1, ...          % 空气交换率
    'Epsilon', 2.1, ...       % 人员活动每平方米产生的热量 (W/m^2)
    'solar_gain_coeff', 0.2, ... %
    'P_rate', 3800, ...       % 空调的额定功率 (W)
    'P_stdb', 30, ...         % 空调待机功率 (W)
    'T_out', 35, ...          % 室外温度 (℃)
    'T_ind', 25 ...           % 室内初始温度 (℃)
);

% 创建 HVAC 对象，使用结构体参数
hvac = HVAC(HVAC_params);

% 仿真持续时间（24小时 * 3600秒 = 86400秒）
simulation_time = 24 * 3600; 
dt = 1;  % 每秒更新一次

% 初始化存储温度和功率数据的数组
T_indoor = zeros(1, simulation_time);   % 室内温度
T_outdoor = zeros(1, simulation_time);  % 室外温度
P_AC_array = zeros(1, simulation_time); % 空调功率

% 每秒更新系统状态，假设内部活动产生的热量和太阳辐射变化
for t = 1:simulation_time-1
    % 随机生成室外温度，范围在32°C到39°C之间
    disp("第"+num2str(t/3600)+"小时：");
    hvac.T_out = Tem(floor(t/3600) + 1);
    
    % 设定人员活动产生的热量和太阳辐射
    H_apo = 100;       % 每平方米产生的热量
    
    % 基于当前室内温度控制空调开关
    if hvac.T_ind > 26
        hvac.s_AC = 1;  % 室内温度高于26°C，开启空调
    elseif hvac.T_ind < 24
        hvac.s_AC = 0;  % 室内温度低于24°C，关闭空调
    end
    
    % 更新 HVAC 系统
    hvac = hvac.updateSystem(P_ins(floor(t/3600) + 1), dt);
    
    % 记录当前时间的室内温度、室外温度和空调功耗
    T_indoor(t) = hvac.T_ind;
    disp("T_indoor:"+num2str(T_indoor(t)));
    T_outdoor(t) = hvac.T_out;
    P_AC_array(t) = hvac.P_AC;  % 记录空调每小时的功耗
end

% 绘制室内温度和室外温度随时间的变化
figure;
subplot(2,1,1);  % 上方子图为温度变化
plot(1:simulation_time, T_indoor, '-o', 'LineWidth', 2);
hold on;
plot(1:simulation_time, T_outdoor, '--', 'LineWidth', 2);
xlabel('时间 (秒)');
ylabel('温度 (°C)');
legend('室内温度', '室外温度');
title('24小时内室内和室外温度变化');
grid on;

% 绘制空调功率曲线随时间的变化
subplot(2,1,2);  % 下方子图为空调功率变化
plot(1:simulation_time, P_AC_array, '-x', 'LineWidth', 2, 'Color', 'r');
xlabel('时间 (秒)');
ylabel('空调功耗 (W)');
title('24小时内空调功率变化');
grid on;
