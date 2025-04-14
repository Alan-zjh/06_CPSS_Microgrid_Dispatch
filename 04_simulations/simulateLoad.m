clc;
clear;
%% 定义环境
% addpath('.\02_Model','..\04_Dispatch\');
load('.\02_data\01_input\Load\loadDataSet.mat');
load('.\02_data\01_input\PV\PVDataSet(1).mat');
load('.\02_data\01_input\Weather\WeatherDataSet.mat');
load('.\02_data\01_input\Params\Params.mat');

microHomeGrid = MicroHomeGrid(homeParams);
elecPrice = [7.8, 7.8, 7.8, 7.8, 7.8, 7.8, 7.8, ... 
            12.2, 12.2, 12.2, 12.2, 12.2, 12.2, 12.2, 12.2, 12.2,...
            28.6, 28.6, 28.6, 28.6, 28.6, ...
            12.2, 12.2, ...
            7.8 ...
];
elecPrice = repelem(elecPrice', 6);
elecPrice = [elecPrice; elecPrice];


timeLine = struct( ...
        'timeslotDuration', 600, ...
        'totalTimeslot', 2016, ...
        'currentTimeslot', 1 ...
);

results = struct( ...
    'totalLoad', zeros(timeLine.totalTimeslot, 1), ...
    'hvacLoad', zeros(timeLine.totalTimeslot, 2) ...
);
    
%% 环境循环
while(timeLine.currentTimeslot <= timeLine.totalTimeslot)
    currentSlot = timeLine.currentTimeslot;
    hvacData = struct( ...
        'pAC', 0, ...  % 随机生成空调功率
        'pIns', weatherDataSet(currentSlot, 2), ...  % 辐照度
        'tempOut', weatherDataSet(currentSlot, 4) ... % 外界温度
    );
    
    loadsData = struct([]);
    for i = 1:(length(microHomeGrid.loadArray) - 1)
        if currentSlot == 1
            prevLoad = 0;
        else
            prevLoad = loadDataSet{currentSlot-1, i+2};
        end
        currLoad = loadDataSet{currentSlot, i+2};

        loadCurve = loadDataSet{currentSlot:end, i+2};
        loadsData(i).isNeed = 0; 
        loadsData(i).enable = 1;
        loadsData(i).pCurve = [];
        if prevLoad < 50 && currLoad > 50 
            loadsData(i).isNeed = 1;
            % 获取当前负荷的用电功率曲线（持续到功率小于100）
            validRange = find(loadCurve <= 100,1);
            loadsData(i).pCurve = loadCurve(1:validRange,1);
        end
    end

    loadsData(6) = struct( ...
        'isNeed', 1, ...
        'enable', 1, ...
        'pCurve', loadDataSet{currentSlot,8} ...
    );

    homeData = struct( ...
        'hvacData', hvacData, ...
        'loadsData', loadsData ...
    );


    results.totalLoad(currentSlot) = microHomeGrid.pTotalDemand;
    results.hvacLoad(currentSlot,1) = microHomeGrid.hvac.pCurrentAC;
    results.hvacLoad(currentSlot,2) = microHomeGrid.hvac.tempInd;
    results.data(currentSlot) = homeData;
    for i = 1:length(microHomeGrid.loadArray)
        results.loadDevicesLoad(currentSlot, i) = microHomeGrid.loadArray(i).pCurrent;
    end
    microHomeGrid.updateState(homeData, timeLine);

    % reward = -abs(microHomeGrid.hvac.tempInd - 26) / 4 + action_ / 6000 * elecPrice(mod(currentSlot-1, 144) + 1) / 5;
    

    timeLine.currentTimeslot = timeLine.currentTimeslot + 1;
end
% 初始化 OutData 为一个空数组
OutData = struct('Index', [], 'LoadsData', [], 'No', 0, 'enableIndex', 0, 'reward', 0);

% 遍历 results.data
for i = 1:length(results.data)
    % 获取当前行的 loadsData
    currentLoadsData = results.data(i).loadsData;
    
    % 检查 loadsData 是否有非空的 pCurve
    for j = 1:length(currentLoadsData) - 1
        if ~isempty(currentLoadsData(j).pCurve)
            % 如果 pCurve 非空，记录当前行的索引和 loadsData
            currentPCurve = currentLoadsData(j).pCurve;
            newEntry.Index = i;                 % 当前行索引
            newEntry.No = j;
            newEntry.LoadsData = currentLoadsData(j); % 当前行的 loadsData
            minLoss = 1000;
            minEnableIndex = i;
            for time = i:i+144
                loss = abs(time-i) / 144 + sum((currentPCurve / 6000/9) .* ...
                        elecPrice(mod(time-1, 144) + 1: ...
                        mod(time-1, 144) +length(currentPCurve)));
                if loss < minLoss
                    minEnableIndex = time;
                    minLoss = loss;
                end
            end
            newEntry.enableIndex = minEnableIndex;
            newEntry.reward = minLoss;
            % 将新条目添加到 OutData
            OutData = [OutData; newEntry];
        end
    end
end

microHomeGridNext = MicroHomeGrid(homeParams);
timeLine = struct( ...
        'timeslotDuration', 600, ...
        'totalTimeslot', 2016, ...
        'currentTimeslot', 1 ...
);
resultsNext = struct( ...
    'totalLoad', zeros(timeLine.totalTimeslot, 1), ...
    'hvacLoad', zeros(timeLine.totalTimeslot, 2) ...
);
indexOutData = 2;
%% 环境循环
while(timeLine.currentTimeslot <= timeLine.totalTimeslot)
    currentSlot = timeLine.currentTimeslot;
    hvacData = struct( ...
        'pAC', 0, ...  % 随机生成空调功率
        'pIns', weatherDataSet(currentSlot, 2), ...  % 辐照度
        'tempOut', weatherDataSet(currentSlot, 4) ... % 外界温度
    );
    loadsData = struct( ...
        'isNeed', num2cell(zeros(1, 6)), ...
        'enable', num2cell(ones(1, 6)), ...
        'pCurve', cell(1, 6) ...
    );
    relevantData = OutData([OutData.enableIndex] == currentSlot);

    if ~isempty(relevantData)
        % 获取所有启动电器编号
        uniqueDevices = unique([relevantData.No]);
        for deviceNo = uniqueDevices
            % 找到该设备的所有启动数据
            deviceData = relevantData([relevantData.No] == deviceNo);

            % 取第一次启动数据
            loadsData(deviceNo).isNeed = 1;
            loadsData(deviceNo).enable = 1;
            loadsData(deviceNo).pCurve = deviceData(1).LoadsData.pCurve;

            % 记录重复启动信息（如有）
            if length(deviceData) > 1
                fprintf('电器 %d 在时隙 %d 有 %d 次启动\n', ...
                    deviceNo, currentSlot, length(deviceData));
                repeatStart(currentSlot, deviceNo) = length(deviceData);
            end
        end
    end

    % 设置电器6的负荷
    loadsData(6) = struct( ...
        'isNeed', 1, ...
        'enable', 1, ...
        'pCurve', loadDataSet{currentSlot, 8} ...
    );


    loadsData(6) = struct( ...
        'isNeed', 1, ...
        'enable', 1, ...
        'pCurve', loadDataSet{currentSlot,8} ...
    );

    homeData = struct( ...
        'hvacData', hvacData, ...
        'loadsData', loadsData ...
    );


    resultsNext.totalLoad(currentSlot) = microHomeGrid.pTotalDemand;
    resultsNext.hvacLoad(currentSlot,1) = microHomeGrid.hvac.pCurrentAC;
    resultsNext.hvacLoad(currentSlot,2) = microHomeGrid.hvac.tempInd;
    resultsNext.data(currentSlot) = homeData;
    for i = 1:length(microHomeGrid.loadArray)
        resultsNext.loadDevicesLoad(currentSlot, i) = microHomeGrid.loadArray(i).pCurrent;
    end
    microHomeGrid.updateState(homeData, timeLine);

    timeLine.currentTimeslot = timeLine.currentTimeslot + 1;
end



% 加载数据
dataBefore = results.loadDevicesLoad;  % 调度前
dataAfter = resultsNext.loadDevicesLoad;  % 调度后

% 设置时间轴
timePerDay = 144;  % 每天144个时隙
days = size(dataBefore, 1) / timePerDay;
timeSlots = (1:timePerDay) * 10;  % 每时隙10分钟

% 加载数据
dataBefore = results.loadDevicesLoad;  % 调度前
dataAfter = resultsNext.loadDevicesLoad;  % 调度后

% 设置时间轴
timePerDay = 144;  % 每天144个时隙
days = 14;  % 生成14天的图
timeSlots = (1:timePerDay) * 10;  % 每时隙10分钟

% 加载数据
dataBefore = results.loadDevicesLoad;  % 调度前
dataAfter = resultsNext.loadDevicesLoad;  % 调度后

% 设置时间轴
timePerDay = 144;  % 每天144个时隙
days = 14;  % 生成14天的图
timeSlots = (1:timePerDay) * 10;  % 每时隙10分钟

% 电器名称
deviceNames = {'洗衣机', '洗碗机', '热水器', '烤箱', '干衣机'};

% 创建颜色
colors = lines(5);  % 自动生成5种颜色
for day = 1:days
    % 创建新图
    figure;
    
    % 提取当天数据
    idx = (day-1)*timePerDay + (1:timePerDay);
    dayDataBefore = dataBefore(idx, :);
    dayDataAfter = dataAfter(idx, :);
    
    % 绘制调度前数据（堆叠柱状图）
    subplot(1, 2, 1);  % 左侧子图
    hold on;
    
    % 使用堆叠柱状图将不同设备的功率叠加在一起
    bar(timeSlots, dayDataBefore(:, 1:5), 'stacked');  % 只选择前五个电器（1到5），堆叠显示
    % 绘制不可调度设备的功率，使用黑色条
    bar(timeSlots, dayDataBefore(:, 6), 'FaceColor', 'k', 'DisplayName', '不可调度设备');
    
    ylabel('功率 (kW)');
    title(['第 ', num2str(day), ' 天调度前']);
    xlabel('时间 (分钟)');
    legend(deviceNames(1:5), 'Location', 'best');
    hold off;
    
    % 绘制调度后数据（堆叠柱状图）
    subplot(1, 2, 2);  % 右侧子图
    hold on;
    
    % 使用堆叠柱状图将不同设备的功率叠加在一起
    bar(timeSlots, dayDataAfter(:, 1:5), 'stacked');  % 只选择前五个电器（1到5），堆叠显示
    % 绘制不可调度设备的功率，使用黑色条
    bar(timeSlots, dayDataAfter(:, 6), 'FaceColor', 'k', 'DisplayName', '不可调度设备');
    
    ylabel('功率 (kW)');
    title(['第 ', num2str(day), ' 天调度后']);
    xlabel('时间 (分钟)');
    legend(deviceNames(1:5), 'Location', 'best');
    hold off;
    
    % 调整图形布局
    sgtitle(['第 ', num2str(day), ' 天调度对比']);
end

% 
% for day = 1:days
%     % 创建新图
%     figure;
% 
%     % 提取当天数据
%     idx = (day-1)*timePerDay + (1:timePerDay);
%     dayDataBefore = dataBefore(idx, :);
%     dayDataAfter = dataAfter(idx, :);
% 
%     % 绘制调度前数据
%     subplot(1, 2, 1);  % 左侧子图
%     yyaxis left;  % 左侧Y轴表示功率
%     hold on;
%     for device = 1:5
%         plot(timeSlots, dayDataBefore(:, device), '-', 'Color', colors(device, :), 'DisplayName', deviceNames{device});
%     end
%     plot(timeSlots, dayDataBefore(:, 6), '--k', 'DisplayName', '不可调度设备');  % 不可调度设备
%     ylabel('功率 (kW)');
%     legend('show');
%     yyaxis right;  % 右侧Y轴表示电价
%     plot(timeSlots, elecPrice(1:144)', '-r', 'DisplayName', '电价');
%     ylabel('电价 (¢/kWh)');
%     title(['第 ', num2str(day), ' 天调度前']);
%     xlabel('时间 (分钟)');
%     hold off;
% 
%     % 绘制调度后数据
%     subplot(1, 2, 2);  % 右侧子图
%     yyaxis left;  % 左侧Y轴表示功率
%     hold on;
%     for device = 1:5
%         plot(timeSlots, dayDataAfter(:, device), '-', 'Color', colors(device, :), 'DisplayName', deviceNames{device});
%     end
%     plot(timeSlots, dayDataAfter(:, 6), '--k', 'DisplayName', '不可调度设备');  % 不可调度设备
%     ylabel('功率 (kW)');
%     legend('show');
%     yyaxis right;  % 右侧Y轴表示电价
%     plot(timeSlots, elecPrice(1:144)', '-r', 'DisplayName', '电价');
%     ylabel('电价 (¢/kWh)');
%     title(['第 ', num2str(day), ' 天调度后']);
%     xlabel('时间 (分钟)');
%     hold off;
% 
%     % 调整图形布局
%     sgtitle(['第 ', num2str(day), ' 天调度对比']);
% end
% 
