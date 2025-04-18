
%================================================================
% 功能：  测试优化调度 HVAC
% 参数：  无
% 返回值： 无
% 主要思路： 加载 TD3 、 MicroCommGrid 、 Sumulation 、 MicroGridController
% 这几类参数并初始化，在 MicroGridController 中 trainHvac 训练 HVAC 的TD3 模型
% 备注：   无
% 调用方法： 直接调用
% 日期：   2025/1/15 13:55
%================================================================

function testHvac()

    load(".\01_src\config\modelConfig.mat", "microCommGridParams", "timeLine", "elecPriceArray");
    load(".\01_src\config\td3Config.mat", "td3Params");  
    load("02_data\01_input\Weather\weatherDataSet_26.5kW.mat","weatherDataSet");
    load("02_data\01_input\Load\loadDataSet.mat","loadDataSet");
    microCommGrid = MicroCommGrid(microCommGridParams);
    simulation = Simulation(timeLine, weatherDataSet, elecPriceArray, loadDataSet);
    controlParams = struct( ...
        'model', microCommGrid, ...
        'simulation', simulation, ...
        'homeParams', struct('homeTd3Params', td3Params)...
        );
    controller = MicroGridController(controlParams);
    output = controller.trainHvac(600,1:8);
    save(".\02_data\02_output\hvac\output.mat", output);
end

