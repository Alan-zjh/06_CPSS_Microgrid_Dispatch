
%================================================================
% 功能：  测试 MicroCommGrid 类各个功能
% 参数：  无
% 返回值： 无
% 主要思路：
% 备注：   无
% 调用方法： 直接测试
% 日期：   2025/1/15 13:55
%================================================================

function testMicroCommGrid()
    % 加载8个家庭的配置参数
    load(".\01_src\config\modelConfig.mat", "microCommGridParams", "timeLine", "elecPriceArray"); 
    load("02_data\01_input\Weather\WeatherDataSet.mat","weatherDataSet");
    
    % 初始化微电网系统（包含8个家庭）
    microCommGrid = MicroCommGrid(microCommGridParams);
    simulation = Simulation(timeLine, weatherDataSet, elecPriceArray, 1);
    
    % 预存储矩阵（8个家庭x2016时间点）
    numHomes = 8;
    tempInd = zeros(numHomes, 2016);  % 温度指标矩阵
    p = zeros(numHomes, 2016);        % 功率矩阵
    
    for i = 1:2016
        % 获取环境数据
        weatherData = simulation.getWeather(i);
        
        % 构建8家庭数据结构
        microCommGridData = struct(...
            'homeData', repmat(struct(), 1, numHomes),...
            'bessData', struct(),...
            'pvData', struct(),...
            'timeLine', simulation.timeLine);
        
        % 为每个家庭生成独立数据
        for homeID = 1:numHomes
            % 家庭热负荷参数（示例配置）
            microCommGridData.homeData(homeID).hvacData = struct(...
                'pAC', 50, ...         % 差异化空调功率
                'pIns', weatherData(2), ... % 辐照度衰减
                'tempOut', weatherData(4)... % 带噪声的温度
            );
            
            % 电器负载（示例：第6类负载）
            microCommGridData.homeData(homeID).loadsData(6) = struct(...
                'isNeed', mod(i,144)<72, ...      % 按时间段需求
                'enable', homeID<5, ...           % 前4个家庭启用
                'pCurve', 100 + 20*homeID ...     % 差异化功率曲线
            );
        end
        
        % 更新系统状态
        microCommGrid.updateState(microCommGridData);
        
        % 记录所有家庭状态
        for homeID = 1:numHomes
            tempInd(homeID,i) = microCommGrid.microHomeGrid(homeID).hvac.tempInd;
            p(homeID,i) = microCommGrid.microHomeGrid(homeID).hvac.pCurrentAC;
        end
    end
    
    % 可视化结果（完整标注版）
    figure('Position', [100 100 800 600])
    
    % 温度对比子图
    subplot(2,1,1)
    hold on
    h1 = plot(tempInd(:,1:144)', 'LineWidth',1.5);  % 所有家庭温度曲线
    h2 = plot(weatherDataSet(1:144,4), 'k--', 'LineWidth',2); % 外界温度
    
    % 标注设置
    xlabel('时间 (15分钟间隔)','FontSize',10)
    ylabel('温度 (°C)','FontSize',10)
    title('8家庭室内温度 vs 外界温度', 'FontSize',12)
    legend([h1(1), h2], {'各家庭温度','外界温度'}, 'Location','northwest')
    grid on
    set(gca,'XTick',0:12:144) % 每3小时一个刻度
    xlim([1 144])
    
    % 功率分布子图
    subplot(2,1,2)
    plot(p(:,1:144)', 'LineWidth',1.5);
    
    % 动态生成图例标签
    homeLabels = arrayfun(@(x)sprintf('家庭%d',x),1:8,'UniformOutput',false);
    
    % 标注设置
    xlabel('时间 (15分钟间隔)','FontSize',10)
    ylabel('空调功率 (kW)','FontSize',10)
    title('各家庭空调功率分布', 'FontSize',12) 
    legend(homeLabels, 'Location','eastoutside','FontSize',8)
    grid on
    colormap(jet(8)) % 使用不同颜色区分家庭
    set(gca,'XTick',0:12:144)
    xlim([1 144])
    
    % 调整布局
    set(gcf,'Color','w') % 白色背景

    
    microCommGrid.reset();
end