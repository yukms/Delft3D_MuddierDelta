% --- default setting ---
ratio = linspace(1, 20, 16)';
total = 0.3; % kgm-3
COH_settlevel = 0.25 / 10 / 100; % mm/s -> m/s
MORFAC = 100;
Qw = 1000;

% --- Figure style ---
figure('Units', 'Centimeters', 'Position', [0, 0, 12, 9]);

loadname = ["R29.mat", "R30.mat", "R31.mat", "R32.mat"];
colors = {'r', 'g', 'b', 'k'};
sea_level_rise_labels = {'0 mm/yr', '3 mm/yr', '5 mm/yr', '7 mm/yr'}; % 범례용 라벨
legend_handles_sand = [];
legend_handles_mud = [];

% A* 
load(loadname(1));
x_axis = MORFAC * log.delta_area(81:end, :) * COH_settlevel / (Qw * total / 2650);

% --- data load and plot ---
for i = 1:4
    load(loadname(i));
    sand_data = log.r_sand_delta(80:end, :);
    mud_data = log.r_mud_delta(80:end, :);
    
    % mean and 95% CI
    mean_sand = mean(sand_data, 2);
    mean_mud = mean(mud_data, 2);
    n = size(sand_data, 2);
    ci_sand = 1.96 * std(sand_data, 0, 2) / sqrt(n);
    ci_mud = 1.96 * std(mud_data, 0, 2) / sqrt(n);
    x_mean = mean(x_axis, 2);
    
    % Sand Retention Fraction
    subplot(2, 1, 1);
    hold on;
    fill_x = [x_mean; flipud(x_mean)];
    fill_y_sand = [mean_sand - ci_sand; flipud(mean_sand + ci_sand)];
    fill(fill_x, fill_y_sand, colors{i}, 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    h_sand = plot(x_mean, mean_sand, 'Color', colors{i}, 'LineWidth', 1.5);
    legend_handles_sand = [legend_handles_sand, h_sand];
    
    % Mud Retention Fraction
    subplot(2, 1, 2);
    hold on;
    fill_y_mud = [mean_mud - ci_mud; flipud(mean_mud + ci_mud)];
    fill(fill_x, fill_y_mud, colors{i}, 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    h_mud = plot(x_mean, mean_mud, 'Color', colors{i}, 'LineWidth', 1.5);
    legend_handles_mud = [legend_handles_mud, h_mud];
end

%% --- Figure details ---
font_name = 'Helvetica';
tick_font_size = 7;
label_font_size = 8;
title_font_size = 9;
legend_font_size = 6;
subplot_labels = {'a', 'b'};

for k = 1:2
    subplot(2, 1, k);
    
    set(gca, 'FontName', font_name, 'FontSize', tick_font_size);
    box on;
    grid on;
    
    % a, b labels
    text(-0.2, 1.05, subplot_labels{k}, 'Units', 'Normalized', ...
        'FontSize', title_font_size + 2, 'FontWeight', 'bold', 'FontName', font_name);

    % 
    if k == 1 % Sand 
        title('Sand Retention', 'FontSize', title_font_size);
        ylabel('Sand Retention Fraction', 'FontSize', label_font_size);
        lgd = legend(legend_handles_sand, sea_level_rise_labels, 'Location', 'southeast');
    else % Mud 
        title('Mud Retention', 'FontSize', title_font_size);
        ylabel('Mud Retention Fraction', 'FontSize', label_font_size);
        lgd = legend(legend_handles_mud, sea_level_rise_labels, 'Location', 'southeast');
    end
    
    xlabel('A*', 'FontSize', label_font_size); % 
    xlim([0.5e6 4e6])
    lgd.FontSize = legend_font_size;
    lgd.Box = 'off'; %
end