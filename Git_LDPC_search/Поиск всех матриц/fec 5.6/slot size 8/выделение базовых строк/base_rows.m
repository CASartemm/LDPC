clear;
load('Pg.mat');
rows = Pg(1:128:2560, :);
fid = fopen('rows_512.txt', 'w');
for i = 1:size(rows, 1)
    fprintf(fid, '%d', rows(i, :));
    fprintf(fid, '\n');
end
fclose(fid);
disp('20 строк сохранены в rows_1024.txt');