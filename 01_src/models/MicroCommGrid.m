
%================================================================
% 功能： MicroCommGrid 类用于存放微电网实时参数
% 参数： microHomeGrid 、 bess 、 pvSystem 、 params
% 备注： 无
% 调用方法： 直接调用
%================================================================
classdef MicroCommGrid < handle & matlab.mixin.Copyable
     
    properties
        microHomeGrid
        bess
        pvSystem
        params
    end
    
    methods
        %================================================================
        % 功能： MicroCommGrid 类 构造函数
        % 参数： microCommGridParams
        % 返回值： 无
        % 主要思路： 调用下属更新函数
        % 备注： 无
        % 调用方法： 直接调用
        %================================================================
        function obj = MicroCommGrid(microCommGridParams)
            if nargin > 0
                obj.params = microCommGridParams;
                obj.microHomeGrid = arrayfun(@(x) MicroHomeGrid(x), microCommGridParams.homeParamsArray);
                obj.bess = BESS(microCommGridParams.bessParams);
                obj.pvSystem = PVSystem(microCommGridParams.pvParams);
            else
                obj.microHomeGrid = {};  % 空的家庭微电网数组
                obj.bess = {};       % 创建空的 BESS 对象
                obj.pvSystem = {};  % 创建空的 PVSystem 对象
                obj.params = {};    % 空的配置参数
            end
        end  

        %================================================================
        % 功能： 更新 MicroCommGrid 类
        % 参数： microCommGridData
        % 返回值： 无
        % 主要思路： 调用下属更新函数
        % 备注： 无
        % 调用方法： 直接调用
        %================================================================
        function updateState(obj, microCommGridData)
            % 更新家庭微电网状态
            for i = 1:length(microCommGridData.homeData)
                if ~isempty(microCommGridData.homeData(i))
                    obj.microHomeGrid(i).updateState(microCommGridData.homeData(i), microCommGridData.timeLine);
                end
            end
        
            % 更新储能系统状态
            if ~isempty(fieldnames(microCommGridData.bessData))
                obj.bess.updateState(microCommGridData.bessData, microCommGridData.timeLine);
            end
        
            % 更新光伏系统状态
            if ~isempty(fieldnames(microCommGridData.pvData))
                obj.pvSystem.updateState(microCommGridData.pvData);
            end
        end

        %================================================================
        % 功能： 初始化 MicroCommGrid
        % 参数： 无
        % 返回值： 无
        % 主要思路： 直接重新创建
        % 备注： 无
        % 调用方法： 直接调用
        %================================================================
        function reset(obj)
            obj.microHomeGrid = arrayfun(@(x) MicroHomeGrid(x), obj.params.homeParamsArray);
            obj.bess = BESS(obj.params.bessParams);
            obj.pvSystem = PVSystem(obj.params.pvParams);
        end
    end
end

