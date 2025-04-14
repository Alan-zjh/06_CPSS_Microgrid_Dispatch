clc;
clear;

% 添加必要的路径
% addpath('./checkpoints');
% addpath('./output_images');
pe = pyenv;

% 参数设置
max_episodes = 1000;  % 最大训练回合数
ckpt_dir = './02_data/02_output/pygym/checkpoints/TD3/';  % 模型保存目录
figure_file = './02_data/02_output/pygym/output_images/reward.png';  % 奖励曲线保存路径

% 创建环境
env = py.gym.make('LunarLanderContinuous-v2', render_mode="human");


stateDim = double(env.observation_space.shape(1));  % 8
actionDim = double(env.action_space.shape(1));      % 2

action_space_low = double(env.action_space.low.tolist())';
action_space_high = double(env.action_space.high.tolist())';

state_space_low = double(env.observation_space.low.tolist())';
state_space_high = double(env.observation_space.high.tolist())';
actorParams = struct('alpha', 0.0003,...                     % 学习率
                     'stateDim', stateDim,...             % 状态空间维度
                     'actionDim', actionDim,...           % 动作空间维度
                     'fc1Dim', 400,...                     % 隐藏层1维度
                     'fc2Dim', 300);                       % 隐藏层2维度
criticParams = struct('beta', 0.0003,...                    % 学习率
                      'stateDim', stateDim,...            % 状态空间维度
                      'actionDim', actionDim,...          % 动作空间维度
                      'fc1Dim', 400,...                    % 隐藏层1维度
                      'fc2Dim', 300);                      % 隐藏层2维度
bufferParams = struct('maxSize', 1000000,...               % 学习率
                      'stateDim', stateDim,...            % 状态空间维度
                      'actionDim', actionDim,...          % 动作空间维度
                      'batchSize', 512);                   % 隐藏层2维度
td3Params = struct(   'gamma', 0.98,...                     % 学习率
                      'actionNoise', 0.1,...               % 动作噪声
                      'policyNoise', 0.2,...               % 策略噪声
                      'policyNoiseClip', 0.4,...          % 策略噪声
                      'delayTime', 2,...                   % 评判次数
                      'ckptDir', ckpt_dir,...              % 参数保存目录
                      'stateDim', stateDim,...             % 状态空间维度
                      'actionDim', actionDim,...           % 动作空间维度
                      'actionSpaceLow', -3800,...
                      'actionSpaceHigh', 3800,...
                      'actorParams', actorParams,...        % 策略网络参数
                      'criticParams', criticParams,...      % 评判网络参数
                      'bufferParams', bufferParams);        % 经验缓冲区参数
% 创建 TD3 智能体
agent = TD3(td3Params); % 经验回放参数
agent.loadModels(1000);

% 创建目录以保存模型
create_directory(ckpt_dir, {'Actor', 'Critic1', 'Critic2', 'Target_actor', ...
                             'Target_critic1', 'Target_critic2'});

% 奖励记录
total_reward_history = zeros(max_episodes);
avg_reward_history = zeros(max_episodes);
iteration = 0;

% 训练循环
for episode = 1:max_episodes
    total_reward = 0;
    done = false;
    episode_step = 0;
    state = env.reset();  % 重置环境并获得初始状态
    state = double(py.array.array('d', state{1}))';
    state = dlarray(state, 'CB');
    state = (state - state_space_low) ./ (state_space_high - state_space_low); % 归一化
    while ~done
        episode_step = episode_step + 1;
        % 选择动作
        action = agent.chooseAction(state, false);
        action_ = scale_action(action, action_space_low, action_space_high);
        action_ = extractdata(action_)';
        action_ = py.numpy.array(action_);
        % 执行动作并获取返回值
        result = env.step(action_);
        next_state = double(py.array.array('d', result{1}))';  % 状态转换为 MATLAB 数组
        next_state = (next_state - state_space_low) ./ (state_space_high - state_space_low); % 归一化
        next_state = dlarray(next_state, 'CB');
        reward = double(result{2});  % 奖励
        done = logical(result{3});  % 任务完成标志
        
        % 记住经验并学习
        agent.memory.storeTransition(state, action, reward, next_state, done);
        if agent.memory.ready()
            iteration = iteration + 1;
        end
        % agent.learn();
        
        % 更新状态和总奖励
        total_reward = total_reward + reward;
        state = next_state;  % 转到下一个状态
        if (episode_step > 800)
            done = 1;
        end
    end

    % 奖励记录
    total_reward_history(episode) = total_reward;
    avg_reward = mean(total_reward_history(max(1, episode-99):episode));  % 计算最近100回合的平均奖励
    avg_reward_history(episode) = avg_reward;

    % 打印训练信息
    fprintf('Episode: %d | Total Reward: %.2f | Average Reward: %.2f\n', episode, total_reward, avg_reward);

    % 每200回合保存一次模型
    if mod(episode, 200) == 0
        agent.saveModels(episode);
    end
end

% 绘制学习曲线
episodes = 1:max_episodes;
% plot_learning_curve(episodes, avg_reward_history, 'AvgReward', 'reward', figure_file);

% 关闭环境
env.close();

function action_ = scale_action(action, low, high)
    action = min(max(action, -1), 1); % Clip action between -1 and 1
    weight = (high - low) / 2;
    bias = (high + low) / 2;
    action_ = action .* weight + bias;
    action_ = double(action_);
end

plot(total_reward_history);