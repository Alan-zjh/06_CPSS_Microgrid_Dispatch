function data = generateTimeSeriesData(n_samples, noise_level)
    % 生成带噪声的正弦波时间序列数据
    t = linspace(0, 10, n_samples);  % 时间点
    clean_signal = sin(2 * pi * 0.5 * t);  % 正弦波
    noise = noise_level * randn(size(t));  % 随机噪声
    data = clean_signal + noise;  % 带噪声的时间序列
end
