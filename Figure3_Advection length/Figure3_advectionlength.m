% run Figure3_deltaradius first.

%% 0. Setup Datasets
% Define dataset names to process
dataset_names = {'advection100', 'advection200', 'advection300'};

% --- Data storage for CDF plots ---
% results(1) = 100, results(2) = 200, results(3) = 300
results = struct('sandchannel', [], 'sandnonchannel', [], 'mudchannel', [], 'mudnonchannel', []);

% Loop through each dataset
for d = 1:length(dataset_names)
    current_dataset_name = dataset_names{d};
    fprintf('===== Processing dataset: %s =====\n', current_dataset_name);
    
    %% 1. Data load 
    foldername = ["/Users/minsik/Desktop/Muddier delta figure/Advection_length/Run_29",...
        "/Users/minsik/Desktop/Muddier delta figure/Advection_length/Run_30",...
        "/Users/minsik/Desktop/Muddier delta figure/Advection_length/Run_31",...
        "/Users/minsik/Desktop/Muddier delta figure/Advection_length/Run_32"];
    % foldername = ["X:\Delft3D\Run_29"];
    
    % --- Velocity Data ---
    all_all_channel_vel = cell(1, length(foldername)); % Initialize cell array
    all_all_land_vel = cell(1, length(foldername));
    for j = 1:length(foldername)
        cd(foldername(j));
        vel_data_struct = load('advectionlength2.mat'); 
        current_vel_data = vel_data_struct.(current_dataset_name); 
        
        channel_vel = []; land_vel = [];
        for i = 1:16
            channel_vel(i, :) = current_vel_data(i).channel_velocity(:);
            land_vel(i, :) = current_vel_data(i).land_velocity(:);
        end
        all_all_channel_vel{j} = channel_vel(:);
        all_all_land_vel{j} = land_vel(:);
    end
    merged_channel_vel = []; merged_land_vel =[];
    for k = 1:length(all_all_channel_vel)
        merged_channel_vel = [merged_channel_vel; all_all_channel_vel{k}(:)];
        merged_land_vel = [merged_land_vel; all_all_land_vel{k}(:)];
    end
    data1=merged_channel_vel(:);
    data2= merged_land_vel(:);
    
    % --- Water Depth Data ---
    all_all_channel_depth = cell(1, length(foldername)); % Initialize cell array
    all_all_land_depth = cell(1, length(foldername));
    for j = 1:length(foldername)
        cd(foldername(j));
        depth_data_struct = load('advectionlength.mat');
        current_depth_data = depth_data_struct.(current_dataset_name);
        
        channel_depth = []; land_depth = [];
        for i = 1:16
            channel_depth(i, :) = current_depth_data(i).channel_depth(:);
            land_depth(i, :) = current_depth_data(i).land_depth(:);
        end
        all_all_channel_depth{j} = channel_depth(:);
        all_all_land_depth{j} = land_depth(:);
    end
    merged_channel_depth = []; merged_land_depth =[];
    for k = 1:length(all_all_channel_depth)
        merged_channel_depth = [merged_channel_depth; all_all_channel_depth{k}(:)];
        merged_land_depth = [merged_land_depth; all_all_land_depth{k}(:)];
    end
    data3=merged_channel_depth(:);
    data4= merged_land_depth(:);
    
    %% 2. Calculate Advection Length (Using original data)
    ws_sand=0.0262537; % Sand settling velocity (m/s)
    ws_mud=0.00025;   % Mud settling velocity (m/s)
    
    sandchannel=data1.*data3 ./ ws_sand;
    mudnonchannel=data2.*data4 ./ ws_mud;
    mudchannel = data1.*data3 ./ ws_mud;
    sandnonchannel=data2.*data4 ./ws_sand;
    
    % --- Remove zeros from results and store for CDF plotting ---
    sandchannel(sandchannel == 0) = [];
    mudnonchannel(mudnonchannel == 0) = [];
    mudchannel(mudchannel ==0)=[];
    sandnonchannel(sandnonchannel==0)=[];
    
    % --- Store results ---
    results(d).sandchannel = sandchannel;
    results(d).sandnonchannel = sandnonchannel;
    results(d).mudchannel = mudchannel;
    results(d).mudnonchannel = mudnonchannel;
    
    %% 3. Final Plot 1: Velocity and Depth Histograms (Create separate figure)
    % (Create one figure per loop iteration)
    data1_hist = data1(data1~=0);
    data2_hist = data2(data2~=0);
    data3_hist = data3(data3~=0);
    data4_hist = data4(data4~=0);
    
    fontname = 'Arial';
    xlabel_fontsize = 10;
    ylabel_fontsize = 10;
    tick_fontsize = 8;
    f = figure('Name', ['Histograms: ' current_dataset_name], 'Units','centimeter','Position',[1 1 8.5 9], 'Renderer', 'painters');
    
    % --- Subplot 1: Flow Velocity ---
    subplot(2,1,1);
    % (Skip histogram plotting if data is empty)
    if ~isempty(data1_hist) || ~isempty(data2_hist)
        edges_vel = linspace(min([data1_hist; data2_hist]), max([data1_hist; data2_hist]), 60); 
        [counts1_vel, ~] = histcounts(data1_hist, edges_vel, 'Normalization', 'pdf');
        [counts2_vel, ~] = histcounts(data2_hist, edges_vel, 'Normalization', 'pdf');
        counts1_vel = counts1_vel / max(counts1_vel);
        counts2_vel = counts2_vel / max(counts2_vel);
        binCenters_vel = edges_vel(1:end-1) + diff(edges_vel)/2;
        bar(binCenters_vel, counts1_vel, 'FaceAlpha', 0.3, 'FaceColor', [0.2 0.4 1], 'EdgeColor', 'none'); hold on;
        bar(binCenters_vel, counts2_vel, 'FaceAlpha', 0.3, 'FaceColor', [1 0.4 0.4], 'EdgeColor', 'none'); hold off;
        xlabel('Flow Velocity [m/s]', 'FontSize', xlabel_fontsize, 'FontName', fontname);
        ylabel('Normalized Density (0–1)', 'FontSize', ylabel_fontsize, 'FontName', fontname);
        title(['Normalized Flow Velocity (' current_dataset_name ')'], 'FontName', fontname);
        legend('Channel', 'Delta plain', 'FontName', fontname);
        ylim([0 1]);
        set(gca, 'FontSize', tick_fontsize, 'FontName', fontname);
    end
    
    % --- Subplot 2: Flow Depth ---
    subplot(2,1,2);
    % (Skip histogram plotting if data is empty)
    if ~isempty(data3_hist) || ~isempty(data4_hist)
        edges_dep = linspace(min([data3_hist; data4_hist]), max([data3_hist; data4_hist]), 60);
        [counts1_dep, ~] = histcounts(data3_hist, edges_dep, 'Normalization', 'pdf');
        [counts2_dep, ~] = histcounts(data4_hist, edges_dep, 'Normalization', 'pdf');
        counts1_dep = counts1_dep / max(counts1_dep);
        counts2_dep = counts2_dep / max(counts2_dep);
        binCenters_dep = edges_dep(1:end-1) + diff(edges_dep)/2;
        bar(binCenters_dep, counts1_dep, 'FaceAlpha', 0.3, 'FaceColor', [0.2 0.4 1], 'EdgeColor', 'none'); hold on;
        bar(binCenters_dep, counts2_dep, 'FaceAlpha', 0.3, 'FaceColor', [1 0.4 0.4], 'EdgeColor', 'none'); hold off;
        xlabel('Flow Depth [m]', 'FontSize', xlabel_fontsize, 'FontName', fontname);
        ylabel('Normalized Density (0–1)', 'FontSize', ylabel_fontsize, 'FontName', fontname);
        title(['Normalized Flow Depth (' current_dataset_name ')'], 'FontName', fontname);
        legend('Channel', 'Delta plain', 'FontName', fontname);
        ylim([0 1]);
        set(gca, 'FontSize', tick_fontsize, 'FontName', fontname);
    end
end % (End of dataset_names loop)
fprintf('===== All datasets processed. Now creating combined CDF plot... =====\n');

%% 4. Final Plot 2: Combined Advection Length CDF (12 curves)
% (This section runs *outside* the loop)

% --- Define plot styles ---
% Data type (Sand C, Sand NC, Mud C, Mud NC) = Color
type_colors = {[0.2 0.4 1], [1 0.4 0.4], [0.2 1 0.4], [0.6 0.2 0.6]};
type_groups = {'Sand Channel', 'Sand Nonchannel', 'Mud Channel', 'Mud Nonchannel'};

% Dataset (100, 200, 300) = Line style + Marker
dataset_styles = {'-', '-o', '-d'}; % 100=solid, 200=solid+(+), 300=solid+Diamond
dataset_names_short = {'100', '200', '300'};
fontname = 'Arial';

% --- Create full figure ---
figure('Name', 'Combined Advection Length CDF (All Datasets)', 'Units','centimeters','Position',[1 1 13 10]);
mainAx = axes('Position',[0.13 0.15 0.75 0.75]);
hold(mainAx, 'on');

% --- Plot 12 lines using nested loops ---
% d = dataset (100, 200, 300)
% i = type (Sand C, Sand NC, ...)
for d = 1:length(dataset_names)
    
    % Construct data cell for current dataset (d)
    data_cell = {results(d).sandchannel, results(d).sandnonchannel, results(d).mudchannel, results(d).mudnonchannel};
    
    for i = 1:length(data_cell)
        data = sort(data_cell{i});
        
        % Skip if data is empty
        if isempty(data)
            continue;
        end
        
        cdf = (1:length(data))' / length(data);
        
        % Generate legend name (e.g., "Sand Channel (100)")
        displayName = sprintf('%s (%s)', type_groups{i}, dataset_names_short{d});
        % Display marker every 20 points as data is dense
        marker_indices = 1:round(length(data)/20):length(data);
        
        % Plot:
        % - dataset_styles{d}: Line/Marker style (e.g., '-o')
        % - type_colors{i}: Line color
        plot(mainAx, data, cdf, ...
             dataset_styles{d}, ... 
             'Color', type_colors{i}, ...
             'LineWidth', 1.5, ...
             'MarkerSize', 7, ...
             'MarkerIndices', marker_indices, ... % Marker spacing
             'DisplayName', displayName);
    end
end

% 1. Group delta radius values to plot.
delta_radii_to_plot = [delta_radius_mean_100, delta_radius_mean_200, delta_radius_mean_300];
time_steps_for_label = [100, 200, 300];

% 2. Loop to draw xlines.
% Get Y-axis limits (determines vertical line height)
y_limits = ylim(mainAx); 
% Divide Y-axis into 100 segments to place markers on vertical lines.
y_vec = linspace(y_limits(1), y_limits(2), 100); 

hold(mainAx, 'on'); % Prevent overwriting
for k = 1:length(delta_radii_to_plot)
    radius_val = delta_radii_to_plot(k);
    time_val = time_steps_for_label(k);
    
    % 1. Select style (cycle based on k)
    style_idx = mod(k-1, length(dataset_styles)) + 1;
    current_style = dataset_styles{style_idx};
    
    % 2. Draw vertical line using plot (replaces xline)
    plot(mainAx, repmat(radius_val, size(y_vec)), y_vec, ...
         current_style, ... % Applies '-o', etc.
         'Color', 'k', ...
         'LineWidth', 0.5, ...
         'MarkerSize', 7, ...
         'MarkerIndices', 1:10:length(y_vec), ... % Marker every 10 points
         'HandleVisibility', 'off'); % Exclude from legend
         
    % 3. Add text label (replaces Label)
    text(mainAx, radius_val, y_limits(2), ...
         sprintf('Mean \\delta radius (t=%d)', time_val), ...
         'FontSize', 8, ...
         'FontName', fontname, ...
         'VerticalAlignment', 'top', ...      % Align to top of axis
         'HorizontalAlignment', 'left', ...   % Text to right of line
         'BackgroundColor', 'none');          % Transparent background
end

% --- Finalize graph style ---
set(mainAx, 'XScale', 'log');
xlabel(mainAx, 'Advection Length [m]', ...
       'FontSize', 10, 'FontName', fontname);
ylabel(mainAx, 'Cumulative Probability', ...
       'FontSize', 10, 'FontName', fontname);
title(mainAx, 'Advection Length CDF (All Datasets)', ...
       'FontSize', 12, 'FontName', fontname);
       
% Axis font settings
set(mainAx, 'FontSize', 8, 'FontName', fontname);
% Legend (show 12 items)
legend(mainAx, 'Location', 'southeast', 'NumColumns', 2); % Legend in 2 columns
xlim([1e-1 1e5]);
grid(mainAx, 'on'); grid(mainAx, 'minor');
box(mainAx, 'on');

fprintf('===== Combined CDF plot created. =====\n');


%% 4. Final Plot 2: Combined Advection Length CDF (12 curves)
% Nature Geoscience Style Configuration

% Colorblind-friendly palette (Wong 2011, Nature Methods)
% Sand Channel - blue
% Sand Nonchannel - orange
% Mud Channel - green
% Mud Nonchannel - purple
type_colors = {
    [0, 114, 178]/255,    % Sand Channel
    [230, 159, 0]/255,    % Sand Nonchannel
    [0, 158, 115]/255,    % Mud Channel
    [204, 121, 167]/255   % Mud Nonchannel
};
type_groups = {'Sand Channel', 'Sand Nonchannel', 'Mud Channel', 'Mud Nonchannel'};

% Line styles per dataset
dataset_styles = {'-', '--', ':'}; % 100=solid, 200=dashed, 300=dotted
dataset_names_short = {'100', '200', '300'};

% Nature Geoscience font settings
fontname = 'Arial';
title_fontsize = 7;
label_fontsize = 6;
tick_fontsize = 5;
legend_fontsize = 5;

% Figure Size: Double column width (183mm = 18.3cm)
fig_width = 18.3;  % cm
fig_height = 12;   % cm (considering aspect ratio)

% Line width
line_width = 1.0;
grid_line_width = 0.25;

% --- Create Figure (High-res settings) ---
fig = figure('Name', 'Combined Advection Length CDF (All Datasets)', ...
             'Units', 'centimeters', ...
             'Position', [2 2 fig_width fig_height], ...
             'Color', 'w', ...
             'PaperUnits', 'centimeters', ...
             'PaperSize', [fig_width fig_height], ...
             'PaperPosition', [0 0 fig_width fig_height], ...
             'Renderer', 'painters');

% Main axis setup (adjust margins)
mainAx = axes('Position', [0.10 0.12 0.65 0.82], ...
              'FontName', fontname, ...
              'FontSize', tick_fontsize, ...
              'LineWidth', 0.5, ...
              'TickDir', 'out', ...
              'Box', 'on');
hold(mainAx, 'on');

% --- Plot 12 lines (remove markers) ---
for d = 1:length(dataset_names)
    data_cell = {results(d).sandchannel, results(d).sandnonchannel, ...
                 results(d).mudchannel, results(d).mudnonchannel};
    
    for i = 1:length(data_cell)
        data = sort(data_cell{i});
        
        if isempty(data)
            continue;
        end
        
        cdf = (1:length(data))' / length(data);
        
        % Legend name
        displayName = sprintf('%s (%s)', type_groups{i}, dataset_names_short{d});
        
        % Plot (lines only, no markers)
        plot(mainAx, data, cdf, ...
             dataset_styles{d}, ...
             'Color', type_colors{i}, ...
             'LineWidth', line_width, ...
             'DisplayName', displayName);
    end
end

% --- Add vertical delta radius lines ---
delta_radii_to_plot = [delta_radius_mean_100, delta_radius_mean_200, delta_radius_mean_300];
time_steps_for_label = [100, 200, 300];
y_limits = [0 1]; % CDF is always 0-1
ylim(mainAx, y_limits);

for k = 1:length(delta_radii_to_plot)
    radius_val = delta_radii_to_plot(k);
    time_val = time_steps_for_label(k);
    
    % Draw vertical line
    plot(mainAx, [radius_val radius_val], y_limits, ...
         dataset_styles{k}, ...
         'Color', [0.3 0.3 0.3], ...
         'LineWidth', 0.75, ...
         'HandleVisibility', 'off');
    
    % Text label (smaller font)
    text(mainAx, radius_val, y_limits(2)*0.98, ...
         sprintf('\\itt\\rm=%d', time_val), ...
         'FontSize', legend_fontsize, ...
         'FontName', fontname, ...
         'VerticalAlignment', 'top', ...
         'HorizontalAlignment', 'left', ...
         'Rotation', 90, ...
         'BackgroundColor', 'none');
end

% --- Axis settings ---
set(mainAx, 'XScale', 'log');
xlabel(mainAx, 'Advection length (m)', ...
       'FontSize', label_fontsize, 'FontName', fontname, 'FontWeight', 'bold');
ylabel(mainAx, 'Cumulative probability', ...
       'FontSize', label_fontsize, 'FontName', fontname, 'FontWeight', 'bold');

% Remove title (Nature style usually has no title)
% Title is replaced by figure caption

% X-axis limits
xlim(mainAx, [1e-1 1e5]);

% Grid (thin lines)
grid(mainAx, 'on');
set(mainAx, 'GridLineStyle', '-', 'GridColor', [0.85 0.85 0.85], ...
            'GridAlpha', 1, 'LineWidth', grid_line_width);
set(mainAx, 'MinorGridLineStyle', ':', 'MinorGridColor', [0.9 0.9 0.9], ...
            'MinorGridAlpha', 1);

% --- Legend settings (place outside figure) ---
leg = legend(mainAx, 'Location', 'eastoutside', ...
             'FontSize', legend_fontsize, ...
             'FontName', fontname, ...
             'Box', 'off', ...
             'NumColumns', 1);

% Fine-tune legend position
leg.Position(1) = 0.77; % X position
leg.Position(2) = 0.20; % Y position

% --- Add panel label (optional) ---
annotation('textbox', [0.02 0.96 0.05 0.03], ...
           'String', 'a', ...
           'FontSize', 8, ...
           'FontName', fontname, ...
           'FontWeight', 'bold', ...
           'EdgeColor', 'none', ...
           'HorizontalAlignment', 'left', ...
           'VerticalAlignment', 'top');

% --- Save options ---
% High-res PNG (300 DPI)
% print(fig, 'advection_length_CDF_nature', '-dpng', '-r300');
% Vector format (PDF) - For publication
% print(fig, 'advection_length_CDF_nature', '-dpdf', '-painters');
% EPS format
% print(fig, 'advection_length_CDF_nature', '-depsc', '-painters');

fprintf('===== Nature Geoscience style CDF plot created. =====\n');
fprintf('To save in publication quality:\n');
fprintf('  PNG:  print(gcf, ''filename'', ''-dpng'', ''-r300'')\n');
fprintf('  PDF:  print(gcf, ''filename'', ''-dpdf'', ''-painters'')\n');
fprintf('  EPS:  print(gcf, ''filename'', ''-depsc'', ''-painters'')\n');