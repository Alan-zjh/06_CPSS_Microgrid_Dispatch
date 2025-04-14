
%================================================================
% 功能：  测试优化调度 Load
% 参数：  无
% 返回值： 无
% 主要思路： 加载 TD3 、 MicroCommGrid 、 Sumulation 、 MicroGridController
% 这几类参数并初始化，在 MicroGridController 中 trainHvac 训练 HVAC 的TD3 模型
% 备注：   无
% 调用方法： 直接调用
% 日期：   2025/1/15 13:55
%================================================================
function testLoad()
    
    load(".\01_src\config\modelConfig.mat", "microCommGridParams", "timeLine", "elecPriceArray");
    load(".\01_src\config\loadOptimizationConfig.mat", "loadOptimizationParams");  
    load("02_data\01_input\Weather\WeatherDataSet.mat","weatherDataSet");
    load("02_data\01_input\Load\loadDemand.mat","loadDemand");
    microCommGrid = MicroCommGrid(microCommGridParams);
    simulation = Simulation(timeLine, weatherDataSet, elecPriceArray, loadDemand);
    controlParams = struct( ...
        'model', microCommGrid, ...
        'simulation', simulation, ...
        'homeParams', struct('homeLoadParams', loadOptimizationParams)...
        );
    controller = MicroGridController(controlParams);

    output = controller.runLoadOptimization(1);
    sive(".\02_data\02_output\hvac\output.mat", output);
end

