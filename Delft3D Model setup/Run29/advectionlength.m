%% advection length sclae : water depth, water flow velocity in channel, nonchannel, settling velocity of mud..!
close all
%put parameter in struct   % where we have sea level rise of 1 m
out.runsdir = 'X:\Delft3D\Run_29'; %%change this whg
out.runname = ['Qsrchange'];
runid='Run_SLR_none';

%% horizontal
ratio=linspace(1, 20 , 16)';
total=0.3;% kgm-3

mud = ratio*total./(1+ratio);% kgm-3
sand = total-mud;% kgm-3
level = [0.00*120];
Qss=sand;
Qmm=mud;
%% vertical
% mud = 0.15 : 0.15 : 3;
% sand = ones(1,length(mud))*0.15;l

for ss= 1: length(Qmm)
% for ss=2; % 11
    tic
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
    t = vs_let(trim,'map-infsed-serie',{0},'MORFT','quiet'); %morphological time
    qw = vs_let(trih,'his-series',{0},'CTR',{1},'quiet'); %m3s-1
    bed_l=-1*vs_let(trim,'map-sed-series','DPS','quiet'); % bed level
    S1 = vs_let(trim,'map-series',{0},'S1','quiet');
    U1 = vs_let(trim,'map-series',{0},'U1','quiet');
    V1 = vs_let(trim,'map-series',{0},'V1','quiet');
    waterdepth = S1-bed_l;
    
    channel=zeros(length(t),227,302);

%% analysis
% assign location

Sea_level=S1(:,226,301);
for ii=1:length(t)
    OAM_delta
    delta(ii,:,:)=delta_OAM;
    deltaplain(ii,:,:)=  bed_l(ii,:,:) < 4.99 & bed_l(ii,:,:) > 0;
    wet_frac(ii)=wetfrac;
    channel(ii,:,:) = (delta_OAM~=land);
    land_1(ii,:,:) = land;
end
   channel_area = sum(channel,[2 3])*25*25;
    delta_area=sum(delta,[2 3])*25*25;
    deltaplain_area=sum(deltaplain,[2 3])*25*25;
%%
    for i = 1 : 1 :length(t)
        vel_mag(i,:,:) = squeeze( sqrt((U1(i,:,:).^2)+V1(i,:,:).^2) );
        vel_mag_channel(i,:,:) = vel_mag(i,:,:).* channel(i,:,:);
        vel_mag_land(i,:,:) = vel_mag(i,:,:).*land_1(i,:,:);
        
        depth_channel(i,:,:)= waterdepth(i,:,:).*channel(i,:,:);
        depth_land(i,:,:) = waterdepth(i,:,:).*land_1(i,:,:);
    end  
    
    advection300(ss).channel_velocity = vel_mag_channel(300,:,:); 
    advection300(ss).channel_depth = depth_channel(300,:,:);
    advection300(ss).land_velocity = vel_mag_land(300,:,:);
    advection300(ss).land_depth =  depth_land(300,:,:);
        advection100(ss).channel_velocity = vel_mag_channel(100,:,:); 
    advection100(ss).channel_depth = depth_channel(100,:,:);
    advection100(ss).land_velocity = vel_mag_land(100,:,:);
    advection100(ss).land_depth =  depth_land(100,:,:);
        advection200(ss).channel_velocity = vel_mag_channel(200,:,:); 
    advection200(ss).channel_depth = depth_channel(200,:,:);
    advection200(ss).land_velocity = vel_mag_land(200,:,:);
    advection200(ss).land_depth =  depth_land(200,:,:);
% back to cdr;
cd(curdir);
toc
end
save('advectionlength2.mat','advection100','advection200','advection300')

