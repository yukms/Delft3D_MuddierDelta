%% Figure 7: Combined Panel (a) and (b) - Nature Geoscience Double Column
% Panel (a): Input vs Deposited grain size (Left)
% Panel (b): A* vs Grain Size Ratio [Log-Log Scale] (Right)
%% River Names Definition
river_names = {'Amazon', 'Copper', 'Ebro', 'Fraser', 'Ganges-Brahmaputra', ...
               'Homathko', 'Huanghe', 'Irrawaddy', 'Klinaklini', 'Mackenzie', ...
               'Mekong', 'Mississippi', 'Niger', 'Nile', 'Po', ...
               'Rhone', 'Squamish', 'Yangtze'};
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
    D_avg_in(i) = estimate_D50_from_bedsus_ratio_corrected(1./V_ratio(i), 0.13, 3);
end
Tstarmax =max( MORFAC*log.delta_area(350,:)*COH_settlevel / (Qw*total/2650) );
%% Load Field data (Syvitski and Saito 2007)
T= readmatrix('FieldSaito.xlsx');
ratio1=T(2:19,10);
AvgTopsetD_saito = T(2:19,8);  %% mm
T_saito =T(2:19,9);  % T*
T_saito_max = max(T_saito);
% [수정 1] Calculate D50 for field data - 차원 오류 방지를 위해 열 벡터로 초기화
D50_input_saito = zeros(length(ratio1), 1); 
for i = 1: length(ratio1)
    D50_input_saito(i) = estimate_D50_from_bedsus_ratio_corrected( ratio1(i), 0.13, 3 );
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
% [수정 2] Field data (Convert to micrometers) - 트랜스포즈(') 제거하여 열 벡터 유지
x_field = 1000 * D50_input_saito; 
y_field = 1000 * AvgTopsetD_saito; 
% 무차원 입경 비율 계산 (D_dep / D_in)
ratio_field = y_field ./ x_field; 
ratio_model = y_model_clean ./ x_model_clean;
valid_f = ~(isnan(T_saito) | isnan(ratio_field)) & T_saito > 0 & ratio_field > 0;
valid_m = Tstar_model_clean > 0 & ratio_model > 0;
%% Create figure with Nature Geoscience Double Column Size
fig_width_cm = 18.3; 
fig_height_cm = 7.5; 
fig = figure('Units', 'centimeters', 'Position', [5, 5, fig_width_cm, fig_height_cm]);
set(gcf, 'Color', 'white');
set(gcf, 'PaperPositionMode', 'auto');
set(groot, 'defaultAxesFontName', 'Arial');
set(groot, 'defaultTextFontName', 'Arial');
mk_size = 15; 
color_field = [0.9 0.6 0.2];
color_model = [0.2 0.4 0.8];
%% ── Panel (a): Input vs Deposited grain size
subplot(1, 2, 1);
% Plot Scatter
scatter(x_field, y_field, mk_size, color_field, 'filled', 'MarkerFaceAlpha', 0.8, 'MarkerEdgeColor', 'none');
hold on;
scatter(x_model_clean, y_model_clean, mk_size, color_model, 'filled', 'MarkerFaceAlpha', 0.8, 'MarkerEdgeColor', 'none');
set(gca, 'XScale', 'log', 'YScale', 'log');
% Add 1:1 line
x_line = logspace(1, 3, 100);
plot(x_line, x_line, 'k--', 'LineWidth', 0.5);
% Linear regression for field data (log-log)
valid_field = ~(isnan(x_field) | isnan(y_field));
if sum(valid_field) >= 2
    x_f_a = x_field(valid_field); x_f_a = x_f_a(:);
    y_f_a = y_field(valid_field); y_f_a = y_f_a(:);
    [p_field, ~] = polyfit(log10(x_f_a), log10(y_f_a), 1);
    xfit_field = logspace(log10(min(x_f_a)), log10(max(x_f_a)), 100);
    plot(xfit_field, 10.^polyval(p_field, log10(xfit_field)), '-', 'Color', [0.8 0.4 0.1], 'LineWidth', 1.0);
    [R_field_a, P_field_a] = corr(log10(x_f_a), log10(y_f_a));
end
% Linear regression for model data (log-log)
if length(x_model_clean) >= 2
    x_m_a = x_model_clean(:); y_m_a = y_model_clean(:);
    [p_model, ~] = polyfit(log10(x_m_a), log10(y_m_a), 1);
    xfit_model = logspace(log10(min(x_m_a)), log10(max(x_m_a)), 100);
    plot(xfit_model, 10.^polyval(p_model, log10(xfit_model)), '--', 'Color', [0.1 0.2 0.6], 'LineWidth', 1.0);
    [R_model_a, P_model_a] = corr(log10(x_m_a), log10(y_m_a));
end
% Formatting & Axis Labels (LaTex interpreter for professional formatting)
xlabel('$D_{\mathrm{in}}$ ($\mu\mathrm{m}$)', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k', 'Interpreter', 'latex');
ylabel('$D_{\mathrm{dep}}$ ($\mu\mathrm{m}$)', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k', 'Interpreter', 'latex');
grid on; 
set(gca, 'FontSize', 6, 'FontName', 'Arial', 'GridColor', [0.8 0.8 0.8], ...
    'GridLineStyle', '-', 'GridAlpha', 0.3, 'MinorGridColor', [0.9 0.9 0.9], ...
    'MinorGridAlpha', 0.2, 'LineWidth', 0.5, 'TickDir', 'in', 'Box', 'off', ...
    'XColor', 'k', 'YColor', 'k');
legend({'Field data', 'Model data', '1:1 line', 'Field fit', 'Model fit'}, 'Location', 'southeast', ...
       'FontSize', 6, 'FontName', 'Arial', 'Box', 'off', 'TextColor', 'k');
% [수정 3] 고정된 축 범위 제거 (Autoscale 활성화)
% xlim([10 100])은 주석 처리 또는 제거하여 자동 조절
% ylim([10 y_field_max])은 주석 처리 또는 제거하여 자동 조절
% Add River Name labels
for i = 1:length(D50_input_saito)
    if i <= length(river_names)
        text(1000*D50_input_saito(i), 1000*AvgTopsetD_saito(i), ['  ', river_names{i}], ...
             'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', 'FontSize', 5, 'Color', 'k')
    end
end
% 패널 문자 설정
text(-0.15, 1.05, 'a', 'Units', 'normalized', 'FontSize', 8, 'FontWeight', 'bold', ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'Color', 'k');
% 통계치 텍스트 표시
if exist('R_field_a', 'var')
    text_str_a = sprintf('Field: r=%.2f, p=%.3f\nModel: r=%.2f, p=%.3f', R_field_a, P_field_a, R_model_a, P_model_a);
    text(0.05, 0.95, text_str_a, 'Units', 'normalized', 'FontSize', 6, ...
         'FontName', 'Arial', 'Color', 'k', 'BackgroundColor', 'none', ...
         'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
end
%% ── Panel (b): A* vs Grain Size Ratio [Log-Log Scale]
subplot(1, 2, 2);
% Plot Scatter (X축에 T_saito 및 Tstar_model_clean 매핑)
scatter(T_saito, ratio_field, mk_size, color_field, 'filled', 'MarkerFaceAlpha', 0.8, 'MarkerEdgeColor', 'none');
hold on;
scatter(Tstar_model_clean, ratio_model, mk_size, color_model, 'filled', 'MarkerFaceAlpha', 0.8, 'MarkerEdgeColor', 'none');
% 축 스케일 설정
set(gca, 'XScale', 'log', 'YScale', 'log');
% 회귀선 및 통계 계산
if sum(valid_f) >= 2
    T_f_b = T_saito(valid_f); T_f_b = T_f_b(:);
    r_f_b = ratio_field(valid_f); r_f_b = r_f_b(:);
    p_f1 = polyfit(log10(T_f_b), log10(r_f_b), 1);
    xf1 = logspace(log10(min(T_f_b)), log10(max(T_f_b)), 100);
    plot(xf1, 10.^polyval(p_f1, log10(xf1)), '-', 'Color', [0.8 0.4 0.1], 'LineWidth', 1.0);
    [R_f1, P_f1] = corr(log10(T_f_b), log10(r_f_b));
end
if sum(valid_m) >= 2
    T_m_b = Tstar_model_clean(valid_m); T_m_b = T_m_b(:);
    r_m_b = ratio_model(valid_m); r_m_b = r_m_b(:);
    p_m1 = polyfit(log10(T_m_b), log10(r_m_b), 1);
    xm1 = logspace(log10(min(T_m_b)), log10(max(T_m_b)), 100);
    plot(xm1, 10.^polyval(p_m1, log10(xm1)), '--', 'Color', [0.1 0.2 0.6], 'LineWidth', 1.0);
    [R_m1, P_m1] = corr(log10(T_m_b), log10(r_m_b));
end
% y=1 지점 점선 추가
x_limits = xlim;
plot(x_limits, [1, 1], 'k--', 'LineWidth', 0.5);
% 라벨 및 포맷팅 (Title 삭제 완료)
xlabel('$A^*$', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k', 'Interpreter', 'latex');
ylabel('$D_{\mathrm{dep}} / D_{\mathrm{in}}$', 'FontSize', 7, 'FontName', 'Arial', 'Color', 'k', 'Interpreter', 'latex');
grid on; 
set(gca, 'FontSize', 6, 'FontName', 'Arial', 'GridColor', [0.8 0.8 0.8], ...
    'GridLineStyle', '-', 'GridAlpha', 0.3, 'MinorGridColor', [0.9 0.9 0.9], ...
    'MinorGridAlpha', 0.2, 'LineWidth', 0.5, 'TickDir', 'in', 'Box', 'off', ...
    'XColor', 'k', 'YColor', 'k');
legend({'Field data', 'Model data', 'Field fit', 'Model fit'}, 'Location', 'southeast', ...
       'FontSize', 6, 'FontName', 'Arial', 'Box', 'off', 'TextColor', 'k');
% [수정 4] Y축 범위 제한(0.9 하한선) 제거하여 자동 조절
% ylim([0.9, max_ratio_val * 1.1]) 은 주석 처리 또는 제거하여 자동 조절
% River Name labels
for i = 1:length(T_saito)
    x = T_saito(i);
    y = ratio_field(i);
    if ~isnan(x) && ~isnan(y) && x > 0 && y > 0 && i <= length(river_names)
        text(x, y, ['  ', river_names{i}], 'VerticalAlignment', 'middle', ...
             'HorizontalAlignment', 'left', 'FontSize', 5, 'Color', 'k');
    end
end
% 패널 문자 설정
text(-0.15, 1.05, 'b', 'Units', 'normalized', 'FontSize', 8, 'FontWeight', 'bold', ...
     'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'Color', 'k');
% 패널 (b) 통계치 텍스트 표시
if exist('R_f1', 'var')
    text_str_b = sprintf('Field: r=%.2f, p=%.3f\nModel: r=%.2f, p=%.3f', R_f1, P_f1, R_m1, P_m1);
    text(0.05, 0.95, text_str_b, 'Units', 'normalized', 'FontSize', 6, ...
         'FontName', 'Arial', 'Color', 'k', 'BackgroundColor', 'none', ...
         'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
end