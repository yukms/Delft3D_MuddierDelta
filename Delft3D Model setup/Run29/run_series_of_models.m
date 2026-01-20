function run_series_of_models
out.runsdir = 'D:\Minsik\Delft3D\Run_40'; 
out.runname = ['Qsrchange'];
runid='Run_SLR_none';

inputdir=[out.runsdir filesep '[Cohesive_Mud_Included] Retention_input' filesep];

% water discharge is 1000 m3/sec
% horizontal
ratio=linspace(1, 20 , 16)';
total=0.3;% kgm-3
mud = ratio*total./(1+ratio);% kgm-3
sand = total-mud;% kgm-3
sealevel_end = [0];

for j = 1 : length(sealevel_end)
for  i = 1 : length(ratio)
    Qs = sand(i);
    Qm = mud(i);
    level = sealevel_end(j);

    rundir=[out.runsdir filesep out.runname '_Qs' num2str(Qs,'%g') '_Qm' num2str(Qm,'%g') 'level' num2str(level,'%g')];
    mkdir(rundir);
    copyfile([inputdir '*.*'],rundir); % inputdir should be untouched
    
                %adjust sediment discharge ratio..  find the txt file and change
                %'A' to 'B'
                findreplace([rundir filesep runid '.bcc'],['change1'],[num2str(Qs,'%g')]);
                findreplace([rundir filesep runid '.bcc'],['change2'],[num2str(Qm,'%g')]);
                
                findreplace([rundir filesep runid '.bct'],['change3'],[num2str(sealevel_end(j),'%g')]);

                %adjust water discharge m3s-1
%                 findreplace([rundir filesep runid '.bct'],['1.0000000e+003'],[num2str(Qs,'%g')]);

%         findreplace([rundir filesep runid '.bcc'],['t.0' num2str(Qm) '00000'],[num2str(storm_time(Qm),'%1.7f')
    % And run the simulation
    curdir=pwd;
    cd(rundir);
    dos('call run_flow2d3d_parallel.bat'); % must sit in inputdir!
    cd(curdir); 
end
end
end


% end




