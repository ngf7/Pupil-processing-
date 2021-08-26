function make_pupil_aligned_rough(mouse,date,cont,save_path,save_path_pass,save_path_spont,base_path,base_path_wav,pupil_all,blocks)
tf_cont= strcmp(cont,'none');
tf_which_cont = strcmp(cont,'pass'); 

%cd(strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Christine Pupil\',mouse,'\',num2str(year),num2str(day),'\',cont))
%cd(strcat('\\runyan-fs-01\Runyan2\Caroline\2P\SOM_VIP\pupil\',num2str(date),'\',mouse))
%cd(base_path)
%   Horizontally concatenates blocks
%d = dir(strcat(mouse,'_smoothed_*_.mat'));
pupil_full = []; %concatenated pupil trace (all blocks), raw
pupil_smoothed_30 = []; %concatenated pupil trace, smoothed by median over 30 timeframes
pupil_smoothed_10 = []; %concatenated pupil trace, smoothed by median over 10 timeframes
xpos = [];
ypos = [];
for i=1:length(pupil_all)
    load(d(i).name)
    pupil_full = [pupil_full pupil_all{i}.area.corrected_areas]; %change made from pupil_cat_stretched to pupil_cat_raw_smoothed_cut NF 5/3)
    pupil_smoothed_30 = [pupil_smoothed_30 pupil_all{i}.area.smoothed_30_timeframes];
    pupil_smoothed_10 = [pupil_smoothed_10 pupil_all{i}.area.smoothed_10_timeframes];
    xpos = [xpos pupil_all{i}.center_position.center_column_cut];
    ypos = [ypos pupil_all{i}.center.position.center_row_cut];
end


%save_loc=strcat('\\runyan-fs-01\Runyan2\Caroline\2P\SOM_VIP\pupil\',num2str(date),'\',mouse);
%save_loc=strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\',cont,'\',mouse);

presence = exist(save_path, 'dir');

if presence==7
    save(strcat(save_path,'\',mouse,'_', num2str(day),'.mat'),'pupil_full');
elseif presence==0
    %cd(strcat('\\runyan-fs-01\Runyan\Noelle\reprocessed data\',cont,'\'));
    mkdir save_path;
    movefile save_path
    %movefile save_loc ci33l %%NEED TO CHANGE NAME OF MOUSE HERE BEFORE RUNNING TO MAKE SURE ITS SAVING TO RIGHT PLACE
    save(strcat(save_path,'\',mouse,'_', num2str(day),'.mat'),'pupil_all');
end

%sizedir = size(d);
%blocks = (1:sizedir(1));

%CALL FUNCTION TO ALIGN RUNNING AND GALVO   
[x_velocity,y_velocity] = make_v_inputs_nf_v2(base_path_wav,blocks);



%%CALL FUNCTION TO ALIGN PUPIL WITH GALVO 
[aligned_pupil_unsmoothed,framesperblock] = make_pupil_aligned_tseries(base_path_tseries,pupil_full);%uses t-series as opposed to wavesurfer to get 2p frames - since not synching signal this is easier than going through wavesurfer
aligned_pupil_smoothed_10=imresize(pupil_smoothed_10,[1,length(aligned_pupil_unsmoothed)]);
aligned_pupil_smoothed_30=imresize(pupil_smoothed_30,[1,length(aligned_pupil_unsmoothed)]);
aligned_x_position = imresize(xpos,[1,length(aligned_pupil_unsmoothed)]);
aligned_y_position = imresize(ypos,[1,length(aligned_pupil_unsmoothed)]);

if length(x_velocity)>length(aligned_pupil_unsmoothed)
    x_velocity=x_velocity(1:length(aligned_pupil_unsmoothed));
    y_velocity=y_velocity(1:length(aligned_pupil_unsmoothed));
end

 
    if length(find(isnan(aligned_pupil_smoothed_30)))>0
        nanx = isnan(aligned_pupil_smoothed_30);
        t    = 1:numel(aligned_pupil_smoothed_30);
        aligned_pupil_smoothed_30(nanx) = interp1(t(~nanx),aligned_pupil_smoothed_30(~nanx), t(nanx));
    end
    

%NORMALIZE PUPIL TO COMPARE ACROSS MICE AND DAYS 
%m = mean(aligned_pupil_smoothed_30);
pup_norm_30 =(aligned_pupil_smoothed_30-mean(aligned_pupil_smoothed_30))/mean(aligned_pupil_smoothed_30);
pup_norm_10 =(aligned_pupil_smoothed_10-mean(aligned_pupil_smoothed_10))/mean(aligned_pupil_smoothed_10);
pup_norm_unsmoothed =(aligned_pupil_unsmoothed-mean(aligned_pupil_unsmoothed))/mean(aligned_pupil_unsmoothed);


x_abs = abs(x_velocity);
y_abs = abs(y_velocity);

loco_sum = x_abs.^2 +y_abs.^2;
 loco_sum = sqrt(loco_sum);
 
 loco_sum_smooth = smooth(loco_sum,100,'gaussian');

% get index of block transitions 
blockTransitions = [];
     frames=0;
    for i=1:length(framesperblock)
        frames = frames+framesperblock(1,i);
     blockTransitions(i) = frames;
    end
    
    if tf_cont==1 
        which_save_path = save_path;
    else
        if tf_which_cont ==1
            which_save_path = save_path_pass;
        else
            which_save_path = save_path_spont;
        end
    end

save(strcat(which_save_path,'\',mouse,'_', num2str(date),'.mat'),'aligned_pupil_unsmoothed','pup_norm_30','pup_norm_10','pup_norm_unsmoothed','aligned_pupil_smoothed_30','aligned_pupil_smoothed_10','aligned_x_position','aligned_y_position','x_velocity','y_velocity','loco_sum','loco_sum_smooth','blockTransitions','-append');
%pause;





