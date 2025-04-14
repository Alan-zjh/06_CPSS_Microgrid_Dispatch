
pCurrent = zeros(144, 7);

% 提取所有 tempInd 和 pCurrentAC 数据
for i = 1:144
    pCurrent(i,2:7) = table2array(loadDataSet(i+72,2:7));
    pCurrent(i,1) = abs(resultArray(299).microGridParams(i+678).pCurrentAC);

end
pCurrent_avg = zeros(24, 7);

% 计算每 6 个时隙的均值
for j = 1:7
    for i = 1:24
        pCurrent_avg(i, j) = mean(pCurrent((i-1)*6+1 : i*6, j));
    end
end
% 绘制堆叠柱状图，并翻转堆叠顺序
figure;
b = bar(flip(pCurrent_avg, 2), 'stacked'); 

% 生成自定义的渐变但分明的颜色（蓝色-青色-绿色系）
cmap = [ 
    0.1  0.3  0.8;  % 深蓝
    0.2  0.5  0.9;  % 蓝色
    0.3  0.7  0.9;  % 浅蓝
    0.2  0.8  0.7;  % 蓝绿色
    0.1  0.6  0.5;  % 青色
    0.2  0.7  0.3;  % 绿色
    0.1  0.5  0.2   % 深绿色
];

% 应用颜色到堆叠柱状图
numCategories = size(pCurrent_avg, 2);  
for k = 1:numCategories
    b(k).FaceColor = cmap(k, :);
end

% 轴标签和标题
xlabel('Time Slot (1-24)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Power Consumption (W)', 'FontSize', 14, 'FontWeight', 'bold');
title('Stacked Bar Chart of Household Appliances', 'FontSize', 16, 'FontWeight', 'bold');

% 图例
legend('Other', 'Dryer', 'Oven', 'HeatPump', 'Dishwasher', 'WashingMachine', 'HVAC', ...
       'Location', 'northwest', 'FontSize', 12);

% 美化图表
grid on;
xlim([1 24]);
set(gca, 'FontSize', 12, 'LineWidth', 1.5);
box on; 

% 统一颜色映射，确保渐变色生效
colormap(cmap);