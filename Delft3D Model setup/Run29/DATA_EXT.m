% trapping efficiency vs delta size & time
clear
close all
%put parameter in struct   % where we have sea level rise of 1 m
out.runsdir = '/Volumes/One Touch/Sediment retention backup/Delft3D/Run_29'; %%change this whg
out.runname = ['Qsrchange'];
runid='Run_SLR_none';

%% information for 'for' loop
ratio=linspace(1, 20 , 16)';
total=0.3;% kgm-3

mud = ratio*total./(1+ratio);% kgm-3
sand = total-mud;% kgm-3
level = [0.00*120];
Qss=sand;
Qmm=mud;


% for ss= 1: length(Qmm) 원래는 16개 시뮬레이션을 전부 한번에 저장합니다. 
for ss=4; % 지금은 sand mud 비율 1개만 계산하도록 한 것 
    tic % 뒤에 toc 까지 걸리는 소요 시간 측정
    Qm=Qmm(ss);
    Qs=Qss(ss);
    rundir=[out.runsdir filesep out.runname '_Qs' num2str(Qs,'%g') '_Qm' num2str(Qm,'%g') 'level' num2str(level,'%g')];
    % And go to data folder
    curdir=pwd;
    cd(rundir);
    
    % vs_use  
    trim=vs_use('trim-Delta_SLR_None.dat','trim-Delta_SLR_None.def','quiet');
    trih=vs_use('trih-Delta_SLR_None.dat','trih-Delta_SLR_None.def','quiet');
    %% load data (vs_let)
    % vs_let(trim) 이나 vs_let(trih) 을 그냥 명령창에 치면 표가 뜹니다. 거기있는 데이터 들을
    % 불러오는것입니다.
    % {0} 같은것은 차원(?)을 의미하는것이고 'quiet' 은 조용히 불러오기 기능입니다.
    % (delft3D matlab jaap 폴더 가면 vs_let vs_use 에 대한 코드가 있습니다.)
    
    
    t = vs_let(trim,'map-infsed-serie',{0},'MORFT','quiet'); %morphological time
    qw = vs_let(trih,'his-series',{0},'CTR',{1},'quiet'); %m3s-1
    cum_qs_sand = vs_let(trih,'his-sed-series',{0},'SSTRC',{1,1},'quiet')+... % cumulative sediment supply
    vs_let(trih,'his-sed-series',{0},'SBTRC',{1,1},'quiet'); % cumulative sediment supply
    cum_qs_sus = vs_let(trih,'his-sed-series',{0},'SSTRC',{1,2},'quiet'); %m3
    ins_qs_sand = vs_let(trih,'his-sed-series',{0},'SSTR',{1,1},'quiet')+... %
    vs_let(trih,'his-sed-series',{0},'SBTR',{1,1},'quiet'); %     
    ins_qs_sus = vs_let(trih,'his-sed-series',{0},'SSTR',{1,2},'quiet'); %m3s-1
    cum_qs_total=cum_qs_sand+cum_qs_sus; % caculate total volume of sediment 
    bed_l=-1*vs_let(trim,'map-sed-series','DPS','quiet'); % bed level
    S1 = vs_let(trim,'map-series',{0},'S1','quiet');
    U1 = vs_let(trim,'map-series',{0},'U1','quiet');
    V1 = vs_let(trim,'map-series',{0},'V1','quiet');
    mudfrac=vs_let(trim,'map-sed-series',{0},'MUDFRAC','quiet');
    lyrfrac=vs_let(trim,'map-sed-series',{0},'LYRFRAC','quiet');
    dp_bedlyr=vs_let(trim,'map-sed-series',{0},'DP_BEDLYR','quiet');
    msed=vs_let(trim,'map-sed-series',{0},'MSED','quiet'); % kg/m2

    volume_lyr1=zeros(length(t),227,302);
    lyrfrac_lyr1=zeros(length(t),227,302);
    volume_lyr1_sand=zeros(length(t),227,302);
    volume_lyr1_mud=zeros(length(t),227,302);
    channel=zeros(length(t),227,302);

%% analysis

% assign location
Sea_level=S1(:,226,301);
for ii=1:length(t)
    OAM_delta  % OAM_delta 라는 코드를 실행해서 delta boundary를 정의합니다. Open angle method- John Shaw 의 논문에서 나온 방법입니다, 코드 참고 바람
    delta(ii,:,:)=delta_OAM;
    deltaplain(ii,:,:)=  bed_l(ii,:,:) < 4.99 & bed_l(ii,:,:) > 0;
    wet_frac(ii)=wetfrac;
    channel(ii,:,:) = (delta_OAM~=land);
    land_1(ii,:,:) = land;
end
   channel_area = sum(channel,[2 3])*25*25;
    delta_area=sum(delta,[2 3])*25*25;
    deltaplain_area=sum(deltaplain,[2 3])*25*25;
%%  squeeze 는 차원을 2차원으로 압축시키는? 그런 코드입니다 자세하겐 help squeeze 해보세요
    for i = 1 : 1 :length(t)
        vel_mag(i,:,:) = squeeze( sqrt((U1(i,:,:).^2)+V1(i,:,:).^2) );
        vel_mag_delta(i,:,:) = vel_mag(i,:,:).* land_1(i,:,:);
        flood_delta_1(i,:,:) = vel_mag_delta(i,:,:) > 0.00025*10 ;
        flood_delta_2(i,:,:) = vel_mag_delta(i,:,:) > 0.00025*100 ;
    end  
    % imagesc(squeeze(vel_mag(300,:,:)))  해보세요.
    % vel_magnitude의 300번째 타입스텝, 모든 X,Y , 즉 2차원 평면에 속도값들을 표면합니다.
    % figure,plot(squeeze(vel_mag(100,100,:))) 은?
    
%% Mass change
% volume change at all layers
% domain

% 25 ^2 는 한 픽셀 크기를 말하는거고 1600, 500 은 denstiy입니다. 결국 volume change를 계산하는 식
% 입니다.  lambda는 무시
for i = 1 : length(t)-1 
    vc_sand(i,:,:)=  (sum(msed(i+1,:,:,:,1), [4] )-sum(msed(i,:,:,:,1), [4] )).*25^2 /1600; % m3
    vc_mud(i,:,:)=  (sum(msed(i+1,:,:,:,2), [4] )-sum(msed(i,:,:,:,2), [4] )).*25^2 / 500;
    vc_sand_basement(i,:,:)=  (sum(msed(i+1,:,:,:,3), [4] )-sum(msed(i,:,:,:,3), [4] )).*25^2 / 1600;
% delta     
    vc_sand_delta (i,:,:) = vc_sand(i,:,:).* delta(i,:,:);
    vc_sand_basement_delta (i,:,:) = vc_sand_basement(i,:,:).* delta(i,:,:);
    vc_mud_delta (i,:,:) = vc_mud(i,:,:).* delta(i,:,:);
    lambda_delta(i,:,:) = vc_mud_delta(i,:,:) ./ (vc_sand_delta(i,:,:)+vc_sand_basement_delta(i,:,:)) ;
% deltaplain
    vc_sand_deltaplain (i,:,:) = vc_sand(i,:,:).* deltaplain(i,:,:);
    vc_sand_basement_deltaplain (i,:,:) = vc_sand_basement(i,:,:).* deltaplain(i,:,:);
    vc_mud_deltaplain (i,:,:) = vc_mud(i,:,:).* deltaplain(i,:,:);
    lambda_deltaplain(i,:,:) = vc_mud_deltaplain(i,:,:) ./ (vc_sand_deltaplain(i,:,:)+vc_sand_basement_deltaplain(i,:,:)) ;
end



%% sediment input
sand_in = (cum_qs_sand-cum_qs_sand(find(t>0,1))).*(t>0).*2650.*100; % in mass (in cumulative)   MorFAC=100
mud_in = (cum_qs_sus-cum_qs_sus(find(t>0,1))).*(t>0).*2650.*100; % in mass % kg
qs_sand_input = diff(sand_in)/1600;  % in volume m3 in deposit (diff one time step)
qs_mud_input = diff(mud_in)/500; % in volume m3 in deposit (diff one time step)

%% sediment retention in deltaplain, delta, in all layers,
r_sand_delta = sum(vc_sand_delta,[2 3]) ./ qs_sand_input;
r_mud_delta = sum(vc_mud_delta,[2 3]) ./ qs_mud_input;
r_sand_deltaplain = sum(vc_sand_deltaplain,[2 3]) ./ qs_sand_input;
r_mud_deltaplain = sum(vc_mud_deltaplain,[2 3]) ./ qs_mud_input;
r_total_delta = (sum(vc_sand_delta,[2 3])+sum(vc_mud_delta,[2 3])) ./ (qs_sand_input+qs_mud_input);


%% total retention
% msed mud and sand in dp and domain
msed_mud=sum(msed(:,:,:,:,2),[2 3 4 ]).*25^2; % kg
msed_mud=(msed_mud-msed_mud(1));
msed_sand=sum(msed(:,:,:,:,1),[2 3 4 ]).*25^2;
msed_sand=(msed_sand-msed_sand(1));
msed_sand_base=sum(msed(:,:,:,:,3),[2 3 4 ]).*25^2;
msed_sand_base=(msed_sand_base-msed_sand_base(1));

% % % % mass balance check   % MAss balance가 잘 맞는지 중간중간 체크하는것입니다. 수치 모델이여서 100% 맞진
% 않습니다. 
% plot(diff(msed_mud)./diff(mud_in))
% plot(diff(msed_sand)./diff(sand_in))

for tt=1:length(t)   %% 주의 foreset은 고려되지않음!!!
msed_mud_delta(tt)=sum(  (sum(msed(tt,:,:,:,2),[4] )-msed_mud(1)).*delta(tt,:,:),'all') .*25^2; % kg
msed_sand_delta(tt)=sum(   (sum(msed(tt,:,:,:,1),[4] )-msed_sand(1)).*delta(tt,:,:) ,'all') .*25^2;
msed_sand_base_delta(tt) = sum(   (sum(msed(tt,:,:,:,3),[4] )-msed_sand_base(1)).*delta(tt,:,:) ,'all').*25^2;
end
volume_sand_delta = msed_sand_delta/1600;
volume_mud_delta = msed_mud_delta/500;
volume_sand_base_delta = msed_sand_base_delta/1600;

mudfrac = volume_mud_delta./(volume_mud_delta+volume_sand_delta+volume_sand_base_delta);
% figure,plot(mudfrac)
% mud proportion in layer 1
for tt = 1 : length(t)
    % 여기서 delta 인 애들만 ! !.*delta(tt,:,:)를 해야된다
    mudproplyr1(tt)=sum(msed(tt,:,:,1,2).*delta(tt,:,:),'all') / (sum(msed(tt,:,:,1,1).*delta(tt,:,:),'all')+sum(msed(tt,:,:,1,3).*delta(tt,:,:),'all') );
end

for i=1:length(t)  %% 이건 cumulative?
delta_retention_mud(i) = msed_mud_delta(i) /mud_in(i) ;
delta_retention_sand(i) = msed_sand_delta(i) / sand_in(i) ;
delta_retention_total(i) = (msed_mud_delta(i)+msed_sand_delta(i)) / (mud_in(i)+sand_in(i)); 
end


%% lambda 
lambda_surface_delta=sum(vc_mud_delta,[2 3]) ./ (sum(vc_sand_delta,[2 3]) + sum(vc_sand_basement_delta, [2 3]) );
% figure,plot(lambda_surface_delta(50:end))
% xlabel('timestep');ylabel('lambda across the delta');  
lambda_surface_deltaplain=sum(vc_mud_deltaplain,[2 3]) ./ (sum(vc_sand_deltaplain,[2 3]) + sum(vc_sand_basement_deltaplain, [2 3]) );



%% data save    % data save 하는 부분입니다. ss가 각 다른 모델 시뮬레이션입니다. 
% ss 개 시뮬레이션에 대한 정보를 저장하면 행이 t 개 (time 개수) 열이 ss개 (시뮬레이션개수) 이렇게 저장됩니다
log.deltaplain_area(:,ss)=deltaplain_area;
log.delta_area(:,ss)=delta_area;

log.wetfrac(:,ss)=wet_frac;

log.r_sand_delta(:,ss)=r_sand_delta;
log.r_mud_delta(:,ss) = r_mud_delta ;
log.r_total_delta(:,ss) =r_total_delta;
log.r_sand_deltaplain(:,ss) = r_sand_deltaplain ;
log.r_mud_deltaplain(:,ss)= r_mud_deltaplain;
log.r_sand_delta_lyr1(:,ss)=r_sand_delta;
log.r_mud_delta_lyr1(:,ss) = r_mud_delta ;
log.r_sand_deltaplain_lyr1(:,ss) = r_sand_deltaplain ;
log.r_mud_deltaplain_lyr1(:,ss)= r_mud_deltaplain;


log.lambda_surface_delta(:,ss)=lambda_surface_delta;
log.lambda_surface_deltaplain(:,ss)=lambda_surface_deltaplain;


log.channel_area(:,ss) = channel_area;
log.t=t;
log.input_ratio=ratio;

log.delta_retention_mud(:,ss) = delta_retention_mud;
log.delta_retention_sand(:,ss) = delta_retention_sand;

log.volume_sand_delta(:,ss) = volume_sand_delta;
log.volume_mud_delta(:,ss) = volume_mud_delta;
log.volume_sand_base_delta(:,ss) = volume_sand_base_delta;

log.vc_sand_delta(:,ss) = sum(vc_sand_delta,[2 3]);
log.vc_mud_delta(:,ss) = sum(vc_mud_delta,[2 3]);
log.qs_sand_input(:,ss)= qs_sand_input;
log.qs_mud_input(:,ss) = qs_mud_input;

log.delta_retention_mud(:,ss) = delta_retention_mud;
log.delta_retention_sand(:,ss) = delta_retention_sand;
log.delta_retention_total(:,ss) = delta_retention_total;
log.mudproplyr1(:,ss) = mudproplyr1;

log.flood_delta_1(:,ss)=sum(flood_delta_1, [2 3]);
log.flood_delta_2(:,ss) = sum(flood_delta_2, [2 3]);  % if you wanna map flood, go to X:\Delft3D\flood_test.m 
% back to cdr;
cd(curdir);
toc
end

sum_vc_sand = sum(vc_sand_delta, [2 3]);
sum_vc_mud = sum(vc_mud_delta,[2 3]);
sum_vc_base = sum(vc_sand_basement_delta, [2 3 ]);

figure,plot(sum_vc_sand)
hold on
plot(sum_vc_mud)
plot(sum_vc_base)
legend('sand','mud','base')