
%================================================================
% 功能： MicroHomeGrid 类用于存放家庭微电网实时参数
% 参数： hvac 、 ev 、 loadArray 、 pTotalDemand
% 备注： 无
%================================================================
classdef MicroHomeGrid < handle & matlab.mixin.Copyable
    properties
        % 子系统实例
        hvac      % HVAC 对象
        ev              % 电动车对象
        loadArray       % 负荷对象集合（结构体数组）

        % 参数
        pTotalDemand  % 总负载需求
        comfortWeight % 舒适度
    end

    methods
        %================================================================
        % 功能： MicroHomeGrid 类 构造函数
        % 参数： HomeParams
        % 返回值： 创建的实例
        % 备注： 无
        %================================================================
        function obj = MicroHomeGrid(HomeParams)
            obj.hvac = HvacSystem(HomeParams.hvacParams);
            % obj.ev = EV(HomeParams.evParams);
            obj.loadArray = arrayfun(@(x) Load(x), HomeParams.loadsParams);
            obj.comfortWeight = HomeParams.comfortWeight;
            obj.pTotalDemand = 0; % 初始总负载
        end

        %================================================================
        % 功能： 更新 MicroHomeGrid 类
        % 参数： homeData 、 timeLine
        % 返回值： 更新的实例
        % 备注： 无
        %================================================================
        function obj = updateState(obj, homeData, timeLine)
            % 更新负载状态
            for i = 1:length(obj.loadArray)
                if i <= length(homeData.loadsData) && ~isempty(fieldnames(homeData.loadsData(i)))
                    obj.loadArray(i).updateState(homeData.loadsData(i));
                end
            end
            
            % 更新HVAC状态
            if isfield(homeData, 'hvacData') && ~isempty(fieldnames(homeData.hvacData))
                obj.hvac.updateState(homeData.hvacData, timeLine);
            end
        
            % 更新EV状态
            % if isfield(homeData, 'evData')
            %     obj.ev.updateState(homeData.evData, timeLine);
            % end
        
            % 计算总需求
            obj.pTotalDemand = 0;
        end
    end
end
