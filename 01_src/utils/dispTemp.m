function dispTemp(resultArray)
    tempInd_all = zeros(144, 1);
    tempOut = zeros(144,1);
    pCurrentAC_all = zeros(144, 1);
    pmv = zeros(144,1);
    
    % 提取所有 tempInd 和 pCurrentAC 数据
    for i = 1:144
        tempInd_all(i) = resultArray.microGridParams(i+720).tempInd;
        tempOut(i) = resultArray.microGridParams(i+720).tempOut;
        pCurrentAC_all(i) = resultArray.microGridParams(i+720).pCurrentAC;
        pmv(i) = resultArray.PMV(i+576);
    end
    
    % 绘制 tempInd 曲线
    figure;
    subplot(3,1,1);
    plot(tempInd_all, '-b', 'LineWidth', 1.5);
    hold on;
    plot(tempOut, '-g', 'LineWidth', 1.5);
    grid on;
    title('Temperature Index');
    xlabel('Index of examples');
    ylabel('Temperature Index');
    legend('tempInd', 'tempOut');  % 添加图例
    
    % 绘制 pCurrentAC 曲线
    subplot(3,1,2);
    plot(pCurrentAC_all, '-r', 'LineWidth', 1.5);
    grid on;
    title('Current Power of AC (pCurrentAC)');
    xlabel('Index of examples');
    ylabel('Power (W)');
    legend('pCurrentAC');  % 添加图例
    
    % 绘制 PMV 曲线
    subplot(3,1,3);
    plot(pmv, 'Color', 'k', 'LineWidth', 1.5); % '-black' 不正确，使用 'Color', 'k'
    grid on;
    title('PMV');
    xlabel('Index of examples');
    ylabel('PMV');
    legend('PMV');  % 添加图例
end

