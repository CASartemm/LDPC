clear;

tic; disp('Начало выполнения скрипта...');

% -------- загрузка --------
Slots = load("Slots_1152.mat"); 
Slots = Slots.Slots;
payload = Slots(:,21:end);
nSlots  = size(payload,1);

% -------- демодуляция (предвыделение, logical) --------
t_demod = tic;
firstRow = demodqpsk_istar(payload(1,:));
data = false(nSlots, numel(firstRow));   % logical компактней/быстрее
data(1,:) = logical(firstRow);
for i = 2:nSlots
    data(i,:) = logical(demodqpsk_istar(payload(i,:)));
end
fprintf('Время демодуляции: %.3f с\n', toc(t_demod));

% -------- дескремблирование (векторно в GF(2)) --------
t_descr = tic;
dataLen = size(data,2);
seqA = logical(scrembler_istar([1 0 0 1 0 1 0 1 0 1 0 1 1 1 1], dataLen));
seqB = logical(scrembler_istar([0 0 0 1 1 1 0 0 0 1 1 1 0 0 0], dataLen));

odd  = 1:2:dataLen;
even = 2:2:dataLen;

xA = false(1,dataLen); xA(odd)  = seqA((odd+1)/2);
xB = false(1,dataLen); xB(even) = seqB(even/2);

data = xor(data, xA);
data = xor(data, xB);
fprintf('Время дескремблирования: %.3f с\n', toc(t_descr));

% -------- GF(2): ранг, det(mod2), решение всех RHS --------
t_gf2 = tic;

% квадрат 960x960 и 192 правых частей (столбцы 961..1152)
A = data(1:1152, 1:1152);
B = data(1:1152, 1153:2304);      % 192 RHS

[rnk960, det960, P] = gf2_rank_det_solve(A, B);  % P: 960x192 logical

% если нужен det для 192x192 как в твоём коде
[~, det192, ~] = gf2_rank_det_solve( logical(data(1:192,1:192)), false(192,0) );

fprintf('GF(2): rank(960x960)=%d, det960(mod2)=%d, det192(mod2)=%d\n', rnk960, det960, det192);
fprintf('Время GF(2) этапа: %.3f с\n', toc(t_gf2));

% -------- визуализация --------
figure; imagesc(double(P)); grid on; colorbar; title('P (960×192) в GF(2)');
figure; imagesc(P'); title('P^T');

fprintf('\nОбщее время: %.3f с\n', toc);


% ===== Локальная функция: быстрый Гаусс над GF(2) =====
function [rnk, det_mod2, X] = gf2_rank_det_solve(A, B)
% A — m×n logical, B — m×k logical (k может быть 0).
% Возврат: rnk — ранг в GF(2); det_mod2 — 0/1; X — n×k базисное решение.

    A = logical(A); B = logical(B);
    [m,n] = size(A); k = size(B,2);
    if ~isempty(B) && size(B,1) ~= m, error('size(B,1) ~= size(A,1)'); end

    U = A; Y = B; r = 1; pc = 0; piv_cols = zeros(1,min(m,n));

    % --- прямой ход ---
    for c = 1:n
        if r > m, break; end
        pivotRow = find(U(r:end,c),1,'first');
        if isempty(pivotRow), continue; end
        pivotRow = pivotRow + r - 1;

        if pivotRow ~= r
            tmp = U(r,:); U(r,:) = U(pivotRow,:); U(pivotRow,:) = tmp;
            if k>0, tmp = Y(r,:); Y(r,:) = Y(pivotRow,:); Y(pivotRow,:) = tmp; end
        end

        below = r+1:m;
        if ~isempty(below)
            idx = below(U(below,c));
            if ~isempty(idx)
                U(idx,:) = xor(U(idx,:), U(r,:));
                if k>0, Y(idx,:) = xor(Y(idx,:), Y(r,:)); end
            end
        end

        pc = pc + 1; piv_cols(pc) = c; r = r + 1;
    end
    rnk = pc; piv_cols = piv_cols(1:pc);

    % --- обратный ход (Жордан) ---
    for t = pc:-1:1
        row = t; col = piv_cols(t);
        if row > 1
            idx = 1:row-1; idx = idx(U(idx,col));
            if ~isempty(idx)
                U(idx,:) = xor(U(idx,:), U(row,:));
                if k>0, Y(idx,:) = xor(Y(idx,:), Y(row,:)); end
            end
        end
    end

    % --- решение (свободные = 0) ---
    if k>0
        X = false(n,k);
        if rnk > 0, X(piv_cols,:) = Y(1:rnk,:); end
    else
        X = false(n,0);
    end

    % --- det mod 2 ---
    det_mod2 = logical(m == n && rnk == n);
end
