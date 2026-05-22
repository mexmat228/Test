
%% Основной скрипт
clear; clc; close all;

% Параметры
Fs = 1000;          % частота дискретизации (Гц)
T = 10;             % длительность сигнала (с)
t = 0:1/Fs:T-1/Fs;  % временная ось
f = 0.5;            % частота синуса (Гц)

% 1. Генерация синуса
x = sin(2*pi*f*t);

% 2. Децимация в 3 раза
x_decimated = decimate_func(x, 3, Fs);

% 3. Интерполяция в 3 раза
x_resampled = interpolate_func(x_decimated, 3, Fs/3);

% Обрезаем сигналы до одинаковой длины (по минимальной)
min_len = min(length(x), length(x_resampled));
x_trimmed = x(1:min_len);
x_resampled_trimmed = x_resampled(1:min_len);

% Сравнение исходного и восстановленного сигнала
figure;
plot(t(1:min(500, min_len)), x_trimmed(1:min(500, min_len)), 'b', 'LineWidth', 1.5); hold on;
plot(t(1:min(500, min_len)), x_resampled_trimmed(1:min(500, min_len)), 'r--', 'LineWidth', 1.5);
xlabel('Время (с)'); ylabel('Амплитуда');
legend('Исходный сигнал', 'После децимации+интерполяции');
title('Сравнение сигналов (f = 0.5 Гц)');
grid on;

% 4. Измерение ошибки в зависимости от частоты f
frequencies = 0.1:0.1:100;  % Гц
errors = zeros(size(frequencies));

for i = 1:length(frequencies)
    f_test = frequencies(i);
    x_test = sin(2*pi*f_test*t);
    
    x_dec = decimate_func(x_test, 3, Fs);
    x_int = interpolate_func(x_dec, 3, Fs/3);
    
    % Обрезаем до одинаковой длины
    min_len = min(length(x_test), length(x_int));
    x_test_trimmed = x_test(1:min_len);
    x_int_trimmed = x_int(1:min_len);
    
    % Ошибка: среднеквадратичное отклонение
    errors(i) = sqrt(mean((x_test_trimmed - x_int_trimmed).^2));
end

% График ошибки
figure;
semilogy(frequencies, errors, 'LineWidth', 2);
xlabel('Частота сигнала f (Гц)');
ylabel('Среднеквадратичная ошибка');
title('Зависимость ошибки от частоты входного сигнала');
grid on;
xlim([0, 100]);

%% Функция децимации (понижение частоты в 3 раза)
function y = decimate_func(x, factor, Fs_orig)
    % factor = 3 - коэффициент децимации
    % Сначала фильтр нижних частот для подавления наложений
    % Частота среза = (Fs_orig/factor)/2 = Fs_orig/(2*factor)
    cutoff = Fs_orig / (2 * factor);
    nyquist = Fs_orig / 2;
    normalized_cutoff = cutoff / nyquist;
    
    % Фильтр 8-го порядка (можно менять)
    [b, a] = butter(8, normalized_cutoff, 'low');
    x_filtered = filtfilt(b, a, x);
    
    % Децимация: берём каждый factor-й отсчёт
    y = x_filtered(1:factor:end);
end

%% Функция интерполяции (повышение частоты в 3 раза)
function y = interpolate_func(x, factor, Fs_orig)
    % factor = 3 - коэффициент интерполяции
    % 1. Вставка нулей
    x_up = zeros(1, length(x) * factor);
    x_up(1:factor:end) = x;
    
    % 2. Фильтр нижних частот для сглаживания
    % Частота среза = Fs_orig/2 (после вставки нулей частота стала Fs_new = factor*Fs_orig)
    Fs_new = Fs_orig * factor;
    cutoff = Fs_orig / 2;
    nyquist = Fs_new / 2;
    normalized_cutoff = cutoff / nyquist;
    
    % Фильтр 8-го порядка с компенсацией усиления (factor)
    [b, a] = butter(8, normalized_cutoff, 'low');
    y = filtfilt(b, a, x_up) * factor;  % умножение на factor для коррекции энергии
end