% Figure 5 supplementary - 델타 반지름 계산
% (advection100, 200, 300에 대해 각각 수행)

% --- 설정: 처리할 시간 단계와 파일 ---
time_steps = [50,100, 150,200, 250,300];
run_files = {'R29.mat', 'R30.mat', 'R31.mat', 'R32.mat'};

% --- 결과를 저장할 구조체 ---
delta_radius_results = struct();

fprintf('Calculating delta radius...\n');

% 1. 각 시간 단계(100, 200, 300)에 대해 반복
for t_idx = 1:length(time_steps)
    current_time = time_steps(t_idx);
    
    % 현재 시간 단계의 모든 area 데이터를 누적할 배열
    all_areas_for_current_time = [];
    
    % 2. 각 Run 파일(R29~R32)에 대해 반복
    for f_idx = 1:length(run_files)
        
        load(run_files{f_idx}, 'log'); % 'log' 변수만 로드
        
        % 현재 시간 단계(예: 100)의 area 데이터를 가져와 누적
        % log.delta_area(100, :)
        current_area_data = log.delta_area(current_time, :);
        
        % 세로 벡터로 추가 (원본 코드와 동일)
        all_areas_for_current_time = [all_areas_for_current_time; current_area_data'];
    
    end % (파일 루프 종료)
    
    % 3. 현재 시간 단계의 반지름 계산 (원본 공식 유지)
    % (R29~R32의 모든 area 데이터가 all_areas_for_current_time에 누적됨)
    radii = sqrt(2 * all_areas_for_current_time / pi());
    
    % 4. 평균 및 표준편차 계산
    mean_radius = mean(radii);
    std_radius = std(radii);
    
    % 5. 결과 저장
    % 5a. 구조체에 저장 (권장)
    field_name = sprintf('t%d', current_time); % 't100', 't200', 't300'
    delta_radius_results.(field_name).mean = mean_radius;
    delta_radius_results.(field_name).std = std_radius;
    
    % 5b. 원본 코드처럼 개별 변수로 생성
    assignin('base', sprintf('delta_radius_mean_%d', current_time), mean_radius);
    assignin('base', sprintf('delta_radius_std_%d', current_time), std_radius);

end % (시간 단계 루프 종료)

% --- 최종 결과 표시 ---
fprintf('Delta Radius Calculations Complete:\n');
disp(delta_radius_results);

fprintf('\n(Individual variables also created in workspace)\n');
fprintf('delta_radius_mean_100 = %.2f (std = %.2f)\n', delta_radius_mean_100, delta_radius_std_100);
fprintf('delta_radius_mean_200 = %.2f (std = %.2f)\n', delta_radius_mean_200, delta_radius_std_200);
fprintf('delta_radius_mean_300 = %.2f (std = %.2f)\n', delta_radius_mean_300, delta_radius_std_300);