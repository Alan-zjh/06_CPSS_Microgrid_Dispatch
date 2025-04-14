clc;
clear;

% 准备数据
load("../../Data/PV/Data_Final.mat");
data = table2array(Data_Slot);
predict_duration = 10;   % 滑动窗口大小
test_split = 0.02;   % 测试集比例
[X_train, Y_train, X_test, Y_test] = prepareData_PV(data, predict_duration, test_split);

% 训练模型
num_epochs = 50;
learning_rate = 0.001;
num_layers = 4;
d_model = 256;
num_heads = 4;
d_ff = 512;
% 训练模型并获取参数
params = trainModel(X_train, Y_train, num_epochs, learning_rate, num_layers, d_model, num_heads, d_ff);

% 模型预测
Y_pred = predict(X_test, params, num_layers, num_heads, d_ff);

% 评估结果
mse = mean((Y_pred - Y_test).^2);
fprintf('测试集的均方误差 (MSE): %.4f\n', mse);
