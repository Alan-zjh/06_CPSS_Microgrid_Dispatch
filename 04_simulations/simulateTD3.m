clc;
clear;
%% 定义环境
addpath('..\02_Model','..\04_Dispatch\');
load('..\01_Data\Load\loadDataSet.mat');
load('..\01_Data\PV\PVDataSet(1).mat');
load('..\01_Data\Weather\WeatherDataSet.mat');
load('..\01_Data\Params\Params.mat');

microHomeGrid = MicroHomeGrid(homeParams);
elecPrice = [2.8, 2.8, 2.8, 2.8, 2.8, 2.8, 2.8, ... 
            12.2, 12.2, 12.2, 12.2, 12.2, 12.2, 12.2, 12.2, 12.2,...
            28.6, 28.6, 28.6, 28.6, 28.6, ...
            12.2, 12.2, ...
            2.8 ...
];
elecPrice = repelem(elecPrice', 6);
%% 定义TD3算法
state_dim = 8;
action_dim = 6;

ckpt_dir = './checkpoints/';  % 模型保存目录
create_directory(ckpt_dir, {'Actor', 'Critic1', 'Critic2', 'Target_actor', ...
                             'Target_critic1', 'Target_critic2'});

actor_param = struct('alpha', 0.0003,...                     % 学习率
                     'state_dim', state_dim,...             % 状态空间维度
                     'action_dim', action_dim,...           % 动作空间维度
                     'fc1_dim', 400,...                     % 隐藏层1维度
                     'fc2_dim', 300);                       % 隐藏层2维度
critic_param = struct('beta', 0.0003,...                    % 学习率
                      'state_dim', state_dim,...            % 状态空间维度
                      'action_dim', action_dim,...          % 动作空间维度
                      'fc1_dim', 400,...                    % 隐藏层1维度
                      'fc2_dim', 300);                      % 隐藏层2维度
buffer_param = struct('max_size', 1000000,...               % 学习率
                      'state_dim', state_dim,...            % 状态空间维度
                      'action_dim', action_dim,...          % 动作空间维度
                      'batch_size', 512);                   % 隐藏层2维度
TD3_param = struct('gamma', 0.99,...                     % 学习率
                      'action_noise', 0.1,...               % 动作噪声
                      'policy_noise', 0.2,...               % 策略噪声
                      'policy_noise_clip', 0.5,...          % 策略噪声
                      'delay_time', 2,...                   % 评判次数
                      'ckpt_dir', ckpt_dir,...              % 参数保存目录
                      'actor_param', actor_param,...        % 策略网络参数
                      'critic_param', critic_param,...      % 评判网络参数
                      'buffer_param', buffer_param);        % 经验缓冲区参数
% 创建 TD3 智能体
agent = TD3(TD3_param); 

%% 迭代训练
max_episodes = 1000;
total_reward_history = zeros(max_episodes);
avg_reward_history = zeros(max_episodes);
iteration = 0;

for episode = 1:max_episodes
    total_reward = 0;
    done = false;
    episode_step = 0;
    timeLine = struct( ...
    'timeSlot', 600, ...
    'totalSlot', 2016, ...
    'currentSlot', 88 ...
    );
    results(episode) = struct( ...
        'totalLoad', zeros(timeLine.totalSlot, 1), ...
        'hvacLoad', zeros(timeLine.totalSlot, 2), ...
        'loadDevicesLoad', zeros(timeLine.totalSlot, length(microHomeGrid.loadDevices)) ...
    );
    
%% 环境循环
    while(timeLine.currentSlot <= timeLine.totalSlot)
        episode_step = episode_step + 1;
        currentSlot = timeLine.currentSlot;


        hvacData = struct( ...
            'pAC', randi([0, 3700]), ...  % 随机生成空调功率
            'pIns', weatherDataSet(currentSlot, 2), ...  % 辐照度
            'tempOut', weatherDataSet(currentSlot, 4) ... % 外界温度
        );
        
        loadsData = struct([]);
        for i = 1:(length(microHomeGrid.loadDevices) - 1)
            if currentSlot == 1
                prevLoad = 0;
            else
                prevLoad = loadDataSet{currentSlot-1, i+2};
            end
            currLoad = loadDataSet{currentSlot, i+2};
            loadCurve = loadDataSet{currentSlot:end, i+2}; % 第 i 个设备的功率曲线
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
        
        state = arrayfun(@(x) x.dispatchDelayTime, loadsData)';
        t = mod(currentSlot, 144);
        if t <= 133
            state = dlarray([state; microHomeGrid.hvac.tempInd; microHomeGrid.hvac.tempOut,elecPrice(i:i+10)]);
        end
        action = agent.choose_action(state, false);
        action_ = agent.scale_action(action, action_space_low, action_space_high);
        reward = ;


        loadsData(6) = struct( ...
            'isNeed', 1, ...
            'enable', 1, ...
            'pCurve', loadDataSet{currentSlot,8} ...
        );
    
        homeData = struct( ...
            'hvacData', hvacData, ...
            'loadsData', loadsData ...
        );


        results(episode).totalLoad(currentSlot) = microHomeGrid.totalLoad;
        results(episode).hvacLoad(currentSlot,1) = microHomeGrid.hvac.pAC;
        results(episode).hvacLoad(currentSlot,2) = microHomeGrid.hvac.tempInd;
        for i = 1:length(microHomeGrid.loadDevices)
            results(episode).loadDevicesLoad(currentSlot, i) = microHomeGrid.loadDevices(i).pCurrent;
        end
        microHomeGrid.updateState(homeData, timeLine);
    
        timeLine.currentSlot = timeLine.currentSlot + 1;
    end
end
