clc;
clear;

% 准备数据
load("../../Data/PV/Data_Final.mat");
data = table2array(Data_Slot);
predict_duration = 10;   % 滑动窗口大小
test_split = 0.02;   % 测试集比例
[X_train, Y_train, X_test, Y_test] = prepareData_PV(data, predict_duration, test_split);

% 设置 Transformer 模型参数
d_model = 512;
num_heads = 8;
num_layers = 6;
d_ff = 2048;
learning_rate = 0.001;
num_epochs = 10;

% 创建 Transformer 模型
model = Transformer(d_model, num_heads, d_ff, num_layers, learning_rate);

% 执行训练
model.train(X_train, Y_train, num_epochs);
