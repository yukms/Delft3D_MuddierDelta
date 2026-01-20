%% Field Data (excel) 
COH_settlevel=0.25/10/100 ; % mm/s -> m/s
total=0.3; 
MORFAC=100;
Qw=1000;
% normalization  :   Area_delta [m2]  settling [m/s]  /   Qs [m3/s]

% Normalized model data
figure('Units', 'centimeters', 'Position', [0, 2, 12, 10]); 
hold on
colors = {'r', 'g', 'b', 'k'};
for i = 29 %: 32
    filename = sprintf('R%d.mat', i);
    % Check if file exists to prevent errors
    if exist(filename, 'file')
        load(filename);
        cum_total_input = cumsum(log.qs_mud_input) + cumsum(log.qs_sand_input);
        plot (MORFAC*log.delta_area(81:end,:)*COH_settlevel/(Qw*total/2650), (log.volume_mud_delta(81:end,:)+log.volume_sand_delta(81:end,:)) ./ (cum_total_input(80:end,:)) ,'color',colors{i-28})
    end
end
% Initial labels (will be overwritten below, but kept for consistency)
xlabel('Normalized Delta Area (T*)','FontSize',16); 
ylabel('Total Sediment Retention','FontSize',16)
set(gca,'FontSize',14)

% Load Field Data
fielding=xlsread('FieldDelta.xlsx'); % Col 3: area, Col 12: retention (flux), Col 13: retention (budget)

% Normalize field data
field_area = fielding(:,3)*1000*1000*0.00034./(fielding(:,9)/2650);

dataselec  = 13; % Select budget retention
field_retention = fielding(:,dataselec);

%% Error bar
% Prepare data
x = fielding(:,3)*1000*1000 *0.00034./(fielding(:,9)/2650);
y = fielding(:,dataselec);
left_range = fielding(:,3)*1000*1000* 0.00034./(fielding(:,9)/2650) - fielding(:,3)*1000*1000* 0.00017./(fielding(:,9)/2650);
right_range = fielding(:,3)*1000*1000* 0.0007./(fielding(:,9)/2650)-fielding(:,3)*1000*1000* 0.00034./(fielding(:,9)/2650);

% Plot error bars
errorbar(x, y, left_range, right_range, 'horizontal', 'o');

% Figure decoration
xlabel('Normalized Delta Area (T*)'); % Changed from 'X'
ylabel('Sediment Retention');         % Changed from 'Y'
grid on;
ylim([0 1])

%% Linear fitting
% Remove NaN and values <= 0 (required for power-law fit)
valid_idx = ~isnan(x) & ~isnan(y) & (x > 0) & (y > 0);
x = x(valid_idx);
y = y(valid_idx);

% Log transformation
logx = log10(x);
logy = log10(y);

% === 1. Log-log linear regression (Power-law fit) ===
[p, ~] = polyfit(logx, logy, 1);  % log10(y) = b*log10(x) + log10(a)
b = p(1);
a = 10^p(2);

% Generate fit line
xfit = linspace(min(x), max(x), 200)';
yfit = a * xfit.^b;

% === 2. Correlation and Significance ===
[R, P] = corr(logx, logy);  % Pearson r and p-value

% === 3. Plotting ===
% Plot trend line
plot(xfit, yfit, 'r-', 'LineWidth', 2);

% Display r and p values
text(0.05, 0.95, sprintf('r = %.2f, p = %.3f', R, P), ...
    'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold');

% Final labeling
xlabel('Normalized Delta Area (T*)'); 
ylabel('Sediment Retention');
grid on;
set(gca, 'FontSize', 12);