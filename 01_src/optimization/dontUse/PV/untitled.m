clc,clear all
%% 
% 读取excel数据，data存放数值数据，text存放文本数据

[data1,text1]  = xlsread('数据集.xlsx');

y1=data1(:,1);
y2=data1(:,2);
x=data1(:,3:end);
X=[ones(length(y1),1),x];
%%
%%
%（1）b=regress( Y,  X ) 确定回归系数的点估计值
%其中，Y为n*1的矩阵；X为（ones(n,1),x1,…,xm）的矩阵；
%（2）[b, bint,r,rint,stats]=regress(Y,X,alpha) 求回归系数的点估计和区间估计，并检验回归模型
%b 回归系数
%bint 回归系数的区间估计
%r 残差
%rint 残差置信区间
%stats 用于检验回归模型的统计量，有四个数值：相关系数R2、F值、与F对应的概率p，
%误差方差。相关系数R2越接近1，说明回归方程越显著；F > F1-α（k，n-k-1）时拒绝H0，F越大，说明回归方程越显著；
%与F对应的概率p 时拒绝H0，回归模型成立。p值在0.01-0.05之间，越小越好。




%%
%%现在要做的是多元线性回归，第一次以TIC为被解释变量，PUT/CALL/BOND RATING/ISSUER RATING/SCALE/MATURITY/PLC这七个为解释变量
%%

[b1,bint1,r1,rint1,stats1]=regress(y1,X);
%b1 是多元回归方程的系数
b1,bint1,stats1
%画残差图
rcoplot(r1,rint1)

%预测及作图
z=b1(1)+b1(2)*x(:,1)+b1(3)*x(:,2)+b1(4)*x(:,3)+b1(5)*x(:,4)+b1(6)*x(:,5)+b1(7)*x(:,6)+b1(8)*x(:,7);
plot(X,y1, 'k+',X,z, 'g')
%%
%第二次以SPREAD为被解释变量，解释变量还是上面那七个

[b2,bint2,r2,rint2,stats2]=regress(y2,X);
%b1 是多元回归方程的系数
b2,bint2,stats2
%画残差图
rcoplot(r2,rint2)

%预测及作图
z=b2(1)+b2(2)*x(:,1)+b2(3)*x(:,2)+b2(4)*x(:,3)+b2(5)*x(:,4)+b2(6)*x(:,5)+b2(7)*x(:,6)+b2(8)*x(:,7);
plot(X,y1, 'k+',X,z, 'o')



%%
%相关性分析
corr(x,y1,'type','Pearson')
corr(x,y2,'type','Pearson')
corr(x,'type','Pearson')
%%
