%% Figure 7: Combined Panel (a) and (b) - Nature Geoscience Double Column
% Panel (a): Input vs Deposited grain size (Left)
% Panel (b): T* vs Deposited grain size (Right)

%% Load and prepare data
COH_settlevel=0.25/10/100 ; % mm/s -> m/s   (16.7μm)
total=0.3; 
MORFAC=100;
Qw=1000;
D_mud = 17e-6;       % [m]
D_sand = 225e-6;     % [m]
rho_mud = 500;       % [kg/m3]
rho_sand = 1600;     % [kg/m3]

% Load model data
load('R29.mat')
R = log.input_ratio;         % mud/sand mass ratio

% input D50 cal
V_ratio = R .* (rho_sand / rho_mud);
for i = 1:length(V_ratio)
    D_avg_in(i) = estimate_D50_from_bedsus_ratio(1./V_ratio(i), 0.1, 3);
end
Tstarmax =max( MORFAC*log.delta_area(350,:)*COH_settlevel / (Qw*total/2650) );

%% Load Field data (Syvitski and Saito 2007)
T= readmatrix('FieldSaito.xlsx');
ratio1=T(2:19,10);
AvgTopsetD_saito = T(2:19,8);  %% mm
T_saito =T(2:19,9);  % T*
T_saito_max = max(T_saito);

% Calculate D50 for field data
for i = 1: length(ratio1)
    D50_input_saito(i) = estimate_D50_from_bedsus_ratio( ratio1(i), 0.1, 3 );
end

%% Collect model data
time_steps = 100:50:350;
n_steps = length(time_steps);
n_runs = size(log.volume_mud_delta, 2);

% Preallocate arrays for model data
x_model_all = [];
y_model_all = [];
Tstar_all = [];

for i = 1:n_steps
    t = time_steps(i);
    
    % Calculate deposited grain size
    mud_vol = log.volume_mud_delta(t,:);
    sand_vol = log.volume_sand_delta(t,:);
    total_vol = mud_vol + sand_vol;
    
    % Avoid division by zero
    valid_idx = total_vol > 0;
    D_avg_dep = NaN(size(total_vol));
    D_avg_dep(valid_idx) = (17 * mud_vol(valid_idx) + 225 * sand_vol(valid_idx)) ./ total_vol(valid_idx);
    
    % Calculate T*
    Tstar = MORFAC * log.delta_area(t,:) * COH_settlevel / (Qw * total / 2650);
    
    % Store data
    x_model_all = [x_model_all, D_avg_in * 1000]; % Input grain size [μm]
    y_model_all = [y_model_all, D_avg_dep]; % Deposited grain size [μm]
    Tstar_all = [Tstar_all, Tstar]; % T*
end

% Remove NaN values from model data
valid_model = ~(isnan(x_model_all) | isnan(y_model_all) | isnan(Tstar_all));
x_model_clean = x_model_all(valid_model);
y_model_clean = y_model_all(valid_model);
Tstar_model_clean = Tstar_all(valid_model);

% Field data
x_field = 1000 * D50_input_saito'; % Convert to micrometers
y_field = 1000 * AvgTopsetD_saito; % Convert to micrometers

%% Create figure with Nature Geoscience Double Column Size
% Nature Standard Widths: 
% Double column: 183 mm (18.3 cm)

% === Double Column (183mm) 설정 ===
fig_width_cm = 18.3; 
fig_height_cm = 7.5; % 가로 배치이므로 높이는 줄여서 비율을 맞춤

fig = figure('Units', 'centimeters', 'Position', [5, 5, fig_width_cm, fig_height_cm]);
set(gcf, 'Color', 'white');
set(gcf, 'PaperPositionMode', 'auto');
set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');

% 마커 사이즈 (패널이 커졌으므로 조금 키워도 되지만 15정도로 유지)
mk_size = 15; 

%% Panel (a): Input avg grain size vs Deposited avg grain size (LEFT)
% 좌우 배치로 변경: subplot(1, 2, 1)
subplot(1, 2, 1);

% Plot Field data
scatter(x_field, y_field, mk_size, [0.9 0.6 0.2], 'filled', 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', 'none');
hold on;
% Plot Model data
scatter(x_model_clean, y_model_clean, mk_size, [0.2 0.4 0.8], 'filled', 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', 'none');

% Set log scale
set(gca, 'XScale', 'log', 'YScale', 'log');

% Add 1:1 line
x_line = logspace(1, 3, 100);
plot(x_line, x_line, 'k--', 'LineWidth', 0.5);

% Linear regression for field data (log-log)
valid_field = ~(isnan(x_field) | isnan(y_field));
if sum(valid_field) >= 2
    x_field_valid = x_field(valid_field);
    y_field_valid = y_field(valid_field);
    x_field_valid = x_field_valid(:);
    y_field_valid = y_field_valid(:);
    
    [p_field, ~] = polyfit(log10(x_field_valid), log10(y_field_valid), 1);
    x_range_field = [min(x_field_valid), max(x_field_valid)];
    xfit_field = logspace(log10(x_range_field(1)), log10(x_range_field(2)), 100);
    yfit_field = 10.^polyval(p_field, log10(xfit_field));
    plot(xfit_field, yfit_field, '-', 'Color', [0.8 0.4 0.1], 'LineWidth', 1.0);
    
    [R_field_a, P_field_a] = corr(log10(x_field_valid), log10(y_field_valid));
end

% Linear regression for model data (log-log)
if length(x_model_clean) >= 2
    x_model_col = x_model_clean(:);
    y_model_col = y_model_clean(:);
    
    [p_model, ~] = polyfit(log10(x_model_col), log10(y_model_col), 1);
    x_range_model = [min(x_model_col), max(x_model_col)];
    xfit_model = logspace(log10(x_range_model(1)), log10(x_range_model(2)), 100);
    yfit_model = 10.^polyval(p_model, log10(xfit_model));
    plot(xfit_model, yfit_model, '--', 'Color', [0.1 0.2 0.6], 'LineWidth', 1.0);
    
    [R_model_a, P_model_a] = corr(log10(x_model_col), log10(y_model_col));
end

% Formatting
xlabel('Input avg grain size (μm)', 'FontSize', 7, 'FontName', 'Arial');
ylabel('Deposited avg grain size (μm)', 'FontSize', 7, 'FontName', 'Arial');
grid on; 
set(gca, 'FontSize', 6, 'FontName', 'Arial', 'GridColor', [0.8 0.8 0.8], ...
    'GridLineStyle', '-', 'GridAlpha', 0.3, 'MinorGridColor', [0.9 0.9 0.9], ...
    'MinorGridAlpha', 0.2, 'LineWidth', 0.5, 'TickDir', 'out', 'Box', 'off');

% Legend 위치 조정 (넓어졌으므로 southeast 등으로 위치시켜도 좋음)
legend({'Field data', 'Model data', '1:1 line', 'Field fit', 'Model fit'}, 'Location', 'southeast', ...
       'FontSize', 6, 'FontName', 'Arial', 'Box', 'off');
xlim([10 100])
y_field_max = max(y_field(~isnan(y_field)));
ylim([10 y_field_max])

% Add numbered labels for field data (Panel a)
for i = 1:length(D50_input_saito)
    x = 1000 * D50_input_saito(i);
    y = 1000 * AvgTopsetD_saito(i);
    text(x, y, sprintf('%d', i), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 6)
end

% Add panel label (Left top, outside)
text(-0.15, 1.05, 'a', 'Units', 'normalized', 'FontSize', 8, 'FontWeight', 'bold', ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

% Add statistics text
if exist('R_field_a', 'var')
    text_str = sprintf('Field: r=%.2f\nModel: r=%.2f', R_field_a, R_model_a);
    text(0.05, 0.95, text_str, 'Units', 'normalized', 'FontSize', 6, ...
         'FontName', 'Arial', 'BackgroundColor', 'none', ...
         'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
end

%% Panel (b): T* vs Deposited avg grain size (RIGHT)
% 좌우 배치로 변경: subplot(1, 2, 2)
subplot(1, 2, 2);

% Field data
x_field_b = T_saito;
y_field_b = 1000 * AvgTopsetD_saito;

% Plot Field data
scatter(x_field_b, y_field_b, mk_size, [0.9 0.6 0.2], 'filled', 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', 'none');
hold on;
% Plot Model data
scatter(Tstar_model_clean, y_model_clean, mk_size, [0.2 0.4 0.8], 'filled', 'MarkerFaceAlpha', 0.9, 'MarkerEdgeColor', 'none');

% Set both axes to log scale
set(gca, 'XScale', 'log', 'YScale', 'log');

% Linear regression for field data (log-log)
valid_field_b = ~(isnan(x_field_b) | isnan(y_field_b)) & x_field_b > 0;
if sum(valid_field_b) >= 2
    x_field_b_valid = x_field_b(valid_field_b);
    y_field_b_valid = y_field_b(valid_field_b);
    x_field_b_valid = x_field_b_valid(:);
    y_field_b_valid = y_field_b_valid(:);
    
    [p_field_b, ~] = polyfit(log10(x_field_b_valid), log10(y_field_b_valid), 1);
    x_range_field_b = [min(x_field_b_valid), max(x_field_b_valid)];
    xfit_field_b = logspace(log10(x_range_field_b(1)), log10(x_range_field_b(2)), 100);
    yfit_field_b = 10.^polyval(p_field_b, log10(xfit_field_b));
    plot(xfit_field_b, yfit_field_b, '-', 'Color', [0.8 0.4 0.1], 'LineWidth', 1.0);
    
    [R_field_b, P_field_b] = corr(log10(x_field_b_valid), log10(y_field_b_valid));
end

% Linear regression for model data (log-log)
valid_model_b = Tstar_model_clean > 0;
if sum(valid_model_b) >= 2
    Tstar_col = Tstar_model_clean(valid_model_b);
    y_model_col_b = y_model_clean(valid_model_b);
    Tstar_col = Tstar_col(:);
    y_model_col_b = y_model_col_b(:);
    
    [p_model_b, ~] = polyfit(log10(Tstar_col), log10(y_model_col_b), 1);
    x_range_model_b = [min(Tstar_col), max(Tstar_col)];
    xfit_model_b = logspace(log10(x_range_model_b(1)), log10(x_range_model_b(2)), 100);
    yfit_model_b = 10.^polyval(p_model_b, log10(xfit_model_b));
    plot(xfit_model_b, yfit_model_b, '--', 'Color', [0.1 0.2 0.6], 'LineWidth', 1.0);
    
    [R_model_b, P_model_b] = corr(log10(Tstar_col), log10(y_model_col_b));
end

% Formatting
xlabel('T*', 'FontSize', 7, 'FontName', 'Arial');
ylabel('Deposited avg grain size (μm)', 'FontSize', 7, 'FontName', 'Arial');
grid on; 
set(gca, 'FontSize', 6, 'FontName', 'Arial', 'GridColor', [0.8 0.8 0.8], ...
    'GridLineStyle', '-', 'GridAlpha', 0.3, 'MinorGridColor', [0.9 0.9 0.9], ...
    'MinorGridAlpha', 0.2, 'LineWidth', 0.5, 'TickDir', 'out', 'Box', 'off');

legend({'Field data', 'Model data', 'Field fit', 'Model fit'}, 'Location', 'southeast', ...
       'FontSize', 6, 'FontName', 'Arial', 'Box', 'off');
ylim([10 y_field_max])

% === [추가됨] Add numbered labels for field data (Panel b) ===
for i = 1:length(x_field_b)
    x = x_field_b(i);
    y = y_field_b(i);
    if ~isnan(x) && ~isnan(y)
        text(x, y, sprintf('%d', i), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 6);
    end
end
% ==========================================================

% Add panel label
text(-0.15, 1.05, 'b', 'Units', 'normalized', 'FontSize', 8, 'FontWeight', 'bold', ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');

% Add statistics text
if exist('R_field_b', 'var')
    text_str = sprintf('Field: r=%.2f\nModel: r=%.2f', R_field_b, R_model_b);
    text(0.05, 0.95, text_str, 'Units', 'normalized', 'FontSize', 6, ...
         'FontName', 'Arial', 'BackgroundColor', 'none', ...
         'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
end

%% Print statistics to console
fprintf('\n=== Figure 7 Statistical Analysis (Double Column) ===\n');
fprintf('Panel (a) - Input vs Deposited grain size:\n');
if exist('R_field_a', 'var')
    fprintf('  Field data:  r = %.4f, p = %.4f\n', R_field_a, P_field_a);
    fprintf('  Model data:  r = %.4f, p = %.4f\n', R_model_a, P_model_a);
end
fprintf('\nPanel (b) - T* vs Deposited grain size:\n');
if exist('R_field_b', 'var')
    fprintf('  Field data:  r = %.4f, p = %.4f\n', R_field_b, P_field_b);
    fprintf('  Model data:  r = %.4f, p = %.4f\n', R_model_b, P_model_b);
end
fprintf('=====================================================\n\n');