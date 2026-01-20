%% 1. Data Loading and Preparation
clear; clc;

% List of files to process
file_list = ["R30.mat", "R31.mat", "R32.mat", "R29.mat"];

% Initialize arrays for data accumulation
X_partial = []; % Time steps: 80 to End (Delta Area)
Y_partial = []; % Time steps: 80 to End (Wet Fraction)

X_full = [];    % Time steps: 1 to End (Delta Area)
Y_full = [];    % Time steps: 1 to End (Wet Fraction)

% Loop through each file
for i = 1:length(file_list)
    fprintf('Loading %s ...\n', file_list(i));
    load(file_list(i));
    
    % --- Dataset 1: Partial Time Steps (80:end) ---
    temp_area_80 = log.delta_area(80:end, :);
    temp_wet_80  = log.wetfrac(80:end, :);
    
    % Flatten and append
    X_partial = [X_partial; temp_area_80(:)];
    Y_partial = [Y_partial; temp_wet_80(:)];
    
    % --- Dataset 2: Full Time Steps (1:end) ---
    temp_area_all = log.delta_area(1:end, :);
    temp_wet_all  = log.wetfrac(1:end, :);
    
    % Flatten and append
    X_full = [X_full; temp_area_all(:)];
    Y_full = [Y_full; temp_wet_all(:)];
end

%% 2. Visualization (Side-by-Side Comparison)
% Set figure size for side-by-side plots (Width > Height)
figure('Units', 'inches', 'Position', [1, 1, 10, 5]);

% --- Left Panel: Partial Data (80:end) ---
subplot(1, 2, 1);
% Scatter plot: Black color ('k'), Transparency used for density
scatter(X_partial, Y_partial, 15, 'k', 'filled', 'MarkerFaceAlpha', 0.2);

% Formatting (English Captions)
title('Time steps: 80 to End', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Delta Area [m^2]', 'FontSize', 11);
ylabel('Wet Fraction', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 10, 'LineWidth', 1, 'TickDir', 'out');
xlim([min(X_full) max(X_full)]); % Set consistent x-axis range
ylim([0 1]);

% --- Right Panel: Full Data (1:end) ---
subplot(1, 2, 2);
% Scatter plot: Black color ('k'), Transparency used for density
scatter(X_full, Y_full, 15, 'k', 'filled', 'MarkerFaceAlpha', 0.2);

% Formatting (English Captions)
title('Time steps: 1 to End', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Delta Area [m^2]', 'FontSize', 11);
ylabel('Wet Fraction', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 10, 'LineWidth', 1, 'TickDir', 'out');
xlim([min(X_full) max(X_full)]); % Set consistent x-axis range
ylim([0 1]);
