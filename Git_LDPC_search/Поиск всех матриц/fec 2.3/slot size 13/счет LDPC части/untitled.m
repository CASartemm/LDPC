% Шаг 1: Загрузка матрицы из файла Pg.mat Убран переворот входного вектра
% Шаг 1: Загрузка матрицы из файла Pg.mat
load('Pg.mat');  % Предполагаем, что матрица называется 'Pg'
if size(Pg, 1) ~= 3328 || size(Pg, 2) ~= 1664
    error('Матрица Pg должна быть размером 640x128');
end
if any(Pg(:) ~= 0 & Pg(:) ~= 1)
    error('Матрица Pg должна содержать только 0 и 1');
end

% Шаг 2: Сохранение матрицы в файл matrix_full.txt
fileID = fopen('matrix_full.txt', 'w');
for i = 1:3328
    fprintf(fileID, '%s\n', num2str(Pg(i, :), '%d'));
end
fclose(fileID);

% Шаг 3: Загрузка 640-битного входного вектора из файла 640bits.txt
fileID = fopen('640bits.txt', 'r');
bit_vector_str = fscanf(fileID, '%s'); % Читаем как строку
fclose(fileID);
bit_vector = double(bit_vector_str - '0'); % Преобразуем в числовой вектор
disp(['Считано бит: ', num2str(length(bit_vector))]); % Отладка
if length(bit_vector) ~= 3328
    error('Входной вектор должен содержать 640 бит, считано: %d', length(bit_vector));
end
if any(bit_vector ~= 0 & bit_vector ~= 1)
    error('Входной вектор должен содержать только 0 и 1');
end


% Шаг 4: Вычисление выходного вектора
output_vector = zeros(1, 1664);
for i = 1:3328
    if bit_vector(i) == 1
        output_vector = xor(output_vector, Pg(i, :));
    end
end

% Шаг 5: Сохранение выходного вектора в файл output_vector.txt
fileID = fopen('output_vector.txt', 'w');
fprintf(fileID, '%s', num2str(output_vector, '%d'));  % Записываем одну строку из 128 бит
fclose(fileID);

% Отладочный вывод для проверки
disp('Выходной вектор:');
disp(num2str(output_vector, '%d'));