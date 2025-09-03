
close;
% Чтение файла sequence.txt
fid = fopen('sequence.txt', 'r');
if fid == -1
    error('Не удалось открыть файл sequence.txt');
end
bits = textscan(fid, '%s');
bits = bits{1}{1};  % Получаем строку из cell-array
fclose(fid);

% Проверка, что строка содержит ровно 640 битов
if length(bits) ~= 640
    error('Файл не содержит ровно 640 битов');
end

% Вывод каждого бита на отдельной строке
bits_column = bits(:);
for i = 1:length(bits_column)
    disp(bits_column(i));
end

% Инвертирование последовательности
inverted_bits = bits;
inverted_bits(bits == '0') = '1';
inverted_bits(bits == '1') = '0';

% Сохранение инвертированной последовательности в файл inverted_sequence.txt
fid_out = fopen('inverted_sequence.txt', 'w');
if fid_out == -1
    error('Не удалось открыть файл для записи');
end
fprintf(fid_out, '%s', inverted_bits);
fclose(fid_out);