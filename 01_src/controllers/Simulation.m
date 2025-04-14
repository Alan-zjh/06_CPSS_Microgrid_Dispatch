classdef Simulation < handle & matlab.mixin.Copyable
    %DATASET 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        % 时间轴
        timeLine
        
        % 数据集
        weather
        loadDataset
        elecPriceArray
    end
    
    methods
        function obj = Simulation(timeLine, weather, elecPriceArray, loadData)
            obj.timeLine.timeslotDuration = timeLine.timeslotDuration;
            obj.timeLine.totalTimeslot = timeLine.totalTimeslot;
            obj.timeLine.currentTimeslot = timeLine.currentTimeslot;
            obj.weather = weather;
            obj.elecPriceArray = elecPriceArray;
            obj.loadDataset = loadData;
        end
        
        function outputData = getWeather(obj,currentTimeslot)
            outputData = obj.weather(currentTimeslot,:);
        end

        function elecPrice = getElecPrice(obj,currentTimeslot)
            elecPrice = obj.elecPriceArray(currentTimeslot,:);
        end

        function loadDemand = getLoadDemand(obj, homeNo, currentTimeslot)
            loadDemand = obj.loadDataset(homeNo, currentTimeslot, :);
        end
    end
end

