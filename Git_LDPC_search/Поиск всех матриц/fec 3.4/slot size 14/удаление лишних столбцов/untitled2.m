% Открываем исходный файл для чтения
fid = fopen('data_4032_Scrembled_bin.txt', 'r');
if fid == -1
    error('Не удалось открыть файл data_640_Scrembled_bin.txt');
end

% Читаем файл построчно
lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line)
        lines{end+1} = line;
    end
end
fclose(fid);

% Указываем позиции бит для удаления (например, только первый бит) для 640
% бит 
%remove_idx = [1:42, 59, 76, 813:817]; % Можно изменить на [1, 3, 5] для удаления нескольких позиций

 remove_idx = [1:42, 59, 76, 5421:5425]; % Можно изменить на [1, 3, 5] для удаления нескольких позиций

% Обрабатываем каждую строку
modified_lines = {};
for i = 1:length(lines)
    binary_str = lines{i};
    % Определяем индексы бит, которые нужно оставить
    keep_idx = setdiff(1:length(binary_str), remove_idx);
    % Удаляем указанные биты
    modified_binary_str = binary_str(keep_idx);
    modified_lines{end+1} = modified_binary_str;
end

% Записываем результат в новый файл
fid = fopen('modified_data_4032.txt', 'w');
if fid == -1
    error('Не удалось создать файл modified_data.txt');
end
for i = 1:length(modified_lines)
    fprintf(fid, '%s\n', modified_lines{i});
end
fclose(fid);

disp('Обработка завершена. Результат сохранён в scrambled.txt');