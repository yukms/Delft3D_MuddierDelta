%% Model data
COH_settlevel=0.25/10/100 ; % mm/s -> m/s   (16.7μm)
total=0.3; 
MORFAC=100;
Qw=1000;
D_mud = 17e-6;       % [m]
D_sand = 225e-6;     % [m]
rho_mud = 500;       % [kg/m3]
rho_sand = 1600;     % [kg/m3]



% normalized area vs mud proportion from model
load('R29.mat')
R = log.input_ratio;         % mud/sand mass ratio

% input D50 cal
V_ratio = R .* (rho_sand / rho_mud);
for i = 1:length(V_ratio)
D_avg_in(i) = estimate_D50_from_bedsus_ratio(1./V_ratio(i), 0.05, 10);
end

    
Tstarmax =max( MORFAC*log.delta_area(350,:)*COH_settlevel / (Qw*total/2650) );



figure
for t = 100:50:350
D_avg_dep = ( 17*log.volume_mud_delta(t,:) + 225*log.volume_sand_delta(t,:) )./ (log.volume_mud_delta(t,:)+log.volume_sand_delta(t,:));
Tstar = MORFAC*log.delta_area(t,:)*COH_settlevel /(Qw*total/2650);
scatter (D_avg_in*1e3, D_avg_dep ,Tstar/8000, 'ko')
hold on
end
xlabel('Input avg grain size [micro m]','FontSize',16); ylabel('Deposited avg grain size [micro m]','FontSize',16)
set(gca,'FontSize',14)

% xxx=10:70;
% yyy=10:70;
% hold on, plot(xxx,yyy,'r')

%% Syvitski and Saito 2007 Dataset  (Fielddata)

T= readmatrix('FieldSaito.xlsx');
% 8 grain size 10 bed/sus

ratio1=T(2:19,10);
AvgTopsetD_saito = T(2:19,8);  %% mm
T_saito =T(2:19,9);  % T*
T_saito_max = max(T_saito)

% comparing AvgTopsetD fron Syvitski and Satio and Rijn estimation for D50
for i = 1: length(ratio1)
D50_input_saito(i) = estimate_D50_from_bedsus_ratio( ratio1(i), 0.05, 10 ); %bed/sus ratio %
% fprintf('Estimated D50 = %.4f mm\n', D50);
end


% figure, plot( D50_input_saito', AvgTopsetD_saito,'ko')  % mm - mm
figure, scatter( D50_input_saito', AvgTopsetD_saito,T_saito/8000,'ro')  % mm - mm
xlabel('D50 from Rijn [mm]'); ylabel('Avg Topset D from Syvitski [mm]')

% % add 1:1 line
% minval = min([D50_input_saito', AvgTopsetD_saito]);
% maxval = max([D50_input_saito', AvgTopsetD_saito]);
% hold on,plot([minval maxval], [minval maxval], 'r', 'LineWidth', 0.5)  % mm -  mm

% add linear regression
p = polyfit(D50_input_saito', AvgTopsetD_saito, 1);           % [slope, intercept]
y_fit = polyval(p, D50_input_saito');
hold on,plot(D50_input_saito', y_fit, 'b-', 'LineWidth', 1)


%% model and field data together.
figure('Position', [100, 100, 1000, 1000]);

for t = 100:50:350
D_avg_dep = ( 17*log.volume_mud_delta(t,:) + 225*log.volume_sand_delta(t,:) )./ (log.volume_mud_delta(t,:)+log.volume_sand_delta(t,:));
Tstar = MORFAC*log.delta_area(t,:)*COH_settlevel /(Qw*total/2650);
scatter (D_avg_in*1e3, D_avg_dep ,Tstar/10000, 'ko')
hold on
end
xlabel('Input avg grain size [micro m]','FontSize',16); ylabel('Deposited avg grain size [micro m]','FontSize',16)
set(gca,'FontSize',14)

% hold on plot to Fig 10 failed.? %% D average input
% hold on, plot( 1000*D50_input_saito', 1000*AvgTopsetD_saito,'ro'); %[microm - microm]
hold on, scatter( 1000*D50_input_saito', 1000*AvgTopsetD_saito,T_saito/10000,'ro')  % mm - mm
for i = 1:length(D50_input_saito)
    x = 1000 * D50_input_saito(i);
    y = 1000 * AvgTopsetD_saito(i);
    text(x, y, sprintf('%d', i), 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'FontSize', 15)
end
% 이걸 Area대신 T*로 해봐?
xlim([0 400])
ylim([0 400])

% add 1:1 line

set(gca, 'XScale', 'log', 'YScale', 'log')
x = logspace(1, 3, 100);  % 10 to 1000 (micrometers)
plot(x, x, 'b', 'LineWidth', 0.5)

% 예시 버블 크기 설정 (T*의 예시 값)
Tstar_examples = [100e4 200e4 500e4, 1000e4, 2000e4];  % T* 값 (이건 예시이니 너의 데이터 범위에 맞게 조절해)
marker_sizes = Tstar_examples / 10000;  % scatter에서 사용한 scale로 변환

% 위치 설정 (plot의 오른쪽 위 등 적당한 위치에 놓기)
x_legend = 200;  % x좌표 고정
y_start = 350;   % y좌표 시작
dy = 30;         % y 간격

for i = 1:length(Tstar_examples)
    y_pos = y_start - (i-1)*dy;
    scatter(x_legend, y_pos, marker_sizes(i), 'k')
    text(x_legend + 15, y_pos, sprintf('T* = %.0e', Tstar_examples(i)), 'FontSize', 12, 'VerticalAlignment', 'middle')
end


%%
% Field data scatter with linear fit - Case 1: T* vs Deposited D
figure
subplot(1,3,1)
x1 = T_saito / 10000;
y1 = 1000 * AvgTopsetD_saito;

scatter(x1, y1, 'bo','filled'); hold on;

% 1차 회귀
p1 = polyfit(x1, y1, 1); % [slope, intercept]
yfit1 = polyval(p1, x1);
plot(x1, yfit1, 'k', 'LineWidth', 1.5)

% R^2 계산
R1 = corrcoef(x1, y1);
R_squared1 = R1(1,2)^2;

% % 회귀식 및 R² 출력
% eq1 = sprintf('y = %.2fx + %.2f, R^2 = %.2f', p1(1), p1(2), R_squared1);
% text(min(x1), max(y1), eq1, 'FontSize', 12, 'VerticalAlignment','top');

xlabel('T*'); ylabel('Deposited D [\mum]')
title('T* vs Deposited D')

% Field data scatter with linear fit - Case 2: input D vs Deposited D
subplot(1,3,2)
x2 = 1000 * D50_input_saito';
y2 = 1000 * AvgTopsetD_saito;

scatter(x2, y2, 'bo', 'filled'); hold on;

% 1차 회귀
p2 = polyfit(x2, y2, 1);
yfit2 = polyval(p2, x2);
plot(x2, yfit2, 'k', 'LineWidth', 1.5)

% R^2 계산
R2 = corrcoef(x2, y2);
R_squared2 = R2(1,2)^2;

% % 회귀식 및 R² 출력
% eq2 = sprintf('y = %.2fx + %.2f, R^2 = %.2f', p2(1), p2(2), R_squared2);
% text(min(x2), max(y2), eq2, 'FontSize', 12, 'VerticalAlignment','top');

xlabel('Input D [\mum]'); ylabel('Deposited D [\mum]')
title('Input D vs Deposited D')

% % Field data scatter with linear fit - Case 3: input D vs T *
% subplot(1,3,3)
% x3 = 1000 * D50_input_saito';
% y3 = T_saito / 10000;
% 
% scatter(x3, y3, 'bo', 'filled'); hold on;
% 
% % 1차 회귀
% p3 = polyfit(x3, y3, 1);
% yfit3 = polyval(p3, x3);
% plot(x3, yfit3, 'k', 'LineWidth', 1.5)
% 
% % R^2 계산
% R3 = corrcoef(x3, y3);
% R_squared3 = R3(1,2)^2;
% 
% xlabel('input D [\mum]'); ylabel('T*')
% title('Input D vs T*')



%% 위에 섹션에서 모델의 R 구하는거 추가
% 초기화
A_all = [];
B_all = [];
C_all = [];

% 데이터 수집
for t = 100:50:350
    D_avg_dep = ( 17*log.volume_mud_delta(t,:) + 225*log.volume_sand_delta(t,:) ) ./ ...
                (log.volume_mud_delta(t,:) + log.volume_sand_delta(t,:));
    Tstar = MORFAC * log.delta_area(t,:) * COH_settlevel / (Qw * total / 2650);
    
    A = D_avg_in * 1e3; % x-axis: input avg grain size [micrometers]
    B = D_avg_dep;      % y-axis: deposited avg grain size [micrometers]
    C = Tstar / 10000;  % scatter size (marker size)

    % 누적 저장
    A_all = [A_all, A];
    B_all = [B_all, B];
    C_all = [C_all, C];
end

% Case 1: x = C, y = B
figure; subplot(2,1,1)
scatter(C_all, B_all, 25, 'filled');
xlabel('T^* / 10,000');
ylabel('Deposited avg grain size [\mum]');
title('Case 1: x = C, y = B');
set(gca,'FontSize',14);

% 상관계수 및 p-value 계산
[r1, p1] = corr(C_all', B_all');  % 행벡터 → 열벡터로 변환
fprintf('Case 1 (x = C, y = B): r = %.4f, p = %.4g\n', r1, p1);

% Case 2: x = A, y = B
subplot(2,1,2)
scatter(A_all, B_all, 25, 'filled');
xlabel('Input avg grain size [\mum]');
ylabel('Deposited avg grain size [\mum]');
title('Case 2: x = A, y = B');
set(gca,'FontSize',14);

% 상관계수 및 p-value 계산
[r2, p2] = corr(A_all', B_all');
fprintf('Case 2 (x = A, y = B): r = %.4f, p = %.4g\n', r2, p2);



