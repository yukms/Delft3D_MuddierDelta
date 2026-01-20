% Figure 1

%% Cautions! Because MSED file is too large I can't upload it!
% Run 'dataext' from 4th folder (Qsr 4.8) in 'Run 29' folder and run this code
%range: 22:227 ;   2:301

% bed level and deltaplain boundary
figure
for i=1:3
subplot(3,3,i)
t=i*100;
imagesc(squeeze(bed_l(t,22:227,2:301)))
colorbar;
caxis([0 1]);
hold on
contour(squeeze(deltaplain(t,22:227,2:301)), [0.5 0.5], 'w', 'LineWidth', 0.5);
contour(squeeze(delta(t,22:227,2:301)), [0.5 0.5] , 'r' ,'LineWidth',0.25);
end


% msed
thickness = sum( msed,[4]);

% sand thickness; 1600 : dry bed density of sand 
for i=1:3
subplot(3,3,3+i)
t=i*100;
imagesc(squeeze(thickness(t,22:227,2:301,1,1)) / 1600)
colorbar;
caxis([0 3.5]);
% hold on
% contour(squeeze(deltaplain(t,22:227,2:301)), [0.8 0.8], 'w', 'LineWidth', 0.5);
end 

% sand thickness; 500 : dry bed density of mud 
for i=1:3
subplot(3,3,6+i)
t=i*100;
imagesc(squeeze(thickness(t,22:227,2:301,1,2)) / 500)
colorbar;
caxis([0 3.5]);
% hold on
% contour(squeeze(deltaplain(t,22:227,2:301)), [0.8 0.8], 'w', 'LineWidth', 0.5);
end 