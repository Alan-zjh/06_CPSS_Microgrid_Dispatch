% % 创建一个结构体，包含 EV 的所有参数
% EV_params = struct( ...
%     'hasEV', 1, ...                 % 用户是否拥有电车
%     'C_rated', 50, ...              % 电池额定容量 (kWh)
%     'P_rated', 10, ...              % 最大充放电功率 (kW)
%     'degradationCostRate', 0.02 ... % 单位退化成本 (元/kWh)
% );
% % 使用结构体参数初始化 EV 对象
% ev = EV(EV_params);
% 
% % 查看初始化状态
% disp("是否拥有电车: " + ev.hasEV);
% disp("电池额定容量 (kWh): " + ev.C_rated);
% disp("初始电量 (kWh): " + ev.C_current);
% % 以 8 kW 的功率充电，持续 30 分钟，并设定电车未外出
% ev = ev.updateState(8, 0, 30);
% 
% % 显示更新后的状态
% disp("当前电池容量 (kWh): " + ev.C_current);
% disp("当前功率 (kW): " + ev.P_current);
% disp("是否外出: " + ev.isOut);

%% 空调测试
load('Params.mat');
disp(homeParams);

microHomeGrid = MicroHomeGrid(homeParams);

disp(homeParams);

% 仿真持续时间（24小时 * 3600秒 = 86400秒）
simulation_time = 24 * 3600; 
dt = 1;  % 每秒更新一次

data = readmatrix("e.xlsx");
result = zeros(ceil(size(data, 1) / 12), size(data, 2)); 
for i = 1:12:size(data, 1)-11  
    result((i-1)/12 + 1, :) = mean(data(i:i+11, :), 1);  
end
P_ins = result(:,7);
Tem = result(:,6);

% 初始化存储温度和功率数据的数组
T_indoor = zeros(1, simulation_time);   % 室内温度
T_outdoor = zeros(1, simulation_time);  % 室外温度
P_AC_array = zeros(1, simulation_time); % 空调功率
pIns = zeros(1, simulation_time);

timeLine = struct('timeSlot', 1, ...
    'timeslotDuration', 600);

hvacData = struct( ...
    'tempOut', 35, ...
    'pIns', 500, ...
    'pAC', 0, ...
    'timeLine', timeLine...
); ...

% 每秒更新系统状态，假设内部活动产生的热量和太阳辐射变化
for t = 1:simulation_time-1
    % 随机生成室外温度，范围在32°C到39°C之间
    disp("第"+num2str(t/3600)+"小时：");

    % 设定人员活动产生的热量和太阳辐射
    H_apo = 100;       % 每平方米产生的热量

    % 基于当前室内温度控制空调开关
    % if microHomeGrid.hvac.tempInd > 26
    %     microHomeGrid.hvac.sAC = 1;  % 室内温度高于26°C，开启空调
    % elseif microHomeGrid.hvac.tempInd < 24
    %     microHomeGrid.hvac.sAC = 0;  % 室内温度低于24°C，关闭空调
    % end

    % 更新 HVAC 系统
    hvacData.pIns = P_ins(floor(t/3600) + 1);
    hvacData.pAC = 0;
    hvacData.tempOut = Tem(floor(t/3600) + 1);
    microHomeGrid.hvac.updateState(hvacData, timeLine);

    % 记录当前时间的室内温度、室外温度和空调功耗
    T_indoor(t) = microHomeGrid.hvac.tempInd;
    disp("T_indoor:"+num2str(T_indoor(t)));
    T_outdoor(t) = microHomeGrid.hvac.tempOut;
    P_AC_array(t) = microHomeGrid.hvac.pCurrentAC;  % 记录空调每小时的功耗
    pIns(t) = hvacData.pIns;
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
hold on;
plot(1:simulation_time, pIns, '--', 'LineWidth', 2);
xlabel('时间 (秒)');
ylabel('空调功耗 (W)');
title('24小时内空调功率变化');
grid on;


%% 负载
% load('..\01_Data\Params\Params.mat');
% disp(homeParams);
% 
% microHomeGrid = MicroHomeGrid(homeParams);
% 
% disp(homeParams);
% 
% 
% % 假设我们有一组更新数据
% homeData = struct( ...
%     'loadsData', struct( ...
%         'isNeed', [1, 0, 1, 0, 1, 0], ...
%         'pCurve', {rand(1,10), [], rand(1,10), [], rand(1,10), []}), ...
%     'hvacData', struct( ...
%         'temp', 35, ...
%         'pIns', 500, ...
%         'pAC', 3000 ...
%         ) ...
% );
% timeLine = struct('timeSlot', 60);
% 
% % 更新家庭微电网的状态
% microHomeGrid = microHomeGrid.updateState(homeData, timeLine);
% 
% % 打印当前状态
% disp('Updated Load Power:');
% for i = 1:length(microHomeGrid.loadDevices)
%     disp(['Load ', microHomeGrid.loadDevices(i).loadName, ': ', num2str(microHomeGrid.loadDevices(i).pCurrent), ' W']);
% end
% 
% disp(['HVAC Indoor Temperature: ', num2str(microHomeGrid.hvac.tempInd), ' C']);