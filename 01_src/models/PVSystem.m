classdef PVSystem < handle & matlab.mixin.Copyable
    % PVSystem 光伏系统类
    % 用于管理光伏设备的出力功率，支持额定功率限制和动态更新。

    properties
        % 光伏设备参数
        pRated    % 光伏额定功率 (W)

        % 输出功率
        pPv   % 光伏实际输出功率 (W)
    end

    methods
        function obj = PVSystem(PvParams)

            if ~isnumeric(PvParams.pRated) || PvParams.pRated <= 0
                error('P_rated_W 必须是正数！');
            end
            
            obj.pRated = PvParams.pRated; % 初始化额定功率
            obj.pPv = 0;       % 初始输出功率设为 0
        end

        % 更新光伏出力功率
        function obj = updateState(obj, pPv)
            if ~isnumeric(pPv) || pPv < 0
                error('P_pv 必须是非负数！');
            end

            obj.pPv = min(pPv, obj.pRated);

        end
    end
end
