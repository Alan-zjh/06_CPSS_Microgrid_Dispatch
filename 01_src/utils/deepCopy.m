function newObj = deepCopy(obj)
    % 创建一个新的对象
    newObj = obj.copy();  % 创建与原对象相同类型的新对象
    
    % 获取所有属性名
    propNames = properties(obj);
    
    % 遍历每个属性进行深复制
    for i = 1:numel(propNames)
        propValue = obj.(propNames{i});
        
        if isa(propValue, 'handle')  % 如果属性是一个 handle 对象
            if isscalar(propValue)  % 如果是单个对象
                newObj.(propNames{i}) = copy(propValue);  % 深复制单个 handle 对象
            else  % 如果是 handle 类型的矩阵（数组）
                newObj.(propNames{i}) = arrayfun(@(x) deepCopy(x), propValue);
            end
        else  % 如果是非 handle 类型的属性，直接赋值
            newObj.(propNames{i}) = propValue;
        end
    end
end
