clear;

%% Продление ТОЛЬКО по основной диагонали (↘) в строках 8..20 + визуализация
tic;

% --- Загрузка ---
S = load('P.mat');                % ожидается переменная P
if ~isfield(S,'P'), error('В файле P.mat не найдена переменная P.'); end
P = logical(S.P);
[nRows, nCols] = size(P);

rows = 8:20;      r1 = rows(1); r2 = rows(end);
bound_tol = 1;    % радиус окна около границ (0..2). 1 = проверяем строки 7..8 и 20..21

P_fixed = P;

%% === Продление по основной диагонали (↘): c - r = const ===
for d = -(nRows-1):(nCols-1)     % смещение диагонали

    % --- проверка наличия единиц около верхней и нижней границ полосы ---
    hasTop = false; hasBot = false;

    % верхняя граница: строки [r1-1-bound_tol .. r1-1+bound_tol]
    rTopMin = max(1, r1-1-bound_tol);
    rTopMax = min(nRows, r1-1+bound_tol);
    if rTopMin <= rTopMax
        for r = rTopMin:rTopMax
            c = r + d;
            if c >= 1 && c <= nCols && P(r,c)
                hasTop = true; break;
            end
        end
    end

    % нижняя граница: строки [r2+1-bound_tol .. r2+1+bound_tol]
    rBotMin = max(1, r2+1-bound_tol);
    rBotMax = min(nRows, r2+1+bound_tol);
    if rBotMin <= rBotMax
        for r = rBotMin:rBotMax
            c = r + d;
            if c >= 1 && c <= nCols && P(r,c)
                hasBot = true; break;
            end
        end
    end

    % --- если диагональ "заходит" в полосу с обеих сторон — протягиваем внутри 8..20 ---
    if hasTop && hasBot
        for r = r1:r2
            c = r + d;
            if c >= 1 && c <= nCols
                P_fixed(r,c) = true;
            end
        end
    end
end

%% --- Сохранение результата ---
save('P_fixed.mat','P_fixed');

%% --- Диагностика изменений ---
Delta = xor(P, P_fixed);
Delta_band = Delta; Delta_band([1:r1-1, r2+1:end], :) = false;

fprintf('Изменено (всего): %d элементов\n', nnz(Delta));
fprintf('Изменено в полосе 8..20: %d элементов\n', nnz(Delta_band));

% -------- визуализация --------
figure; imagesc(double(P)); grid on; colorbar; axis image;
title(sprintf('P (%d×%d) в GF(2)', nRows, nCols));

figure; imagesc(P'); grid on; colorbar; axis image;
title('P^T');

figure; imagesc(double(P_fixed)); grid on; colorbar; axis image;
title(sprintf('P_{fixed} (%d×%d): продление только по ↘ в строках 8–20', nRows, nCols));

figure; imagesc(P_fixed'); grid on; colorbar; axis image;
title('P_{fixed}^T');

figure; imagesc(double(Delta_band)); grid on; colorbar; axis image;
title('Изменения внутри 8–20: XOR(P, P_{fixed})');

fprintf('\nОбщее время: %.3f с\n', toc);
