% ===== ЗАНУЛЕНИЕ ЕДИНИЦ В 10-Й СТРОКЕ + КРУПНАЯ КВАДРАТНАЯ ВИЗУАЛИЗАЦИЯ =====
clear; clc;
tic; disp('Начало выполнения скрипта...');

%% -------- загрузка --------
t_load = tic;
filename = 'P.mat';
if ~isfile(filename)
    error('Файл %s не найден.', filename);
end
S = load(filename);
if isfield(S,'P')
    vname = 'P';
else
    fns = fieldnames(S);
    if isempty(fns), error('MAT-файл пуст.'); end
    vname = fns{1};
end
P = S.(vname);

if ~(islogical(P) || isnumeric(P))
    error('Ожидается логическая/числовая матрица 0/1. Найден тип: %s', class(P));
end
P = logical(P);
[m,n] = size(P);
fprintf('Загрузка: %s размером %dx%d за %.3f с\n', vname, m, n, toc(t_load));

if m < 10
    error('В матрице меньше 10 строк.');
end

%% -------- визуализация (ДО): большое квадратное окно --------
t_vis1 = tic;
fig1 = figure('Name','P (исходная)','Color','w');
set(fig1, 'Units','normalized','OuterPosition',[0 0 1 1]);    % на весь экран

imagesc(double(P));
axis tight; axis off;                                         % максимум места под картинку
colormap(gray); colorbar;
title(sprintf('%s: исходная, %dx%d, единиц: %d', vname, m, n, nnz(P)), ...
      'FontSize',16,'FontWeight','bold');

% делаем область построения квадратной и крупной
set(gca, 'Position', [0.05 0.05 0.90 0.90]);

fprintf('Визуализация (до): %.3f с\n', toc(t_vis1));

%% -------- модификация: занулить всю 10-ю строку (без изменения размера) --------
t_edit = tic;
P2 = P;                          % копия исходной матрицы
ones_in_row10 = nnz(P2(10,:));   % сколько единиц будет занулено
P2(10,:) = false;                % занулить всю строку 10
fprintf('Зануление: строка 10, занулено единиц = %d. Время: %.3f с\n', ...
        ones_in_row10, toc(t_edit));

%% -------- визуализация (ПОСЛЕ): большое квадратное окно --------
t_vis2 = tic;
fig2 = figure('Name','P (после зануления строки 10)','Color','w');
set(fig2, 'Units','normalized','OuterPosition',[0 0 1 1]);    % на весь экран

imagesc(double(P2));
axis tight; axis off;
colormap(gray); colorbar;
title(sprintf('%s: после, %dx%d, единиц: %d', vname, size(P2,1), size(P2,2), nnz(P2)), ...
      'FontSize',16,'FontWeight','bold');

set(gca, 'Position', [0.05 0.05 0.90 0.90]);

fprintf('Визуализация (после): %.3f с\n', toc(t_vis2));

%% -------- сводка и сохранение --------
fprintf('ИТОГО: размер был %dx%d, остался %dx%d. Занулено в 10-й строке: %d элементов\n', ...
    m, n, size(P2,1), size(P2,2), ones_in_row10);

t_save = tic;
S.(vname) = P2;
save(filename, '-struct', 'S');   % перезаписываем в тот же файл; при желании поменяй имя
fprintf('Сохранено в %s за %.3f с\n', filename, toc(t_save));

fprintf('\nОбщее время: %.3f с\n', toc);
