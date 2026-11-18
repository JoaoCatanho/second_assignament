function L = ann_lib()
L.load_concrete = @load_concrete;
% ... one handle per library function
end

function C = load_concrete(path)
  txt = fileread(path);
  lines = regexp(txt, '\r?\n', 'split'); 
  lines = lines(2:end); # salta o cabeçalho
  lines = lines(~cellfun(@isempty, strtrim(lines))); 

  if any(lines{1} == ';')                        % formato PT: (;)separa, (,)decimal
    lines = strrep(lines, ',', '.');
    lines = strrep(lines, ';', ',');
  end
  M = zeros(numel(lines), 9);

  for i = 1:numel(lines)
    v = sscanf(strrep(lines{i}, ' ', ''), '%f,');
    if numel(v) ~= 9, error('Linha %d do CSV nao tem 9 valores', i + 1); end
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

  c = textscan(fid, '%s %s', 'Delimiter', ',', 'HeaderLines', 1);
  fclose(fid);

  d = strrep(c{1}, '"', '');
  t = strrep(c{2}, '"', '');
  t = regexprep(t, '[^0-9.\-]', '');    % limpa caracteres estranhos (ex. '?')
  ok = ~cellfun(@isempty, regexp(d, '^\d{4}-\d{2}-\d{2}$'));
  d = d(ok); t = t(ok);                  % ignora linhas de rodape / vazias
  S.dates = datenum(d, 'yyyy-mm-dd');
  S.y     = str2double(t);
  S.target = 'MinTemp';
  S.target_unit = 'graus C';
end

function theta = init_params(layers, seed)
% ...
end
% In main_assignment2.m:
L = ann_lib();
[theta, hist] = L.train_adam(theta0, layers, Xtr, ytr, Xva, yva, opts);