%%  ��ջ�������
warning off             % �رձ�����Ϣ
close all               % �رտ�����ͼ��
clear                   % ��ձ���
clc                     % ���������

%%  ��������
load("..\..\Data\PV\Data_Final.mat");
data = table2array(Data_Slot);
predict_duration = 10;   % �������ڴ�С
test_split = 0.02;   % ���Լ�����
[P_train, T_train, P_test, T_test] = prepareData_PV(data, predict_duration, test_split);
P_test = P_test(1:end-predict_duration,:);
T_train = T_train(:,2);
T_test = T_test(:,2);
%%  ���·��
addpath('goat\')

%%  ����ѵ�����Ͳ��Լ�
input=[P_train;P_test];
output=[T_train;T_test]; 
% �ָ�����ת��
P_train = P_train';
P_test = P_test';
% �ָ�����ת��
T_train = T_train';
T_test = T_test';

M = size(P_train, 2);
N = size(P_test, 2);
disp(size(P_train));  % �鿴ѵ���������ά��
disp(size(P_test));   % �鿴���Լ������ά��
%%  ���ݹ�һ��
[p_train, ps_input] = mapminmax(P_train, 0, 1);
disp(ps_input)
p_test = mapminmax('apply', P_test, ps_input);

[t_train, ps_output] = mapminmax(T_train, 0, 1);
t_test = mapminmax('apply', T_test, ps_output);

%% ������������
inputnum=size(input,2);
outputnum=size(output,2);
disp(['�����ڵ�����',num2str(inputnum),',  �����ڵ�����',num2str(outputnum)])
disp(['������ڵ�����ΧΪ ',num2str(fix(sqrt(inputnum+outputnum))+1),' �� ',num2str(fix(sqrt(inputnum+outputnum))+10)])
disp(' ')
disp('���������ڵ��ȷ��...')
 
%����hiddennum=sqrt(m+n)+a��mΪ�����ڵ�����nΪ�����ڵ�����aȡֵ[1,10]֮�������
MSE=1e+5;                             %����ʼ��
transform_func={'tansig','purelin'};  %���������tan-sigmoid��purelin
train_func='trainlm';                 %ѵ���㷨
for hiddennum=fix(sqrt(inputnum+outputnum))+1:fix(sqrt(inputnum+outputnum))+10
    net=newff(p_train,t_train,hiddennum,transform_func,train_func); %����BP����
    % �����������
    net.trainParam.epochs=1000;       % ����ѵ������
    net.trainParam.lr=0.01;           % ����ѧϰ����
    net.trainParam.goal=0.000001;     % ����ѵ��Ŀ����С���
    % ��������ѵ��
    net=train(net,p_train,t_train);
    an0=sim(net,p_train);     %������
    mse0=mse(t_train,an0);   %����ľ������
    disp(['��������ڵ���Ϊ',num2str(hiddennum),'ʱ��ѵ�����������Ϊ��',num2str(mse0)])
    %���ϸ������������ڵ�
    if mse0<MSE
        MSE=mse0;
        hiddennum_best=hiddennum;
    end
end
disp(['ѡ��������ڵ���Ϊ',num2str(hiddennum_best)])
%%  ����ģ��
S1 = hiddennum_best;           %  ���ز�ڵ����                
net = newff(p_train, t_train, S1);

%%  ���ò���
net.trainParam.epochs = 1000;        % ���������� 
net.trainParam.goal   = 1e-6;        % ���������ֵ
net.trainParam.lr     = 0.01;        % ѧϰ��

%%  �����Ż�����
gen = 60;                       % �Ŵ�����
pop_num = 6;                    % ��Ⱥ��ģ
S = size(p_train, 1) * S1 + S1 * size(t_train, 1) + S1 + size(t_train, 1);
                                % �Ż���������
bounds = ones(S, 1) * [-1, 1];  % �Ż������߽�

%%  ��ʼ����Ⱥ
prec = [1e-6, 1];               % epslin Ϊ1e-6, ʵ������
normGeomSelect = 0.09;          % ѡ�����Ĳ���
arithXover = 2;                 % ���溯���Ĳ���
nonUnifMutation = [2 gen 3];    % ���캯���Ĳ���

initPpp = initializega(pop_num, bounds, 'gabpEval', [], prec);  

%%  �Ż��㷨
[Bestpop, endPop, bPop, trace] = ga(bounds, 'gabpEval', [], initPpp, [prec, 0], 'maxGenTerm', gen,...
                           'normGeomSelect', normGeomSelect, 'arithXover', arithXover, ...
                           'nonUnifMutation', nonUnifMutation);

%%  ��ȡ���Ų���
[val, W1, B1, W2, B2] = gadecod(Bestpop);

%%  ������ֵ
net.IW{1, 1} = W1;
net.LW{2, 1} = W2;
net.b{1}     = B1;
net.b{2}     = B2;

%%  ģ��ѵ��
net.trainParam.showWindow = 1;       % ��ѵ������
net = train(net, p_train, t_train);  % ѵ��ģ��

%%  �������
t_sim1 = sim(net, p_train);
t_sim2 = sim(net, p_test );

%%  ���ݷ���һ��
T_sim1 = mapminmax('reverse', t_sim1, ps_output);
T_sim2 = mapminmax('reverse', t_sim2, ps_output);

%%  ���������
error1 = sqrt(sum((T_sim1 - T_train).^2) ./ M);
error2 = sqrt(sum((T_sim2 - T_test ).^2) ./ N);

%%  ��ͼ
figure
plot(1: M, T_train, 'r-*', 1: M, T_sim1, 'b-o', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {'ѵ����Ԥ�����Ա�'; ['RMSE=' num2str(error1)]};
title(string)
xlim([1, M])
grid

figure
plot(1: N, T_test, 'r-*', 1: N, T_sim2, 'b-o', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {'���Լ�Ԥ�����Ա�'; ['RMSE=' num2str(error2)]};
title(string)
xlim([1, N])
grid

%%  ���ָ�����
%  R2
R1 = 1 - norm(T_train - T_sim1)^2 / norm(T_train - mean(T_train))^2;
R2 = 1 - norm(T_test  - T_sim2)^2 / norm(T_test  - mean(T_test ))^2;
r=corrcoef(T_sim1,T_train);
R3=r(1,2);
r=corrcoef(T_sim2,T_test);
R4=r(1,2);
disp(['ѵ�������ݵ�R1Ϊ��', num2str(R1)])
disp(['���Լ����ݵ�R2Ϊ��', num2str(R2)])
disp(['ѵ�������ݵ��������ϵ��R3�� ',num2str(R3)])
disp(['���Լ����ݵ��������ϵ��R4�� ',num2str(R4)])

%  MAE
mae1 = sum(abs(T_sim1 - T_train)) ./ M ;
mae2 = sum(abs(T_sim2 - T_test )) ./ N ;

disp(['ѵ�������ݵ�MAEΪ��', num2str(mae1)])
disp(['���Լ����ݵ�MAEΪ��', num2str(mae2)])

%  MBE
mbe1 = sum(T_sim1 - T_train) ./ M ;
mbe2 = sum(T_sim2 - T_test ) ./ N ;

disp(['ѵ�������ݵ�MBEΪ��', num2str(mbe1)])
disp(['���Լ����ݵ�MBEΪ��', num2str(mbe2)])

%  RMSE
disp(['ѵ�������ݵ�RMSEΪ��', num2str(error1)])
disp(['���Լ����ݵ�RMSEΪ��', num2str(error2)])

