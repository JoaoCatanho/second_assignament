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
