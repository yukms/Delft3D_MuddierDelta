%% Figure Generation: Separate Figures for Nature Geoscience
% Figure 1: Theoretical D50 range with uncertainty
% Figure 2: Estimated Input D50 vs Observed Topset D50 (Validation)

%% 1. Load and Calculation (데이터 처리)
% Load Data
T = readmatrix('FieldSaito.xlsx');
ratio1 = T(2:19, 10);              % Bed/Suspended Load Ratio
AvgTopsetD_saito = T(2:19, 8);     % Observed Topset Grain size [mm]
Area_saito = T(2:19, 7);           % Delta Area [km2]

% Parameters
u_star_ref = 0.1; h_ref = 3.0;

% Calculate Estimated D50
D50_input_saito = zeros(length(ratio1), 1);
for i = 1:length(ratio1)
    D50_input_saito(i) = estimate_D50_from_bedsus_ratio(ratio1(i), u_star_ref, h_ref);
end

% Calculate Uncertainty Band
u_star_min = 0.05; u_star_max = 0.2;
h_min = 1; h_max = 10;
R_range = logspace(-4, 1, 300); 

D50_ref = zeros(size(R_range));
D50_min = zeros(size(R_range));
D50_max = zeros(size(R_range));

for i = 1:length(R_range)
    R = R_range(i);
    D50_ref(i) = estimate_D50_from_bedsus_ratio(R, u_star_ref, h_ref);
    D_low = estimate_D50_from_bedsus_ratio(R, u_star_min, h_max);
    D_high = estimate_D50_from_bedsus_ratio(R, u_star_max, h_min);
    D50_min(i) = min([D_low, D_high]);
    D50_max(i) = max([D_low, D_high]);
end

%% Common Style Settings (공통 스타일)
fig_width = 8.9;   % Nature Single Column Width (cm)
fig_height = 8.0;  % Square-ish aspect ratio
font_name = 'Arial';

%% === Figure 1: Uncertainty Analysis ===
figure(1);
set(gcf, 'Units', 'centimeters', 'Position', [5, 10, fig_width, fig_height]);
set(gcf, 'Color', 'white');

hold on;

% 1. Uncertainty Band
fill_color = [0.85 0.90 0.95]; 
fill([R_range fliplr(R_range)], [D50_min fliplr(D50_max)], ...
    fill_color, 'EdgeColor', 'none', 'FaceAlpha', 1);

% 2. Reference Line
plot(R_range, D50_ref, 'k-', 'LineWidth', 1.0);

% 3. Field Data Inputs
scatter(ratio1, D50_input_saito, 25, 'r', 'filled', ...
    'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.8);

% Formatting
set(gca, 'XScale', 'log', 'YScale', 'log');
xlim([1e-4 10]);
ylim([1e-3 100]);

xlabel('Bedload / Suspended load Ratio', 'FontSize', 7, 'FontName', font_name);
ylabel('Estimated D_{50} (mm)', 'FontSize', 7, 'FontName', font_name);

set(gca, 'FontSize', 6, 'FontName', font_name, 'LineWidth', 0.5, ...
    'TickDir', 'out', 'Box', 'on', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
grid on;
set(gca, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.3);

legend({'Uncertainty', 'Reference', 'Field Data'}, ...
    'Location', 'northwest', 'FontSize', 6, 'Box', 'off');

% (Optional) Save
% print(gcf, 'Figure_Uncertainty.eps', '-depsc', '-painters');

%% === Figure 2: Validation (Observed vs Estimated) ===
figure(2);
set(gcf, 'Units', 'centimeters', 'Position', [15, 10, fig_width, fig_height]);
set(gcf, 'Color', 'white');

hold on;

% 1. 1:1 Line
min_val = 1e-3; max_val = 10;
plot([min_val max_val], [min_val max_val], 'k--', 'LineWidth', 0.5);

% 2. Linear Regression Fit
valid_idx = ~isnan(D50_input_saito) & ~isnan(AvgTopsetD_saito);
x_val = D50_input_saito(valid_idx);
y_val = AvgTopsetD_saito(valid_idx);

if length(x_val) > 2
    p_log = polyfit(log10(x_val), log10(y_val), 1);
    x_fit = logspace(log10(min(x_val)), log10(max(x_val)), 50);
    y_fit = 10.^polyval(p_log, log10(x_fit));
    
    plot(x_fit, y_fit, '-', 'Color', [0.2 0.4 0.8], 'LineWidth', 1.0);
    [R_corr, ~] = corr(log10(x_val), log10(y_val));
end

% 3. Scatter Plot (Size proportional to Area)
area_norm = Area_saito(valid_idx);
if ~isempty(area_norm)
    min_log = min(log10(area_norm));
    max_log = max(log10(area_norm));
    size_markers = 10 + 40 * (log10(area_norm) - min_log) / (max_log - min_log);
else
    size_markers = 25;
end

scatter(x_val, y_val, size_markers, 'k', 'filled', ...
    'MarkerFaceAlpha', 0.6, 'MarkerEdgeColor', 'none');

% Formatting
set(gca, 'XScale', 'log', 'YScale', 'log');
xlim([1e-2 5]); 
ylim([1e-2 5]);

xlabel('Estimated Input D_{50} (mm)', 'FontSize', 7, 'FontName', font_name);
ylabel('Observed Topset D_{50} (mm)', 'FontSize', 7, 'FontName', font_name);

set(gca, 'FontSize', 6, 'FontName', font_name, 'LineWidth', 0.5, ...
    'TickDir', 'out', 'Box', 'on', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
grid on;
set(gca, 'GridColor', [0.8 0.8 0.8], 'GridAlpha', 0.3);

legend({'1:1 Line', 'Fit', 'Field Data'}, ...
    'Location', 'southeast', 'FontSize', 6, 'Box', 'off');

if exist('R_corr', 'var')
    text(0.05, 0.95, sprintf('r = %.2f', R_corr), 'Units', 'normalized', ...
        'FontSize', 6, 'FontName', font_name, 'VerticalAlignment', 'top');
end

% (Optional) Save
% print(gcf, 'Figure_Validation.eps', '-depsc', '-painters');