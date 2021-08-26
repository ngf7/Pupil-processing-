function dil_con_events_no_constraints_v2(tot_file_save_path,mouse,date,blockTransitions)
%%% add elimination of block transition points
%mouse = input('Whats the mouse ID?');
%day = input('Day?');
%load(strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\pass\',mouse,'\',mouse,'_',num2str(day)),'blockTransitions');
%load(strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\pass\',mouse,'\',mouse,'_',num2str(day)),'blockTransitions');
%blockTransitions_pass = blockTransitions;

%load(strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\spont\',mouse,'\',mouse,'_',num2str(day)),'blockTransitions');
%load(strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\spont\',mouse,'\',mouse,'_',num2str(day)),'blockTransitions');
%blockTransitions_spont = blockTransitions + blockTransitions_pass(end);

%blockTransitionsFull = horzcat(blockTransitions_pass, blockTransitions_spont);


load(strcat(tot_file_save_path,'\',mouse,'\',mouse,'_',num2str(day)),'aligned_pupil_smoothed_30')
%load(strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\total\',mouse,'\',mouse,'_',num2str(day)),'totPup','totnorm')

%totPup = totPup';
%wont need this for later datasets - only needed it when this conditional
%cat was happening in the kmeans code 
fc=1;
fs=30;
time = linspace(0.0333,length(aligned_pupil_smoothed_30)/fs,length(aligned_pupil_smoothed_30));




[b,a]=butter(4,fc/(fs/2));
%filt=filter(b,a,pupil_smoothed30_stretched);
ff=filtfilt(b,a,aligned_pupil_smoothed_30);
%ff=filtfilt(b,a,dpp);

for i=1:length(blockTransitions)-1
   aligned_pupil_smoothed_30(blockTransitions(i)-30:blockTransitions(i)+30) = NaN;
   ff(blockTransitions(i)-30:blockTransitions(i)+30) = NaN;
end

mins=islocalmin(ff);
maxs=islocalmax(ff);


figure(1);
clf
plot(time,ff,time(maxs),ff(maxs),'r*',time(mins),ff(mins),'k*')

Cpts=find(mins==1); %Cpts = mins [pts that start constrictin)
Dpts=find(maxs==1);%Dpts = mins (pts that start dilation)
if length(Dpts)>length(Cpts)
   Dpts(1)=[];
elseif length(Cpts)>length(Dpts)
    Cpts(1)=[];
end

%%%Scenario 1: first pt is a min, there will be 1 greater dilation event than
%there wil be constriction events - for dilation events, start corresponds
%with Dpt(i), end corresponds with Cpts(i); for constriction events, start
%corresponds with Cpts(i), end corresponds with Dpt (i+1)
if Dpts(1)<Cpts(1)
    type = 1; 
    
    %create initial dilation and constriciton events
    cEvents=cell(2,length(Dpts));
    dEvents=cell(2,length(Cpts)-1);
    for i=1:length(Dpts)
        cEvents{1,i}=ff(Dpts(i):Cpts(i));
        cEvents{2,i}=Dpts(i):Cpts(i);
    end
    for i=1:length(Dpts)-1
        dEvents{1,i}=ff(Cpts(i):Dpts(i+1));
        dEvents{2,i}=Cpts(i):Dpts(i+1);
    end
    
    %DURATION
    dDuration=(cellfun(@length,dEvents(2,:)))./30;
    cDuration=(cellfun(@length,cEvents(2,:)))./30;
    
    %MAGNITUDE
    dMagnitude = zeros(1,length(dEvents));
    %avgDm=mean(dMagnitude);
    cMagnitude = zeros(1,length(cEvents));
    %avgCm=mean(cMagnitude);
    
    fun = @(m)diff(m,1,2);
    dMagnitude =abs(cellfun(@mean, cellfun(fun,dEvents(1,:),'uni',0)));
    cMagnitude = abs(cellfun(@mean, cellfun(fun,cEvents(1,:),'uni',0)));
    
   
    
    elseif Dpts(1)>Cpts(1)
    type = 2; 
    cEvents=cell(2,length(Dpts)-1);
    dEvents=cell(2,length(Cpts));
    for i=1:length(Dpts)
        dEvents{1,i}=ff(Cpts(i):Dpts(i));
        dEvents{2,i}=Cpts(i):Dpts(i);
    end
    for i=1:length(Dpts)-1
        cEvents{1,i}=ff(Dpts(i):Cpts(i+1));
        cEvents{2,i}=Dpts(i):Cpts(i+1);
    end

    %DURATIONS
    dDuration=(cellfun(@length,dEvents(2,:)))./30;
    cDuration=(cellfun(@length,cEvents(2,:)))./30;
   
    dMagnitude = zeros(1,length(dEvents));
    cMagnitude = zeros(1,length(cEvents));
    
    fun = @(m)diff(m,1,2);
    dMagnitude =abs(cellfun(@mean, cellfun(fun,dEvents(1,:),'uni',0)));
    cMagnitude = abs(cellfun(@mean, cellfun(fun,cEvents(1,:),'uni',0)));
end

   



    dhasTrans=[];
for i=1: length(dEvents) 
    TF=any(isnan(dEvents{1,i}));
    if TF==1
        dhasTrans=[dhasTrans i];
    end
end

dEvents(:,dhasTrans) = [];
dMagnitude(:,dhasTrans) = [];
dDuration(:,dhasTrans) = [];


chasTrans = [];
for i=1: length(cEvents) 
    TF=any(isnan(cEvents{1,i}));
    if TF==1
        chasTrans=[chasTrans i];
    end
end
cEvents(:,chasTrans) = [];
cMagnitude(:,chasTrans) = [];
cDuration(:,chasTrans) = [];

% 
figure(15);
clf
plot(time,ff,time(Dpts),ff(Dpts),'r*',time(Cpts),ff(Cpts),'k*')


 
 
  edges = 0:.5:31;
   AVG_dDuration=mean(dDuration);
   AVG_cDuration=mean(cDuration);
   AVG_dMagnitude=mean(dMagnitude);
   AVG_cMagnitude=mean(cMagnitude);
   
   
   
  new_Cpts=cellfun(@(v)v(1),dEvents);
  new_Dpts=cellfun(@(v)v(end),dEvents); 
  figure(13)
  clf
  plot(time,ff,time(new_Dpts(2,:)),ff(new_Dpts(2,:)),'r*',time(new_Cpts(2,:)),ff(new_Cpts(2,:)),'k*')

    
%      figure(18)
%   clf
%   subplot(2,1,1);
% histogram(FINAL_dDuration,edges)
% line([AVG_dDuration AVG_dDuration], get(gca, 'ylim'));
% title('dilations')
% subplot(2,1,2)
% histogram(FINAL_cDuration,edges)
% line([AVG_cDuration AVG_cDuration], get(gca, 'ylim'));
% title('constrictions')
% xlabel('time(s)')
% ylabel('#events')
% 
% figure(19)
% clf
% edges = 0:0.00005:0.0035;
%   subplot(2,1,1);
% histogram(FINAL_dMagnitude,edges)
% line([AVG_dMagnitude AVG_dMagnitude], get(gca, 'ylim'));
% title('dilations')
% subplot(2,1,2)
% histogram(FINAL_cMagnitude,edges)
% line([AVG_cMagnitude AVG_cMagnitude], get(gca, 'ylim'));
% title('constrictions')
% xlabel('average change across event')
% ylabel('#events')
%  
%save(strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\total\',mouse,'\',mouse,'_',num2str(day),'LocalExtrema.mat'),'dMagnitude','cMagnitude','dDuration','cDuration','AVG_cDuration','AVG_dDuration','AVG_cMagnitude','AVG_dMagnitude','-append');

%save(strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\processed\total\',mouse,'\',mouse,'_',num2str(day),'LocalExtrema.mat'),'Cpts','Dpts','dEvents','dDuration','dMagnitude','cEvents','cDuration','cMagnitude','AVG_cDuration','AVG_dDuration','AVG_dMagnitude','AVG_cMagnitude','new_Cpts','new_Dpts','totBlockTransitions','ff','totPup');
save(strcat(tot_file_save_path,'\',mouse,'_',num2str(date)),'Cpts','Dpts','dEvents','dDuration','dMagnitude','cEvents','cDuration','cMagnitude','AVG_cDuration','AVG_dDuration','AVG_dMagnitude','AVG_cMagnitude','new_Cpts','new_Dpts','ff','-append');