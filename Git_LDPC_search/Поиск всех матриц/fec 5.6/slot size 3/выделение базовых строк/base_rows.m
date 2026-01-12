clear;
load('Pg.mat');
rows = Pg(1:48:960, :);
fid = fopen('base_rows.txt', 'w');
for i = 1:size(rows, 1)
    fprintf(fid, '%d', rows(i, :));
    fprintf(fid, '\n');
end
fclose(fid);
disp('20 строк сохранены в rows.txt');