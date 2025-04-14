
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

    load(".\01_src\config\modelConfig.mat", "microCommGridParams", "timeLine", "elecPriceArray"); 
    load("02_data\01_input\Weather\WeatherDataSet.mat","weatherDataSet");
    microCommGrid = MicroCommGrid(microCommGridParams);
    simulation = Simulation(timeLine, weatherDataSet, elecPriceArray, 1);
    tempInd = zeros(1,2016);
    p = zeros(1,2016);
    for i = 1 : 2016
        weatherData = simulation.getWeather(i);
        microCommGridData = struct( ...
            'homeData', struct(), ...  % 家庭数据
            'bessData', struct(), ...  % 储能数据
            'pvData', struct(), ...  % 光伏数据
            'timeLine', struct() ...
        );
        microCommGridData.timeLine = simulation.timeLine;
        microCommGridData.homeData(1).hvacData = struct( ...
                'pAC', 1000, ...
                'pIns', weatherData(2), ...    % 当前时段的辐照度
                'tempOut', weatherData(4) ... % 当前时段的外界温度
        ...
        );
        microCommGridData.homeData(1).loadsData(6) = struct( ...
            'isNeed', 1, ...
            'enable', 1, ...
            'pCurve', 100 ...
        );
    
        microCommGrid.updateState(microCommGridData);
        tempInd(i) = microCommGrid.microHomeGrid(1).hvac.tempInd;
        p(i) = microCommGrid.microHomeGrid(1).hvac.pCurrentAC;
    end
    microCommGrid.reset();
end

