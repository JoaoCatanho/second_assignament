% In main_assignment2.m:
clear; clc; close all;
L = ann_lib();


C = L.load_concrete(fullfile('Datasets', 'Concrete_Data.csv'));
fprintf('\n=== CONCRETE: %d observacoes, %d entradas ===\n', size(C.X,1), size(C.X,2));
L.describe([C.X C.y], [C.names {C.target}], [C.units {C.target_unit}]);

M = L.load_melbourne(fullfile('Datasets', 'daily-minimum-temperatures-in-me.csv'));
fprintf('\n=== MELBOURNE ===\n');
L.describe(M.y, {M.target}, {M.target_unit});
M.info = L.check_series(M.dates, M.y);


% ---- fase 2 ------ %
f = L.plot_histograms([C.X C.y], [C.names {C.target}], [C.units {C.target_unit}]);
L.save_plot(f, 'concrete_hist');
close(f);

[R, f] = L.plot_correlation_matrix([C.X C.y], [C.names {C.target}]);
L.save_plot(f, 'concrete_corr');
close(f);
fprintf('\n=== CONCRETE: correlacao de cada entrada com a resistencia ===\n');
[~, ord] = sort(abs(R(1:end-1, end)), 'descend');
for j = ord'
  fprintf('  %-18s r = %+.3f\n', C.names{j}, R(j, end));
end

% Scatter de cada entrada contra a resistencia
f = L.plot_scatter_vs_y(C.X, C.y, C.names, 'Strength (MPa)');
L.save_plot(f, 'concrete_scatter');
close(f);

% --- Melbourne: autocorrelacao testes, depois é retirar
r = L.autocorrelation(M.y, 730);
fprintf('\n=== MELBOURNE: ACF ===\n');
fprintf('r(0)=%.3f  r(1)=%.3f  r(2)=%.3f  r(3)=%.3f  r(7)=%.3f\n', r(1), r(2), r(3), r(4), r(8));
fprintf('r(182)=%.3f (meio ano)  r(365)=%.3f (um ano)\n', r(183), r(366));

% --- Melbourne
E = L.plot_melbourne_eda(M.dates, M.y, 730);
fprintf('\n=== MELBOURNE: EDA ===\n');
fprintf('Mes mais quente: %.1f C | mes mais frio: %.1f C\n', max(E.month_mean), min(E.month_mean));
fprintf('ACF: r(1)=%.3f r(2)=%.3f r(3)=%.3f r(182)=%.3f r(365)=%.3f\n', ...
        E.acf(2), E.acf(3), E.acf(4), E.acf(183), E.acf(366));
fprintf('Variacoes bruscas (> 4 desvios = %.1f C): %d\n', 4*E.diff_std, numel(E.jumps));

[Xc, Cnames, Cunits] = L.concrete_features(C.X, C.names, C.units);
fprintf('\n=== CONCRETE: %d x %d (8 originais + logAge + W/C) ===\n', size(Xc, 1), size(Xc, 2));
r = corrcoef([Xc C.y]);
fprintf('r(Age, y) = %.3f | r(logAge, y) = %.3f | r(W/C, y) = %.3f\n', r(8, end), r(9, end), r(10, end));
disp(Xc(1:3, 8:10))

% ---Melbourne: preencher os 2 dias em falta
[Md, My, filled] = L.fill_gaps(M.dates, M.y);
fprintf('\n=== MELBOURNE ===\n');
fprintf('Dias antes: %d | depois: %d | preenchidos: %d\n', numel(M.y), numel(My), sum(filled));
for k = find(filled)'
  fprintf('  %s -> %.2f C  (vizinhos: %.1f e %.1f)\n', datestr(Md(k), 'yyyy-mm-dd'), My(k), My(k-1), My(k+1));
end

% PACF (justificacao da janela p)
pc = L.pacf(My, 15);
fprintf('PACF k=1..15: %s\n', sprintf('%.2f ', pc));
fprintf('Limite 95%%: +-%.3f\n', 1.96 / sqrt(numel(My)));

% ---Melbourne: tabela de entradas (janela p = 7, por agora fixo)
[Xm, tm, im] = L.make_lags(My, Md, 7);
fprintf('Tabela Melbourne: %d x %d | alvos: %d\n', size(Xm, 1), size(Xm, 2), numel(tm));
fprintf('Linha 1: %s| alvo %.1f\n', sprintf('%.2f ', Xm(1, :)), tm(1));
fprintf('Hoje = %s  ->  alvo = %s\n', datestr(Md(im(1)), 'yyyy-mm-dd'), datestr(Md(im(1) + 1), 'yyyy-mm-dd'));

%--- Melbourne: particao cronologica 70/15/15
F_TR = 0.70; F_VA = 0.15;
[itr_m, iva_m, ite_m] = L.split_chrono(numel(tm), F_TR, F_VA);
dt = Md(im + 1);   % data do ALVO de cada linha
fprintf('Treino: %d (%s a %s)\n', numel(itr_m), datestr(dt(itr_m(1)), 'yyyy-mm-dd'), datestr(dt(itr_m(end)), 'yyyy-mm-dd'));
fprintf('Valid.: %d (%s a %s)\n', numel(iva_m), datestr(dt(iva_m(1)), 'yyyy-mm-dd'), datestr(dt(iva_m(end)), 'yyyy-mm-dd'));
fprintf('Teste : %d (%s a %s)\n', numel(ite_m), datestr(dt(ite_m(1)), 'yyyy-mm-dd'), datestr(dt(ite_m(end)), 'yyyy-mm-dd'));

% --- Escolha da janela p (AR linear + sin/cos, erro na VALIDACAO)
F_TR = 0.70; F_VA = 0.15;
[P, tab] = L.choose_window(My, Md, [1 2 3 5 7 10 14 21 30], F_TR, F_VA);
fprintf('Escolha da janela (RMSE de validacao):\n');
fprintf('  p = %2d  ->  %.4f C\n', tab');
fprintf('Janela escolhida: p = %d\n', P);

[Xm, tm, im] = L.make_lags(My, Md, P);   % <- antes estava 7

% --- Concrete: particao aleatoria 70/15/15 (semente 42)
SEED = 42;
[itr_c, iva_c, ite_c] = L.split_random(size(Xc, 1), F_TR, F_VA, SEED);
fprintf('\n=== CONCRETE: PARTICAO ===\n');
fprintf('Treino %d | Valid. %d | Teste %d\n', numel(itr_c), numel(iva_c), numel(ite_c));
fprintf('Primeiros indices de teste: %s\n', sprintf('%d ', ite_c(1:5)));
fprintf('Media de y: treino %.1f | valid. %.1f | teste %.1f MPa\n', mean(C.y(itr_c)), mean(C.y(iva_c)), mean(C.y(ite_c)));
fprintf('Sobreposicao treino/valid.: %d | total de linhas usadas: %d\n', numel(intersect(itr_c, iva_c)), numel(unique([itr_c; iva_c; ite_c])));

% --- Teste do scaler (Concrete)
S  = L.fit_scaler(Xc(itr_c, :));
fprintf('\n=== SCALER (Concrete) ===\n');
fprintf('Cement: media %.1f | desvio %.1f\n', S.mu(1), S.sigma(1));
Ztr = L.apply_scaler(Xc(itr_c, :), S);
Zte = L.apply_scaler(Xc(ite_c, :), S);
fprintf('Cement normalizado - treino: media %.3f desvio %.3f | teste: media %.3f desvio %.3f\n', ...
        mean(Ztr(:, 1)), std(Ztr(:, 1)), mean(Zte(:, 1)), std(Zte(:, 1)));
fprintf('Exemplo: Cement %.1f -> z = %.3f\n', Xc(itr_c(1), 1), Ztr(1, 1));
Xback = L.invert_scaler(Ztr, S);
fprintf('Erro maximo ao desfazer: %g\n', max(abs(Xback(:) - reshape(Xc(itr_c, :), [], 1))));

%% ===== PASSO 4: PACOTES D =====
% Nomes das colunas do Melbourne: T(t-6) ... T(t), sin_doy, cos_doy
Mnames = cell(1, P + 2);
for j = 1:P
  Mnames{j} = sprintf('T(t-%d)', P - j);
end
Mnames{P}     = 'T(t)';
Mnames{P + 1} = 'sin_doy';
Mnames{P + 2} = 'cos_doy';

Dc = L.build_D(Xc, C.y, itr_c, iva_c, ite_c, Cnames);
Dm = L.build_D(Xm, tm,  itr_m, iva_m, ite_m, Mnames);
Dm.dates_target = Md(im + 1);   % data de cada alvo (para graficos)
Dm.persist      = Xm(:, P);     % T(t) em C: modelo "amanha = hoje"

fprintf('\n=== PACOTES D ===\n');
fprintf('Concrete : Xtr %dx%d | Xva %dx%d | Xte %dx%d | d = %d\n', size(Dc.Xtr), size(Dc.Xva), size(Dc.Xte), Dc.d);
fprintf('Melbourne: Xtr %dx%d | Xva %dx%d | Xte %dx%d | d = %d\n', size(Dm.Xtr), size(Dm.Xva), size(Dm.Xte), Dm.d);
fprintf('Concrete  y: media %.2f MPa | desvio %.2f MPa\n', Dc.mu_y, Dc.sigma_y);
fprintf('Melbourne y: media %.2f C   | desvio %.2f C\n', Dm.mu_y, Dm.sigma_y);
fprintf('Nomes Melbourne: %s\n', strjoin(Dm.names, ', '));

e = Dm.persist(Dm.idx.te) - tm(Dm.idx.te);
fprintf('Persistencia (amanha = hoje), RMSE teste: %.3f C\n', sqrt(mean(e .^ 2)));

save('dados_preparados.mat', 'Dc', 'Dm', '-v7');
fprintf('Guardado: dados_preparados.mat\n');