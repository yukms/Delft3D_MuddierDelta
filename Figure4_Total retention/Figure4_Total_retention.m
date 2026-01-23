%% 1. Basic Setup and Model Data Loading
COH_settlevel = 0.25/10/100; % mm/s -> m/s
total = 0.3; 
MORFAC = 100;
Qw = 1000;

figure_width = 18.3;  
figure_height = 10;   

fig = figure('Units', 'centimeters', 'Position', [0, 2, figure_width, figure_height]);
set(fig, 'DefaultAxesFontName', 'Helvetica', 'DefaultTextFontName', 'Helvetica');
hold on;

% Color Definitions
color_model = [0.25, 0.45, 0.75]; 
color_field = [0.2, 0.2, 0.2];   
color_fit = [0.85, 0.3, 0.3];    

% === Model Data Plotting ===
model_indices = 29; 
is_first_plot = true; 

for i = model_indices
    filename = sprintf('R%d.mat', i);
    if exist(filename, 'file')
        load(filename);
        cum_total_input = cumsum(log.qs_mud_input) + cumsum(log.qs_sand_input);
        
        p = plot(MORFAC * log.delta_area(81:end,:) * COH_settlevel / (Qw * total / 2650), ...
             (log.volume_mud_delta(81:end,:) + log.volume_sand_delta(81:end,:)) ./ (cum_total_input(80:end,:)), ...
             'Color', color_model, 'LineWidth', 1.5);
         
        if is_first_plot
            set(p, 'DisplayName', 'Model');
            is_first_plot = false;
        else
            set(p, 'HandleVisibility', 'off');
        end
    end
end

%% 2. Field Data Loading (Modified to read Names)
[fielding, ~, raw] = xlsread('FieldDelta.xlsx'); 

if size(raw, 1) > size(fielding, 1)
    delta_names = raw(2:end, 2); % 
else
    delta_names = raw(:, 2);
end

dataselec = 13; 
x = fielding(:,3) * 1000 * 1000 * 0.00034 ./ (fielding(:,9) / 2650);
y = fielding(:,dataselec);

left_range = x - (fielding(:,3) * 1000 * 1000 * 0.00017 ./ (fielding(:,9) / 2650));
right_range = (fielding(:,3) * 1000 * 1000 * 0.0007 ./ (fielding(:,9) / 2650)) - x;

% errorbar
errorbar(x, y, left_range, right_range, 'horizontal', ...
    'o', 'MarkerFaceColor', color_field, 'MarkerEdgeColor', 'none', ...
    'Color', color_field, 'LineWidth', 1.2, 'CapSize', 0, 'MarkerSize', 6, ...
    'DisplayName', 'Field observations');

% delta name (offset)
for k = 1:length(x)
    if ~isnan(x(k)) && ~isnan(y(k))
        text(x(k) * 1.05, y(k) + 0.015, delta_names{k}, ...
            'FontSize', 8, 'Color', [0.3 0.3 0.3], ...
            'FontName', 'Helvetica', 'Interpreter', 'none', ...
            'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom');
    end
end

%% 3. Logarithmic Fitting
valid_idx = ~isnan(x) & ~isnan(y) & (x > 0);
x_clean = x(valid_idx);
y_clean = y(valid_idx);

p = polyfit(log10(x_clean), y_clean, 1); 
a = p(1);
b = p(2);

xfit = logspace(log10(min(x_clean)*0.8), log10(max(x_clean)*1.2), 200)';
yfit = a * log10(xfit) + b; 
[R, P] = corr(log10(x_clean), y_clean);

%% 4. Graph Aesthetics and Text Output
plot(xfit, yfit, '-', 'Color', color_fit, 'LineWidth', 2.5, 'DisplayName', 'Log-fit'); 

stats_str = {sprintf('{\\it y} = %.2f log_{10}({\\it x}) %+.2f', a, b), ...
             sprintf('{\\it r} = %.2f, {\\it p} = %.3f', R, P)};
         
text(0.05, 0.9, stats_str, 'Units', 'normalized', ...
    'FontSize', 10, 'Color', color_fit, 'FontName', 'Helvetica', ...
    'VerticalAlignment', 'top'); 

set(gca, 'XScale', 'log', 'FontSize', 11, 'LineWidth', 1.2, 'TickDir', 'in');

grid on;
set(gca, 'GridColor', [0.6, 0.6, 0.6], 'GridAlpha', 0.5);
box on;
ylim([0 1.0]); 
xlim([8e3, 3e7]); 

xlabel('Normalized delta area, {\it A}^*', 'FontSize', 12);
ylabel('Total sediment retention, {\it f}_R', 'FontSize', 12);

hLegend = legend('Location', 'southeast');
set(hLegend, 'Box', 'off', 'FontSize', 10);
