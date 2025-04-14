function create_directory(basePath, subPathList)  
    % 检查输入参数是否为字符串和列表（在 MATLAB 中为 cell 数组或字符数组）  
    if ~ischar(basePath) || ~iscell(subPathList) && ~ischar(subPathList) && ~isnumeric(subPathList) && ~any(arrayfun(@(x) isequal(class(x), 'char'), subPathList))  
        error('Invalid input arguments. basePath should be a string, and subPathList should be a cell array or string array of paths.');  
    end  
      
    % 如果 subPathList 是字符数组，则转换为 cell 数组以便迭代  
    if ischar(subPathList)  
        subPathList = strsplit(subPathList, '\n'); % 假设路径是用换行符分隔的  
    elseif isnumeric(subPathList) && all(arrayfun(@isstrprop, subPathList, 'digit')) % 如果它是数字数组（不太可能，但检查一下）  
        error('Numeric array is not a valid input for subPathList. Convert to string or cell array of strings.');  
    elseif ~iscell(subPathList) && ~ischar(subPathList{1}) % 如果它既不是字符数组也不是 cell 数组  
        error('subPathList should be a cell array or string array where each element is a path string.');  
    end  
      
    % 遍历子路径列表  
    for i = 1:length(subPathList)  
        fullPath = fullfile(basePath, subPathList{i}); % 构建完整路径  
          
        % 检查路径是否存在  
        if ~exist(fullPath, 'dir')  
            mkdir(fullPath); % 创建目录  
            fprintf('Path: %s created successfully!\n', fullPath);  
        else  
            fprintf('Path: %s already exists!\n', fullPath);  
        end  
    end  
end