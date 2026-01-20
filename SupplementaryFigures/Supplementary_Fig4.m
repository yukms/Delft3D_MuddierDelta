figure('Units','centimeters','Position',[1 1 18 10]);

loadname = ["R29.mat", "R30.mat", "R31.mat", "R32.mat"];
slr_labels = {'0','0.3','0.5','0.7'};
colors = [1 0 0; 0 0.6 0; 0 0 1; 0 0 0];  % red, green, blue, black

% === [수정] boxwidth 변수 정의 ===
boxwidth = 0.15;  % 박스 너비 설정 (0.15 ~ 0.2 정도가 적당함)

%% ===== 1. Sand Retention vs Channel Area =====
% --- 자동 bin 계산 ---
all_channel_area = [];
for slr_id = 1:4
    load(loadname(slr_id))
    x = log.channel_area(81:end,:)/1e6;
    all_channel_area = [all_channel_area; x(:)];
end
edges = linspace(min(all_channel_area), max(all_channel_area), 5);  % 4 bin
bin_labels = arrayfun(@(i) sprintf('%.1f–%.1f', edges(i), edges(i+1)), 1:4, 'UniformOutput', false);

% --- Sand Retention boxplot ---
subplot(1,2,1); hold on
all_y = []; all_pos = [];
for slr_id = 1:4
    load(loadname(slr_id))
    x = log.channel_area(81:end,:)/1e6;
    y = log.r_sand_delta(80:end,:);
    x = x(:); y = y(:);
    
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid); y = y(valid);
    
    [~, bin_idx] = histc(x, edges);
    
    for b = 1:4
        idx = (bin_idx == b);
        if any(idx)
            % 여기서 boxwidth가 사용됩니다.
            xpos = b + (slr_id - 2.5) * boxwidth;
            all_y = [all_y; y(idx)];
            all_pos = [all_pos; repmat(xpos, sum(idx), 1)];
        end
    end
end

boxplot(all_y, all_pos, 'Positions', unique(all_pos), 'Colors', 'k', 'Widths', boxwidth, 'Symbol','');

% 박스 색상 입히기
h = findobj(gca, 'Tag', 'Box');
% 핸들이 역순으로 잡히는 경우가 많아, x축 위치를 기준으로 정렬하여 색상을 입힙니다.
boxes = h(end:-1:1); 
x_centers = arrayfun(@(x) x.XData(1), boxes); % 박스 중심 좌표 추출
[~, sort_idx] = sort(x_centers);
sorted_boxes = boxes(sort_idx);

% 정렬된 박스에 순서대로 색상 적용 (반복)
for j = 1:length(sorted_boxes)
    color_idx = mod(j-1, 4) + 1;
    patch(get(sorted_boxes(j), 'XData'), get(sorted_boxes(j), 'YData'), colors(color_idx,:), ...
          'FaceAlpha', 0.4, 'EdgeColor', 'k');
end

% --- X축 및 범위 표시 ---
xticks(1:4)
xticklabels({'1','2','3','4'})
xlabel('Channel Area Bin [km^2]', 'FontSize', 10)
ylabel('Sand Sediment Retention', 'FontSize', 10)
title('(a) Sand Retention', 'FontSize', 10) % 제목 추가
set(gca, 'FontSize', 8)
% ylim([0 1]) % 필요시 주석 해제

% bin 범위 텍스트 추가
yl = ylim;
text_y_pos = yl(2) * 1.02; % Y축 범위에 맞춰 위치 자동 조정
for i = 1:4
    text(i, text_y_pos, bin_labels{i}, 'HorizontalAlignment', 'center', 'FontSize', 7)
end


%% ===== 2. Mud Retention vs Floodplain Area =====
% --- bin 경계 자동 계산 ---
all_floodplain_area = [];
for slr_id = 1:4
    load(loadname(slr_id))
    floodplain = (log.delta_area - log.channel_area) / 1e6;
    all_floodplain_area = [all_floodplain_area; floodplain(:)];
end
edges = linspace(min(all_floodplain_area), max(all_floodplain_area), 5);  % 4 bins
nbins = length(edges) - 1;
bin_labels = arrayfun(@(i) sprintf('%.1f–%.1f', edges(i), edges(i+1)), 1:nbins, 'UniformOutput', false);

% --- boxplot 구성 ---
subplot(1,2,2); hold on
all_y = []; all_pos = [];
for slr_id = 1:4
    load(loadname(slr_id))
    log.flood_delta_1 = log.delta_area - log.channel_area;
    x = log.flood_delta_1(81:end,:) / 1e6;
    y = log.r_mud_delta(80:end,:);
    
    x = x(:); y = y(:);
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid); y = y(valid);
    
    [~, bin_idx] = histc(x, edges);
    
    for b = 1:nbins
        idx = (bin_idx == b);
        if any(idx)
            xpos = b + (slr_id - 2.5) * boxwidth;
            all_y = [all_y; y(idx)];
            all_pos = [all_pos; repmat(xpos, sum(idx), 1)];
        end
    end
end

% --- boxplot 그리기 ---
boxplot(all_y, all_pos, 'Positions', unique(all_pos), 'Colors', 'k', 'Widths', boxwidth, 'Symbol','');

% 색상 입히기 (정렬 방식 적용)
h = findobj(gca, 'Tag', 'Box');
boxes = h(end:-1:1);
x_centers = arrayfun(@(x) x.XData(1), boxes);
[~, sort_idx] = sort(x_centers);
sorted_boxes = boxes(sort_idx);

for j = 1:length(sorted_boxes)
    color_idx = mod(j-1, 4) + 1;
    patch(get(sorted_boxes(j), 'XData'), get(sorted_boxes(j), 'YData'), colors(color_idx,:), ...
          'FaceAlpha', 0.4, 'EdgeColor', 'k');
end

% --- x축 처리 ---
xticks(1:nbins)
xticklabels({'1','2','3','4'})
xlabel('Floodplain Area Bin [km^2]', 'FontSize', 10)
ylabel('Mud Sediment Retention', 'FontSize', 10)
title('(b) Mud Retention', 'FontSize', 10)
set(gca, 'FontSize', 8)
ylim([0 0.5])

% bin 범위 텍스트 표시
for i = 1:nbins
    text(i, 0.5 * 1.02, bin_labels{i}, 'HorizontalAlignment', 'center', 'FontSize', 7) % Y 위치 고정값 대신 상단 기준 조정 추천
end

%% ===== Legend (Dummy Handles 생성) =====
% Boxplot은 객체가 많아 legend가 꼬이기 쉬우므로 가짜 플롯을 만들어 범례를 답니다.
h_legend = zeros(4,1);
for i = 1:4
    h_legend(i) = patch(NaN, NaN, colors(i,:), 'FaceAlpha', 0.4, 'EdgeColor', 'k');
end
lg = legend(h_legend, slr_labels, 'Position', [0.91 0.75 0.05 0.1]);
title(lg, 'SLR [mm/yr]', 'FontSize', 8)

% 파일 저장 부분 (필요시 경로 수정)
% filePath = 'C:\Users\Minsik Kim\Desktop\accomretention';
% filename = 'accom vs sediment retention fraction box.eps';
% fullFilePath=fullfile(filePath,filename);
% if ~exist(filePath, 'dir')
%    mkdir(filePath);
% end
% print(gcf, fullFilePath, '-depsc2', '-painters');