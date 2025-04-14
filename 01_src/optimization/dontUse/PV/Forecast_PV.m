
clc;
clear;
load('..\..\data\PV\Data_Final.mat');
addpath('goat\')

res = table2array(Data_Slot);

%%  划分训练集和测试集
input=res(:,4:8);
output=res(:,3); 
P_train = res(1: 1000, 4:8)';
T_train = res(1: 1000, 3)';
M = size(P_train, 2);

P_test = res(1001: 1050, 4:8)';
T_test = res(1001: 1050, 3)';
N = size(P_test, 2);

%%  数据归一化
[p_train, ps_input] = mapminmax(P_train, 0, 1);
p_test = mapminmax('apply', P_test, ps_input);

[t_train, ps_output] = mapminmax(T_train, 0, 1);
t_test = mapminmax('apply', T_test, ps_output);

%% 求解最佳隐含层
inputnum=size(input,2);
outputnum=size(output,2);
disp(['输入层节点数：',num2str(inputnum),',  输出层节点数：',num2str(outputnum)])
disp(['隐含层节点数范围为 ',num2str(fix(sqrt(inputnum+outputnum))+1),' 至 ',num2str(fix(sqrt(inputnum+outputnum))+10)])
disp(' ')
disp('最佳隐含层节点的确定...')
 
%根据hiddennum=sqrt(m+n)+a，m为输入层节点数，n为输出层节点数，a取值[1,10]之间的整数
MSE=1e+5;                             %误差初始化
transform_func={'tansig','purelin'};  %激活函数采用tan-sigmoid和purelin
train_func='trainlm';                 %训练算法
for hiddennum=fix(sqrt(inputnum+outputnum))+1:fix(sqrt(inputnum+outputnum))+10
    net=newff(p_train,t_train,hiddennum,transform_func,train_func); %构建BP网络
    % 设置网络参数
    net.trainParam.epochs=1000;       % 设置训练次数
    net.trainParam.lr=0.01;           % 设置学习速率
    net.trainParam.goal=0.000001;     % 设置训练目标最小误差
    % 进行网络训练
    net=train(net,p_train,t_train);
    an0=sim(net,p_train);     %仿真结果
    mse0=mse(t_train,an0);   %仿真的均方误差
    disp(['当隐含层节点数为',num2str(hiddennum),'时，训练集均方误差为：',num2str(mse0)])
    %不断更新最佳隐含层节点
    if mse0<MSE
        MSE=mse0;
        hiddennum_best=hiddennum;
    end
end
disp(['选择隐含层节点数为',num2str(hiddennum_best)])
%%  建立模型
S1 = hiddennum_best;           %  隐藏层节点个数                
net = newff(p_train, t_train, S1);

%%  设置参数
net.trainParam.epochs = 1000;        % 最大迭代次数 
net.trainParam.goal   = 1e-6;        % 设置误差阈值
net.trainParam.lr     = 0.01;        % 学习率

%%  设置优化参数
gen = 60;                       % 遗传代数
pop_num = 6;                    % 种群规模
S = size(p_train, 1) * S1 + S1 * size(t_train, 1) + S1 + size(t_train, 1);
                                % 优化参数个数
bounds = ones(S, 1) * [-1, 1];  % 优化变量边界

%%  初始化种群
prec = [1e-6, 1];               % epslin 为1e-6, 实数编码
normGeomSelect = 0.09;          % 选择函数的参数
arithXover = 2;                 % 交叉函数的参数
nonUnifMutation = [2 gen 3];    % 变异函数的参数

initPpp = initializega(pop_num, bounds, 'gabpEval', [], prec);  

%%  优化算法
[Bestpop, endPop, bPop, trace] = ga(bounds, 'gabpEval', [], initPpp, [prec, 0], 'maxGenTerm', gen,...
                           'normGeomSelect', normGeomSelect, 'arithXover', arithXover, ...
                           'nonUnifMutation', nonUnifMutation);

%%  获取最优参数
[val, W1, B1, W2, B2] = gadecod(Bestpop);

%%  参数赋值
net.IW{1, 1} = W1;
net.LW{2, 1} = W2;
net.b{1}     = B1;
net.b{2}     = B2;

%%  模型训练
net.trainParam.showWindow = 1;       % 打开训练窗口
net = train(net, p_train, t_train);  % 训练模型

%%  仿真测试
t_sim1 = sim(net, p_train);
t_sim2 = sim(net, p_test );

%%  数据反归一化
T_sim1 = mapminmax('reverse', t_sim1, ps_output);
T_sim2 = mapminmax('reverse', t_sim2, ps_output);

%%  均方根误差
error1 = sqrt(sum((T_sim1 - T_train).^2) ./ M);
error2 = sqrt(sum((T_sim2 - T_test ).^2) ./ N);

%%  绘图
figure
plot(1: M, T_train, 'r-*', 1: M, T_sim1, 'b-o', 'LineWidth', 1)
legend('真实值', '预测值')
xlabel('预测样本')
ylabel('预测结果')
string = {'训练集预测结果对比'; ['RMSE=' num2str(error1)]};
title(string)
xlim([1, M])
grid

figure
plot(1: N, T_test, 'r-*', 1: N, T_sim2, 'b-o', 'LineWidth', 1)
legend('真实值', '预测值')
xlabel('预测样本')
ylabel('预测结果')
string = {'测试集预测结果对比'; ['RMSE=' num2str(error2)]};
title(string)
xlim([1, N])
grid

%%  相关指标计算
%  R2
R1 = 1 - norm(T_train - T_sim1)^2 / norm(T_train - mean(T_train))^2;
R2 = 1 - norm(T_test  - T_sim2)^2 / norm(T_test  - mean(T_test ))^2;
r=corrcoef(T_sim1,T_train);
R3=r(1,2);
r=corrcoef(T_sim2,T_test);
R4=r(1,2);
disp(['训练集数据的R1为：', num2str(R1)])
disp(['测试集数据的R2为：', num2str(R2)])
disp(['训练集数据的线性相关系数R3： ',num2str(R3)])
disp(['测试集数据的线性相关系数R4： ',num2str(R4)])

%  MAE
mae1 = sum(abs(T_sim1 - T_train)) ./ M ;
mae2 = sum(abs(T_sim2 - T_test )) ./ N ;

disp(['训练集数据的MAE为：', num2str(mae1)])
disp(['测试集数据的MAE为：', num2str(mae2)])

%  MBE
mbe1 = sum(T_sim1 - T_train) ./ M ;
mbe2 = sum(T_sim2 - T_test ) ./ N ;

disp(['训练集数据的MBE为：', num2str(mbe1)])
disp(['测试集数据的MBE为：', num2str(mbe2)])

%  RMSE
disp(['训练集数据的RMSE为：', num2str(error1)])
disp(['测试集数据的RMSE为：', num2str(error2)])

