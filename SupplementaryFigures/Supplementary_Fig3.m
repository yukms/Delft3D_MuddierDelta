% --- Setting ---
figure('Units', 'inches', 'Position', [0, 0, 8, 9]); % Adjust figure size
loadname = ["R29.mat", "R30.mat", "R31.mat", "R32.mat"];
colors = {'r', 'g', 'b', 'k'};
sea_level_rise_labels = {'0 mm/yr', '3 mm/yr', '5 mm/yr', '7 mm/yr'};
COH_settlevel=0.25/10/100 ; % mm/s -> m/s   (16.7μm)
total=0.3; 
MORFAC=100;
Qw=1000;
for i = 1:4
    load(loadname(i));
    
    % Prepare data
    x_axis_raw = MORFAC * log.delta_area(81:end, :) * COH_settlevel / (Qw * total / 2650);
    sand_data = log.r_sand_delta(80:end, :);
    mud_data = log.r_mud_delta(80:end, :);
    
    x_mean = mean(x_axis_raw, 2);
    mean_sand = mean(sand_data, 2);
    mean_mud = mean(mud_data, 2);
    
    % Remove NaN values
    valid_indices_sand = ~isnan(x_mean) & ~isnan(mean_sand);
    valid_indices_mud = ~isnan(x_mean) & ~isnan(mean_mud);
    
    % -------------------------------------------------------------------
    % 1. Sand Retention (subplot 1)
    % -------------------------------------------------------------------
    subplot(3, 2, 1); 
    hold on;
    plot(x_mean, mean_sand, 'Color', colors{i}, 'LineWidth', 1.5, 'HandleVisibility','off');
    
    % -------------------------------------------------------------------
    % 2. Mud Retention (subplot 2)
    % -------------------------------------------------------------------
    subplot(3, 2, 2); 
    hold on;
    plot(x_mean, mean_mud, 'Color', colors{i}, 'LineWidth', 1.5, 'DisplayName', sea_level_rise_labels{i});
    
    %% ================================================================
    %% Method 1: Global Trend Fitting
    %% ================================================================
    % Mud: Linear fit
    p_mud = polyfit(x_mean(valid_indices_mud), mean_mud(valid_indices_mud), 1);
    y_fit_mud = polyval(p_mud, x_mean);
    subplot(3,2,2); 
    plot(x_mean, y_fit_mud, '--', 'Color', colors{i}, 'LineWidth', 2, 'HandleVisibility','off');
    fprintf('[%s - Mud] Linear slope: %.2e\n', sea_level_rise_labels{i}, p_mud(1));
    
    % Sand: Quadratic fit
    p_sand = polyfit(x_mean(valid_indices_sand), mean_sand(valid_indices_sand), 2);
    y_fit_sand = polyval(p_sand, x_mean);
    subplot(3,2,1); 
    plot(x_mean, y_fit_sand, '--', 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', [sea_level_rise_labels{i} ' Trend']);
    fprintf('[%s - Sand] Quadratic coeffs: a=%.2e, b=%.2e, c=%.2e\n', sea_level_rise_labels{i}, p_sand(1), p_sand(2), p_sand(3));
    
    %% ================================================================
    %% Method 2: Segmented Slope Analysis
    %% ================================================================
    num_segments = 6; % Split into 6 segments
    edges = linspace(min(x_mean), max(x_mean), num_segments + 1);
    slopes_sand = zeros(num_segments, 1);
    slopes_mud = zeros(num_segments, 1);
    
    for j = 1:num_segments
        segment_indices_sand = (x_mean >= edges(j)) & (x_mean < edges(j+1)) & valid_indices_sand;
        segment_indices_mud = (x_mean >= edges(j)) & (x_mean < edges(j+1)) & valid_indices_mud;
        
        if sum(segment_indices_sand) > 1
            p_seg_sand = polyfit(x_mean(segment_indices_sand), mean_sand(segment_indices_sand), 1);
            slopes_sand(j) = p_seg_sand(1);
        end
        if sum(segment_indices_mud) > 1
            p_seg_mud = polyfit(x_mean(segment_indices_mud), mean_mud(segment_indices_mud), 1);
            slopes_mud(j) = p_seg_mud(1);
        end
    end
    
    % Sand Segmented Slopes
    subplot(3,2,3); hold on;
    bar((1:num_segments) + (i-1)*0.2 - 0.4, slopes_sand, 0.2, 'FaceColor', colors{i}, 'DisplayName', sea_level_rise_labels{i});
    % Mud Segmented Slopes
    subplot(3,2,4); hold on;
    bar((1:num_segments) + (i-1)*0.2 - 0.4, slopes_mud, 0.2, 'FaceColor', colors{i}, 'DisplayName', sea_level_rise_labels{i});
    
    %% ================================================================
    %% Method 3: Moving Slope Analysis
    %% ================================================================
    window_size = floor(length(x_mean) / 10); 
    moving_slopes_sand = NaN(length(x_mean), 1);
    moving_slopes_mud = NaN(length(x_mean), 1);
    
    for j = 1 : length(x_mean) - window_size
        window_indices = j : j + window_size;
        
        valid_window_sand = intersect(window_indices, find(valid_indices_sand));
        if length(valid_window_sand) > 1
            p_mov_sand = polyfit(x_mean(valid_window_sand), mean_sand(valid_window_sand), 1);
            moving_slopes_sand(j + floor(window_size/2)) = p_mov_sand(1); 
        end
        
        valid_window_mud = intersect(window_indices, find(valid_indices_mud));
        if length(valid_window_mud) > 1
            p_mov_mud = polyfit(x_mean(valid_window_mud), mean_mud(valid_window_mud), 1);
            moving_slopes_mud(j + floor(window_size/2)) = p_mov_mud(1);
        end
    end
    
    % Sand Moving Slopes
    subplot(3,2,5); hold on;
    plot(x_mean, moving_slopes_sand, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', sea_level_rise_labels{i});
    % Mud Moving Slopes
    subplot(3,2,6); hold on;
    plot(x_mean, moving_slopes_mud, 'Color', colors{i}, 'LineWidth', 2, 'DisplayName', sea_level_rise_labels{i});
    
end

%% --- Final Formatting  ---
font_name = 'Helvetica';      
tick_font_size = 7;
label_font_size = 8;
title_font_size = 10;
legend_font_size = 7;
subplot_labels = {'a', 'b', 'c', 'd', 'e', 'f'};

for k = 1:6
    subplot(3, 2, k);
    
    % --- Common Formatting ---
    set(gca, 'FontName', font_name, 'FontSize', tick_font_size);
    box on;
    grid on;
    
    % Add panel labels (a, b, c...)
    text(-0.15, 1.05, subplot_labels{k}, 'Units', 'Normalized', ...
        'FontSize', title_font_size + 2, 'FontWeight', 'bold', 'FontName', font_name);
    
    % --- Specific Formatting per Subplot ---
    switch k
        case 1
            title('Sand Retention', 'FontSize', title_font_size);
            ylabel('Retention Fraction', 'FontSize', label_font_size);
            xlabel('T*', 'FontSize', label_font_size);
            ylim([0.3 1]); 
        case 2
            title('Mud Retention', 'FontSize', title_font_size);
            ylabel('Retention Fraction', 'FontSize', label_font_size);
            xlabel('T*', 'FontSize', label_font_size);
            lgd = legend(sea_level_rise_labels, 'Location', 'southeast');
        case 3
            title('Sand: Segmented Slope', 'FontSize', title_font_size);
            ylabel('Slope', 'FontSize', label_font_size);
            xlabel('Segment Index', 'FontSize', label_font_size);
            set(gca, 'XTick', 1:num_segments);
            xlim([0.5, num_segments+0.5]);
        case 4
            title('Mud: Segmented Slope', 'FontSize', title_font_size);
            ylabel('Slope', 'FontSize', label_font_size);
            xlabel('Segment Index', 'FontSize', label_font_size);
            set(gca, 'XTick', 1:num_segments);
            xlim([0.5, num_segments+0.5]);
            lgd = legend(sea_level_rise_labels, 'Location', 'northeast');
        case 5
            title('Sand: Moving Slope', 'FontSize', title_font_size);
            ylabel('Slope (d/dT*)', 'FontSize', label_font_size);
            xlabel('T*', 'FontSize', label_font_size);
            lgd = legend(sea_level_rise_labels, 'Location', 'northeast');
        case 6
            title('Mud: Moving Slope', 'FontSize', title_font_size);
            ylabel('Slope (d/dT*)', 'FontSize', label_font_size);
            xlabel('T*', 'FontSize', label_font_size);
            lgd = legend(sea_level_rise_labels, 'Location', 'northeast');
    end
    
    % Legend adjustment
    if exist('lgd', 'var') && isvalid(lgd)
        lgd.FontSize = legend_font_size;
        lgd.Box = 'off'; 
    end
    clear lgd; 
end

%% --- Background Shading ---
bgColor1 = [0.9 0.9 0.9]; % Light Gray
bgColor2 = [0.95 0.95 0.85]; % Light Beige

% Add background to Subplot a (Sand)
subplot(3, 2, 1);
yl = get(gca, 'YLim');
for j = 1:num_segments
    if mod(j, 2) == 1 
        color = bgColor1;
    else 
        color = bgColor2;
    end
    h = patch([edges(j) edges(j+1) edges(j+1) edges(j)], [yl(1) yl(1) yl(2) yl(2)], color, 'EdgeColor', 'none');
    uistack(h, 'bottom'); 
end

% Add background to Subplot b (Mud)
subplot(3, 2, 2);
yl = get(gca, 'YLim'); 
for j = 1:num_segments
    if mod(j, 2) == 1 
        color = bgColor1;
    else 
        color = bgColor2;
    end
    h = patch([edges(j) edges(j+1) edges(j+1) edges(j)], [yl(1) yl(1) yl(2) yl(2)], color, 'EdgeColor', 'none');
    uistack(h, 'bottom');
end