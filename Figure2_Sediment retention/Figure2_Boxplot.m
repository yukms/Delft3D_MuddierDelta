%% 1. Data Loading and Preparation
% 각 mat 파일에서 데이터를 로드하여 하나로 합칩니다.

% R30 (SLR 3mm/yr)
load('R30.mat');
temp1 = log.r_sand_delta(80:end, :);
temp2 = log.r_mud_delta(80:end, :);

% R31 (SLR 5mm/yr)
load('R31.mat');
temp3 = log.r_sand_delta(80:end, :);
temp4 = log.r_mud_delta(80:end, :);

% R32 (SLR 7mm/yr)
load('R32.mat');
temp5 = log.r_sand_delta(80:end, :);
temp6 = log.r_mud_delta(80:end, :);

% R29 (SLR 0mm/yr)
load('R29.mat');
temp7 = log.r_sand_delta(80:end, :);
temp8 = log.r_mud_delta(80:end, :);

% 모든 케이스의 데이터를 하나의 벡터로 통합
combined_mud = [temp8(:); temp2(:); temp4(:); temp6(:)];
combined_sand = [temp7(:); temp1(:); temp3(:); temp5(:)];

% 기본 통계량 출력 (확인용)
fprintf('Sand - Mean: %.4f, Std: %.4f\n', mean(combined_sand), std(combined_sand));
fprintf('Mud  - Mean: %.4f, Std: %.4f\n', mean(combined_mud), std(combined_mud));

%% 2. Draw Box Plot
% 박스 플롯 시각화

figure('Units', 'inches', 'Position', [0, 0, 4, 4]); % Figure 사이즈 설정
boxplot([combined_sand, combined_mud], 'Labels', {'Sand', 'Mud'});

% 그래프 꾸미기
ylabel('Retention Fraction', 'FontSize', 12);
title('Comparison of Sand and Mud Retention', 'FontSize', 12);
grid on; % 격자 추가
set(gca, 'FontSize', 12); % 축 글씨 크기 조절