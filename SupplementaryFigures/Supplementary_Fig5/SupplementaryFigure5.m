%% Sensitivity Analysis
load('logdata.mat')

%% 0. Calculate Analysis Start Point for Each Experiment
% -------------------------------------------------------------------------
% Find the index where 'wetfrac' reaches its maximum value to set
% the dynamic start point for analysis.
disp('0. Calculating analysis start points (based on wetfrac)...');
try
    if isfield(log, 'wetfrac') && ~isempty(log.wetfrac)
        num_cols = size(log.wetfrac, 2);
        [~, max_indices] = max(log.wetfrac(:, 1:num_cols));
        disp('Calculation complete. Start indices (max_indices):');
        disp(max_indices);
    else
        error('Field "log.wetfrac" is empty or does not exist.');
    end
catch ME
    disp('Error: Failed to calculate wetfrac indices. Check the message below.');
    disp(ME.message);
    return; % Stop execution on error
end

%% 1. Extract Parameters for All Experiments
% -------------------------------------------------------------------------
% Extract experiment conditions (settlevel, Qw, total) from folder names.
disp('1. Extracting parameters from folder names...');
num_experiments = length(log.folders);
params = []; % Structure array to store valid experiments
for i = 1:num_experiments
    folder_info = log.folders{i};
    token_settle = regexp(folder_info, 'settlevel(\d+\.?\d*)', 'tokens');
    token_qw = regexp(folder_info, 'Qw(\d+\.?\d*)', 'tokens');
    token_total = regexp(folder_info, 'total(\d+\.?\d*)', 'tokens');
    
    if isempty(token_settle) || isempty(token_qw) || isempty(token_total)
        warning('Skipping experiment "%s": Unable to find all parameters.', folder_info);
        continue;
    end
    
    % Store valid experiment info
    params(end+1).settlevel = str2double(token_settle{1}{1});
    params(end).Qw = str2double(token_qw{1}{1});
    params(end).total = str2double(token_total{1}{1});
    params(end).index = i; % Original index in log data
end
disp('Parameter extraction complete.');

%% 2. Prepare Combined Data (Single Loop)
% -------------------------------------------------------------------------
% Prepare data for all analyses (combined, grouped, multi-regression) in one loop.
disp('2. Preparing data for analysis...');

% Variables for Combined Analysis
all_Tstar = [];
all_R_total = [];

% Variables for Grouped Analysis
Tstar_per_exp = cell(1, length(params));
R_total_per_exp = cell(1, length(params));
legend_names = cell(1, length(params));

% Variables for Multi-Regression Analysis
all_delta_area_multi = [];
all_R_total_multi = [];
all_ws_multi = [];
all_Qw_multi = [];
all_C_multi = [];

for i = 1:length(params)
    p = params(i);
    w_s = p.settlevel;
    
    % Apply dynamic start index from Step 0
    start_idx_R = max_indices(p.index); 
    start_idx_T = start_idx_R + 1;
    
    % Check data boundaries
    if start_idx_T > size(log.delta_area, 1)
        warning('Experiment %d: Calculated start index (%d) exceeds data range. Skipping.', p.index, start_idx_R);
        Tstar_vector = [];
        R_total_vector = [];
        delta_area_vector = [];
    else
        Tstar_vector = log.delta_area(start_idx_T:end, p.index) * w_s ./ (p.total * p.Qw);
        
        % <<< Use delta_retention_total instead of r_mud + r_sand >>>
        R_total_vector = log.delta_retention_total(start_idx_R:end, p.index);
        
        delta_area_vector = log.delta_area(start_idx_T:end, p.index); % For multi-regression
    end
    
    % [Filter] Select data where delta_area < 16e7
    % 1. Find indices meeting the condition
    delta_area_filter = delta_area_vector < 16e7;
    
    % 2. Apply filter to vectors
    delta_area_vector = delta_area_vector(delta_area_filter);
    Tstar_vector = Tstar_vector(delta_area_filter);
    
    % Adjust R_total_vector length to match Tstar (if needed)
    if length(R_total_vector) == length(delta_area_filter) + 1
        R_total_vector = R_total_vector(2:end); % Align start point with Tstar
    end
    
    % Apply filter to R_total
    R_total_vector = R_total_vector(delta_area_filter);
    
    % Filter valid data (exclude 0, NaN, Inf)
    valid_idx = Tstar_vector > 0 & R_total_vector > 0 & isfinite(Tstar_vector) & isfinite(R_total_vector);
    
    % 1. Store Grouped Data
    Tstar_per_exp{i} = Tstar_vector(valid_idx);
    R_total_per_exp{i} = R_total_vector(valid_idx);
    legend_names{i} = sprintf('w_s=%.2f, Q_w=%d, C=%.1f', p.settlevel, p.Qw, p.total);
    
    % 2. Accumulate Combined Data
    all_Tstar = [all_Tstar; Tstar_per_exp{i}];
    all_R_total = [all_R_total; R_total_per_exp{i}];
    
    % 3. Accumulate Multi-Regression Data
    final_delta_area_vector = delta_area_vector(valid_idx);
    num_valid_points = length(final_delta_area_vector);
    
    all_delta_area_multi = [all_delta_area_multi; final_delta_area_vector];
    all_R_total_multi = [all_R_total_multi; R_total_per_exp{i}];
    all_ws_multi = [all_ws_multi; repmat(p.settlevel, num_valid_points, 1)];
    all_Qw_multi = [all_Qw_multi; repmat(p.Qw, num_valid_points, 1)];
    all_C_multi = [all_C_multi; repmat(p.total, num_valid_points, 1)];
end
disp('Data preparation complete.');

%% 3. Combined Regression Analysis and Plotting
% -------------------------------------------------------------------------
% Fit a single Power-Law model to all experiment data and visualize.
disp('3. Generating combined regression plot...');

if length(all_Tstar) > 1
    % Log transformation for power-law fit
    log_Tstar_all = log10(all_Tstar);
    log_R_total_all = log10(all_R_total);
    
    % Linear fit in log-log space
    p_fit_all = polyfit(log_Tstar_all, log_R_total_all, 1);
    b = p_fit_all(1); 
    a = 10^p_fit_all(2);
    
    % Calculate R-squared
    y_fit_all = polyval(p_fit_all, log_Tstar_all);
    r_squared_all = 1 - sum((log_R_total_all - y_fit_all).^2) / sum((log_R_total_all - mean(log_R_total_all)).^2);
    
    % Create Figure
    fig1 = figure('Name', 'Combined Log-Log Plot with Power-Law Fit', 'Color', 'w');
    hold on; grid on;
    
    % --- Plot each group with unique lines ---
    colors = lines(length(Tstar_per_exp)); % Use default colormap
    line_styles = {'-', '--', ':', '-.'}; % Cycle through 4 styles
    
    for i = 1:length(Tstar_per_exp)
        if ~isempty(Tstar_per_exp{i})
            % Sort for clean line plotting
            [sorted_Tstar, sort_idx] = sort(Tstar_per_exp{i});
            sorted_R_total = R_total_per_exp{i}(sort_idx);
            
            % Determine color and style
            current_color = colors(i, :);
            current_style = line_styles{mod(i-1, length(line_styles)) + 1};
            
            loglog(sorted_Tstar, sorted_R_total, ...
                   'Color', current_color, ...
                   'LineStyle', current_style, ...
                   'LineWidth', 1.5, ...
                   'DisplayName', legend_names{i});
        end
    end
    
    % Plot Overall Regression Line
    log_Tstar_fit_range = linspace(min(log_Tstar_all), max(log_Tstar_all), 100);
    log_R_total_fit_line = polyval(p_fit_all, log_Tstar_fit_range);
    
    plot(10.^log_Tstar_fit_range, 10.^log_R_total_fit_line, 'r-', ...
        'LineWidth', 2.5, 'DisplayName', 'Overall Power-Law Fit');
    
    % Axis Settings
    set(gca, 'XScale', 'log', 'YScale', 'log', 'FontSize', 12, 'TickDir', 'out', 'Box', 'on');
    title('Combined Power-Law Regression Analysis');
    xlabel('Normalized Delta Area (T*)'); 
    ylabel('Total Sediment Retention');
    
    % Legend
    legend('show', 'Location', 'southeast', 'NumColumns', 2, 'FontSize', 8, 'Box', 'off');
    
    % Add Equation and R-squared Text
    equation_text = sprintf('Retention = %.2e \\cdot (T*)^{%.2f}', a, b);
    rsquared_text = sprintf('Overall R^2 = %.4f', r_squared_all);
    
    text(0.05, 0.95, {equation_text, rsquared_text}, 'Units', 'normalized', ...
         'VerticalAlignment', 'top', 'BackgroundColor', 'none', 'EdgeColor', 'none', ...
         'FontSize', 10, 'FontWeight', 'bold');
     
    hold off;
    disp('Combined plot generation complete.');
else
    disp('Not enough valid data for combined regression analysis.');
end