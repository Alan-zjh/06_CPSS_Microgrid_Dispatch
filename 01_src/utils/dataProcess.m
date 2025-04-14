classdef dataProcess
    %DATAPROCESS 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        
    end
    
    methods
        function obj = dataProcess()
        end
        %================================================================
        % 功能： 动态加载并预处理家庭用电负载数据
        % 参数： timeslotDuration - 重采样间隔（分钟）
        %           - 取值范围：1-60的正整数
        %           - 示例：15 表示15分钟粒度
        % 返回值： 隐式返回，生成并存储 loadDataSet 到时序数据文件
        % 备注： 
        %   1. 输入文件要求：
        %       - 必须包含完整设备功率列：MHE/CWE/DWE/HPE/WOE/CDE
        %       - 时间列必须为有效Unix时间戳（秒级精度）
        %   2. 时间处理规范：
        %       - 自动转换时区至系统默认时区
        %       - 强制时间范围：2012-04-01 07:00 至 2012-06-01 07:00
        %================================================================
        function getLoadData(~, timeslotDuration)
            % 参数说明:
            %   timeslotDuration - 重采样的时间间隔（单位：分钟），需为正整数
            
            % 1. 文件读取
            csvPath = fullfile('.', '02_data', '01_input', 'Load', 'Electricity_P.csv');
            try
                rawData = readtable(csvPath);
            catch ME
                error('文件读取失败: %s\n文件路径: %s', ME.message, csvPath);
            end
            
            % 2. 时间处理（带时区支持和格式验证）
            try
                timeStamps = datetime(rawData{:,1}, 'ConvertFrom', 'posixtime');
            catch
                error('时间列格式验证失败，请确认为有效Unix时间戳');
            end
            
            % 3. 时间范围过滤（增加空数据集检查）
            dataTimetable = table2timetable(rawData(:,2:end), 'RowTimes', timeStamps);
            timeFilter = timerange('2012-04-01 07:00:00', '2012-06-01 07:00:00', 'closed');
            filteredData = dataTimetable(timeFilter, :);
            
            if isempty(filteredData)
                error('过滤后的数据集为空，请检查时间范围设置');
            end
            
            % 4. 重采样
            validateattributes(timeslotDuration, {'numeric'},...
                {'positive', 'scalar', 'integer', '>=', 1, '<=', 60},...
                '', 'timeslotDuration');  % 限制1-60分钟
            
            try
                resampledData = retime(filteredData,...
                    'regular', @(x) mean(x, 'omitnan'),...
                    'TimeStep', minutes(timeslotDuration));
            catch ME
                error('重采样失败: %s\n建议检查时间序列连续性', ME.message);
            end
            
            % 5. 列处理
            requiredOrder = {'MHE', 'CWE', 'DWE', 'HPE', 'WOE', 'CDE'};
            columnNames = {'WholeHouse', 'WashingMachine', 'Dishwasher',...
                           'HeatPump', 'Oven', 'Dryer'};
            
            missingCols = setdiff(requiredOrder, resampledData.Properties.VariableNames);
            if ~isempty(missingCols)
                error('缺失必要列: %s', strjoin(missingCols, ', '));
            end
            
            applianceData = resampledData{:, requiredOrder};
            
            % 使用矩阵运算代替逐元素计算
            otherPower = applianceData(:,1) - sum(applianceData(:,2:end), 2);
            otherPower = max(otherPower, 0);  % 处理负功耗
            
            % 内存预分配（类型一致性优化）
            finalData = [applianceData, otherPower];
            
            % 7. 时间表构建（带自动类型转换）
            loadDataSet = array2timetable(finalData,...
                'RowTimes', resampledData.Time,...
                'VariableNames', [columnNames, {'Other'}]);
            
            % 8. 高效数据存储（带版本控制和压缩）
            savePath = fullfile('.', '02_data', '01_input', 'Load');
            if ~exist(savePath, 'dir')
                mkdir(savePath);
            end

            save(fullfile(savePath, 'loadDataSet.mat'),...
                'loadDataSet',...
                '-v7.3',...      % 支持 >2GB 数据
                '-nocompression'... % 禁用压缩以加快保存速度
            );
            disp(string(datetime('now', 'Format', 'HH:mm:ss')) + " ：负载数据已优化存储");
        end


        function loadDemand = extractLoadDemand(~)
            % 加载数据文件
            load('.\02_data\01_input\Load\loadDataSet.mat', 'loadDataSet');
            loadData = loadDataSet{:,2:end};
            [numTimeSlots, numLoads] = size(loadData);
            % 预分配结构数组
            loadDemand = repmat(struct('isNeed',0, 'enable',0, 'pCurve',[]), numTimeSlots, numLoads);
            % 比较前后时段负载
            prevLoads = loadData(1:end-1, 1:end-1);
            currLoads = loadData(2:end, 1:end-1);
            
            % 查找所有触发点
            triggerMask = (prevLoads < 40) & (currLoads >= 40);
            [triggerTimes, loadIndices] = find(triggerMask);

            % 主处理循环
            for i = 1:length(triggerTimes)
                t = triggerTimes(i) + 1;
                loadIdx = loadIndices(i);
                
                % 提取负载曲线段（从触发时隙到结束）
                fullCurve = loadData(t:end, loadIdx);
                
                % 查找第一个满足终止条件的点
                cutoff = find(fullCurve <= 40, 1);
                
                % 更新对应时隙的负载需求记录
                if ~isempty(cutoff) && cutoff > 1
                    loadDemand(t, loadIdx).pCurve = fullCurve(1:cutoff);
                    loadDemand(t, loadIdx).isNeed = 1;
                end
            end
            
            for i = 1:numTimeSlots
                loadDemand(i, 6).pCurve = loadData(i,6);
                loadDemand(i, 6).enable = loadData(i,6) > 0;
                loadDemand(i, 6).isNeed = loadData(i,6) > 0;
            end
            % 保存结果（使用快速保存格式）
            save('.\02_data\01_input\Load\loadDemand.mat', 'loadDemand', '-v7.3');
        end

    end
end

