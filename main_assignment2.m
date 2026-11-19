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