clear;
load('Pg.mat');
rows = Pg(1:240:4320, :);
fid = fopen('rows.txt', 'w');
for i = 1:size(rows, 1)
    fprintf(fid, '%d', rows(i, :));
    fprintf(fid, '\n');
end
fclose(fid);
disp('20 строк сохранены в rows.txt');