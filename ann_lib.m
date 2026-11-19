function L = ann_lib()
L.load_concrete = @load_concrete;
L.load_melbourne = @load_melbourne
L.describe = @describe
L.check_series = @check_series
L.plot_histograms = @plot_histograms
L.save_plot = @save_plot
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
  if nargin < 4, 
    nbins = 30 
  end;
  p = size(X, 2);
  nc = ceil(sqrt(p)); nr = ceil(p / nc);
  fig = figure('Position', [100 100 1000 700]);
  for j = 1:p
    subplot(nr, nc, j);
    hist(X(:, j), nbins);
    title(names{j}); xlabel(units{j}); ylabel('Frequencia');
  end
end

% da save do plot
function save_plot(fig, name)
  if ~exist('figure', 'dir'),
    mkdir('figures');
  end
  print(fig, fullfile('figures', [name '.png']), '-dpng', '-r150');
end