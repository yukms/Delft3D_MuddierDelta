% =========================================================================
% 1. Load Data and Convert to Single Column Vector
% =========================================================================
All_r_total_delta = []; 
file_numbers = 29:32;
for i = 1:length(file_numbers)
    filename = sprintf('R%d.mat', file_numbers(i));
    if exist(filename, 'file')
        load(filename);
        temp_data = log.r_total_delta(80:end, :);
        All_r_total_delta = [All_r_total_delta; temp_data];
    end
end
All_r_total_delta = All_r_total_delta(:); % Convert to 16000x1 vector
clear i file_numbers filename log temp_data;

% =========================================================================
% 2. Calculate Statistics
% =========================================================================
% Calculate Mean and Standard Deviation
data_mean = mean(All_r_total_delta);
data_std = std(All_r_total_delta);

% Print to Command Window
fprintf('--- Data Statistics ---\n');
fprintf('Mean: %.4f\n', data_mean);
fprintf('Standard Deviation: %.4f\n', data_std);
fprintf('-----------------------\n');

% =========================================================================
% 3. Generate Histogram and Add Text
% =========================================================================
% --- Figure 1: Histogram + Mean/Std ---
figure; 
% Draw Histogram
histogram(All_r_total_delta, 'Normalization', 'pdf');
title('Total Sediment Retention Distribution');
xlabel('Total Sediment Retention');
ylabel('Probability Density');
grid on;
hold on; 

% Draw Vertical Line for Mean (Red)
xline(data_mean, 'r-', 'Mean', 'LineWidth', 2, 'LabelVerticalAlignment', 'bottom');

% Draw Vertical Lines for Mean ± 1 Std Dev (Blue Dashed)
xline(data_mean - data_std, 'b--', 'Mean - 1 \sigma', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'top');
xline(data_mean + data_std, 'b--', 'Mean + 1 \sigma', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'top');

% Add Legend
legend('Data', 'Mean', 'Mean \pm 1 \sigma', 'Location', 'best'); 

% --- Add Statistics as Text Box ---
% Create text string
text_str = sprintf('Mean = %.4f\n\\sigma = %.4f', data_mean, data_std);

% Determine text position automatically
ax_limits = axis; % [xmin xmax ymin ymax]
x_pos = ax_limits(1) + (ax_limits(2) - ax_limits(1)) * 0.05; % 5% from left
y_pos = ax_limits(4) * 0.9; % 90% from bottom

% Add Text
text(x_pos, y_pos, text_str, 'FontSize', 10, 'EdgeColor', 'k', 'BackgroundColor', 'w');

hold off;