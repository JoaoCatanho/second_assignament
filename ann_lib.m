function L = ann_lib()
L.load_concrete = @load_concrete;
L.load_melbourne = @load_melbourne
L.describe = @describe
L.check_series = @check_series
L.plot_histograms = @plot_histograms
L.save_plot = @save_plot
L.plot_correlation_matrix = @plot_correlation_matrix;
L.plot_scatter_vs_y = @plot_scatter_vs_y;
L.autocorrelation = @autocorrelation
% ... one handle per library function
end

% ------ fase 1 ------- %
function C = load_concrete(path)
  txt = fileread(path);
  lines = regexp(txt, '\r?\n', 'split'); 
  lines = lines(2:end); % salta o cabeçalho
  lines = lines(~cellfun(@isempty, strtrim(lines))); % tira as linhas vazias

  if any(lines{1} == ';')                        % formato PT: (;)separa, (,)decimal
    lines = strrep(lines, ',', '.');
    lines = strrep(lines, ';', ',');
  end
  M = zeros(numel(lines), 9);

  for i = 1:numel(lines) % tira os espaços
    v = sscanf(strrep(lines{i}, ' ', ''), '%f,');
    if numel(v) ~= 9, error('Linha %d do CSV nao tem 9 valores', i + 1); end # se não tiver 9 numeros para
    M(i, :) = v';
  end
  C.X = M(:, 1:8);
  C.y = M(:, 9);
  C.names  = {'Cement','Slag','FlyAsh','Water','Superplasticizer', ...
              'CoarseAgg','FineAgg','Age'};
  C.units  = {'kg/m3','kg/m3','kg/m3','kg/m3','kg/m3','kg/m3','kg/m3','dias'};
  C.target = 'Strength';
  C.target_unit = 'MPa';
end

function S = load_melbourne(path)
% Le o CSV de Melbourne: "Date","Temp" (datas yyyy-mm-dd).
  fid = fopen(path, 'r');

  if fid < 0, error('Nao encontrei %s', path); end

  c = textscan(fid, '%s %s', 'Delimiter', ',', 'HeaderLines', 1); % lê como texto porque há 3 valores com "?"
  fclose(fid);

  d = strrep(c{1}, '"', ''); % vai tirar as aspas
  t = strrep(c{2}, '"', '');
  t = regexprep(t, '[^0-9.\-]', '');    % limpa caracteres estranhos (ex. '?')
  ok = ~cellfun(@isempty, regexp(d, '^\d{4}-\d{2}-\d{2}$'));
  d = d(ok); t = t(ok);                  % ignora linhas de rodape / vazias
  S.dates = datenum(d, 'yyyy-mm-dd'); % datas em numeros
  S.y     = str2double(t);
  S.target = 'MinTemp';
  S.target_unit = 'graus C';
end

function describe(X, names, units)
% Tabela de estatisticas descritivas (uma linha por variavel).
  fprintf('%-18s %-7s %9s %9s %9s %9s %9s %5s\n', ...
          'Variavel','Unid.','min','max','media','desvio','mediana','NaN');
  for j = 1:size(X, 2)
    x = X(:, j); ok = ~isnan(x); % para NaN não estragar
    fprintf('%-18s %-7s %9.2f %9.2f %9.2f %9.2f %9.2f %5d\n', names{j}, units{j}, ...
            min(x(ok)), max(x(ok)), mean(x(ok)), std(x(ok)), median(x(ok)), sum(~ok));
  end
end

function info = check_series(dates, y)
% Cobertura temporal, falhas de datas e valores suspeitos da serie.
  dd = diff(dates); % sempre 1
  info.start = datestr(dates(1), 'yyyy-mm-dd');
  info.stop = datestr(dates(end), 'yyyy-mm-dd');
  info.n = numel(y);
  info.n_expected = dates(end) - dates(1) + 1;
  info.gaps = find(dd ~= 1);                 % encontra saltos, datas em falta
  info.n_nan = sum(isnan(y)); % os valores em falta
  info.n_zero = sum(y == 0); % valores a 0
  fprintf('Periodo: %s a %s (%d valores, %d dias no calendario)\n', ...
          info.start, info.stop, info.n, info.n_expected);
  for k = info.gaps(:)'
    fprintf('  Falha: %s -> %s (%d dia(s) em falta)\n', datestr(dates(k),'yyyy-mm-dd'), ...
            datestr(dates(k+1),'yyyy-mm-dd'), dd(k) - 1);
  end
  fprintf('NaN: %d | zeros: %d\n', info.n_nan, info.n_zero);
end

% ----- fase 2 --------- %

% Histograma de cada coluna, um subplot para cada variavel
function fig = plot_histograms(X, names, units, nbins)
  if nargin < 4
    nbins = 30;
  end
  p = size(X, 2);
  nc = ceil(sqrt(p)); nr = ceil(p / nc);
  fig = figure('Position', [50 50 1400 900]);
  for j = 1:p
    subplot(nr, nc, j);
    hist(X(:, j), nbins);
    set(gca, 'FontSize', 8);                                  % letra pequena nos eixos
    lo = min(X(:, j)); hi = max(X(:, j));
    xlim([lo hi]);                                            % eixo do min ao max
    set(gca, 'XTick', round(linspace(lo, hi, 4)));            % so 4 numeros, arredondados
    title(names{j}, 'FontSize', 10);
    xlabel(units{j});
    if mod(j - 1, nc) == 0                                    % so na 1.a coluna
      ylabel('Frequencia');
    end
  end
end

% da save do plot
function save_plot(fig, name)
  if ~exist('figure', 'dir'),
    mkdir('figures');
  end
  print(fig, fullfile('figures', [name '.png']), '-dpng', '-r150');
end

% Matriz de Correlação de Pearson
function [R, fig] = plot_correlation_matrix (X, names) 

  R = corrcoef(X);
  p = size(R,1);
  fig = figure('Position', [100 100 1300 1100]);
  imagesc(R, [-1 1]); colorbar; axis square;
  colormap(jet(64));
  set(gca, 'XTick', 1:p, 'XTickLabel', {}, 'YTick', 1:p, 'YTickLabel', names, 'FontSize', 9);
  for j = 1:p                                 
    text(j, p + 0.7, names{j}, 'Rotation', 45, 'HorizontalAlignment', 'right', 'FontSize', 9);
  end

  for i = 1:p
    for j = 1:p
      text(j, i, sprintf('%.2f', R(i, j)), 'HorizontalAlignment', 'center', 'FontSize', 8);
    end
  end

  title('Matriz de correlação (Pearson)')
end 

function fig = plot_scatter_vs_y(X, y, names, namey) 

  p = size(X, 2);
  nc = ceil(sqrt(p)); nr = ceil(p / nc);
  fig = figure('Position', [50 50 1400 900]);

  for j = 1:p 
    subplot(nr, nc, j);
    plot(X(:, j), y, '.', 'MarkerSize', 4);
    set(gca, 'FontSize', 8);
    r = corrcoef(X(:, j), y);
    r = r(1, 2);
    title(sprintf('%s (r = %.2f)', names{j}, r), 'FontSize', 10);
    xlabel(names{j});
    if mod(j - 1, nc) == 0
      ylabel(namey);
    end
  end 
end

function r = autocorrelation(y, maxlag)

  y = y(:) - mean(y); % ver se o dia esta acima da média ou abaixo ex: +3, -2
  n = numel(y); % quantos dias
  den = sum(y .^2); % a soma dos quadrados
  r = zeros(maxlag + 1, 1);

  for k = 0:maxlag
    r(k+1) = sum(y(1:n-k) .* y(1+k:n)) /den;
  end
end
