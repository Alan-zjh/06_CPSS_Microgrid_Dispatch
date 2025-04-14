function dispLoss(resultArray)
    reward = zeros(294,1);
    pmv = zeros(294,1);
    % 提取所有 tempInd 和 pCurrentAC 数据
    for i = 1:294
        reward(i) = sum(resultArray(i+5).reward(:));
        pmv(i) = sum(resultArray(i+1).PMV(:));
    end
    
    % 绘制 tempInd 曲线
    figure;
    plot(pmv, '-black', 'LineWidth', 1.5);
    hold on;
    title('Total PMV curve');
    xlabel('Index of examples');
    ylabel('Total PMV');
    legend('Total PMV');  % 添加图例
end

