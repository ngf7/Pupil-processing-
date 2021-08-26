%   Processes AVI file of pupil, fitting circles around pupil ROI,
%   generting artifact corrected frame by frame measurements of pupil area in
%   mm^2 

%   User inputs dataset information into command window
mouse = input('Whats the mouse ID?');
date = input('Date?');
cont = input('Context? If exists type "spont" or "pass"; if not applicable type "none"');
threshold = input('Threshold?'); 
orientation = input('What is the orientation of the camera? "0"(normal)/"180"(rotated)');
unit = input('mm^2 or pix^2? m/p');
alignment = input('Rough or tight alignment? r/t');
km = input('Complete kmeans clustering analysis? y/n');
dilcon= input('Complete dilation/constriction event identificaton? y/n');
%   Threshold is the level used to generate BW pixel image
%       Pixels with luminence > threshold are set to 1(white)
%       Pixels with luminance<threhsold are set to 0(black)
%   Effectively, this translates to:
%      High threshold --> fewer pixels get contained in pupil ROI
%      Low thresold --> more pixels get contained in pupil ROI
%
%   NOTE: Threshold value will need to be tested before runnning code in its
%   entirely so that only those pixels representative of pupil are labeled appropriately labels all
%   pixels of pupil 1 and nothing pixls outside of pupil 0 before running rest
%   of code, may need to be changed across datasets if you notice differences
%   in lightblocking,camera angle, focus, etc.

base_path =strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Noelle Pupil\',mouse,'_',num2str(date),'\burst'); 
base_path_wav=strcat('\\runyan-fs-01\Runyan3\Noelle\wavesurfer\LC\',mouse,'_',num2str(date),'\burst');
%base_path_tseries=strcat('\\runyan-fs-01\Runyan\Christine\images\',mouse,'\',strcat(date),'\pass\');
tot_file_save_path =strcat('\\runyan-fs-01\Runyan3\Noelle\Pupil\Noelle Pupil\processed\',mouse,'\',num2str(date),'\burst'); %this is where final aligned files will be saved, not processed files for individual blocks, those will be saved in the base folder by default
%save_path_pass = strcat('\\runyan-fs-01\Runyan2\Caroline\2P\SOM_VIP\pupil\processed\pass',num2str(date),'\',mouse);
%save_path_spont = strcat('\\runyan-fs-01\Runyan2\Caroline\2P\SOM_VIP\pupil\processed\spont',num2str(date),'\',mouse);

d = dir(strcat(base_path,'\MATLAB_*.avi'));
    cd(base_path);
    
blocks = 1:size(d,1); %each movie within a imaging session date is an separate block

for block =14:16
   
    if block<10
        obj = VideoReader(strcat('MATLAB_000',num2str(block),'.avi')); %reads video file properites
    else
        obj = VideoReader(strcat('MATLAB_00',num2str(block),'.avi'));
    end
    
    NumberOfFrames = obj.NumberOfFrames;
    
    %Create variables 
    the_areas = [];
    raw_radii = [];
    center_row = [];
    center_column = [];
    the_image = read(obj,100);
    rows = size(the_image,1);
    columns = size(the_image,2);
    all_ridx = zeros(1,NumberOfFrames);
    all_cidx = zeros(1,NumberOfFrames);
    
    %Converts image to BW matrix based on threshold 
    for cnt = 1:NumberOfFrames  
        the_image = read(obj,cnt);
        if size(the_image,3)==3
            the_image = rgb2gray(the_image);
        end
        piel = im2bw(the_image,threshold); 
        piel = bwmorph(piel,'open');
        piel = bwareaopen(piel,200);
        piel = imfill(piel,'holes');
        
 % Tagged objects in BW image
        L = bwlabel(piel);
       
        %   You may wish to set some contraints on the location within the
        %   image that pupil ROI can exist in order to minimize cases where
        %   the function identifies an object outside of pupil as pupil.
        %   You can eliminate rows/columns where it is impossible for pupil to occur
        %   (ex along edges of fov). 
        %   Note: this will likely differ across datasets, be sure not to
        %   eliminate locations where pupil has the possibility of appearing. 
       L(1:275,:) = 0; 
       L(:,1:50) =0;
        %L(:,250:end)=0;
       %L(670:end,:) = 0;
        BW1 = edge(L,'Canny'); 
        [row,column] = find(BW1);
        x = vertcat(row',column'); %x is the input indices used to fit the circle
        
  
        
  %looks for gaps in distribution of object locations - if gaps
        %exist, this indicates more than one object was identified. This
        %allows for proper selection fot the pupil as object to fit circle.
   
       TFx = isempty(x); 
        TFcent = isempty(center_row);
      tf_orientation=strcmp('180',orientation);  
      if tf_orientation == 1
        if TFx==1 
            x = []; 
    
        elseif TFx==0 &&  TFcent == 1
             bott=find(x(1,:)>=prctile(x(1,:),80)); %only want to input the top and bottom 20% of x into fitcircles to allow a more accurate circle be fit to frames where pupil is partially occurlied by eyelid
             top=find(x(1,:)<=prctile(x(1,:),20));
             ind = union(bott,top);
             x = x(:,ind);          
            
        else
            %if x is not empty, ROI(s) identified
            %x_sorted_by_row = sortrows(x.',1).';  
            %rowgaps = find(diff(x_sorted_by_row(1,:))>1);
            %x_sorted_by_column = sortrows(x.',2).';
            %colgaps = find(diff(x_sorted_by_column(2,:))>1);
            %if isempty(rowgaps) ==1 && isempty(colgaps) ==1
             %   bott=find(x(1,:)>=prctile(x(1,:),80)); 
              %  top=find(x(1,:)<=prctile(x(1,:),20));
               % ind = union(bott,top);
                %x = x(:,ind);

            %else
                groupID = dbscan(x',5,5);
                groupID = groupID';
                if max(groupID)== 1
                    bott=find(x(1,:)>=prctile(x(1,:),80)); 
                    top=find(x(1,:)<=prctile(x(1,:),20));
                    ind = union(bott,top);
                    x = x(:,ind);
                else
                    row_means = [];
                    col_means = [];
                    for group = 1:max(groupID)
                        row_means = [row_means mean(x(1,groupID == group))];
                    end
                    for group = 1:max(groupID)
                        col_means = [col_means mean(x(2,groupID == group))];
                    end
                    [~,ridx] = min(abs(center_row(cnt-1)-row_means));
                    %all_ridx(cnt) = ridx;
                    [~,cidx] = min(abs(center_column(cnt-1)-col_means));
                    %all_ridx(cnt) = ridx;
                    TFmatch = ridx == cidx;
                    if TFmatch==0
                        %x = x(:,groupID == max(ridx));
                        x = x(:,groupID == 1);
                        all_ridx(cnt) = 1;
                        all_cidx(cnt) = 1;
                        bott = find(x(1,:)>=prctile(x(1,:),80));
                        top = find(x(1,:)<=prctile(x(1,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    else
                        x = x(:,groupID == ridx);
                        all_ridx(cnt) = ridx;
                        all_cidx(cnt) = cidx;
                        bott = find(x(1,:)>=prctile(x(1,:),80));
                        top = find(x(1,:)<=prctile(x(1,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    end
                end
        end
      else
          if TFx==1 
            x = []; 
    
        elseif TFx==0 &&  TFcent == 1
             bott=find(x(2,:)>=prctile(x(2,:),80)); %only want to input the top and bottom 20% of x into fitcircles to allow a more accurate circle be fit to frames where pupil is partially occurlied by eyelid
             top=find(x(2,:)<=prctile(x(2,:),20));
             ind = union(bott,top);
             x = x(:,ind);          
            
        else
            %if x is not empty, ROI(s) identified
            %x_sorted_by_row = sortrows(x.',1).';  
            %rowgaps = find(diff(x_sorted_by_row(1,:))>1);
            %x_sorted_by_column = sortrows(x.',2).';
            %colgaps = find(diff(x_sorted_by_column(2,:))>1);
            %if isempty(rowgaps) ==1 && isempty(colgaps) ==1
             %   bott=find(x(1,:)>=prctile(x(1,:),80)); 
              %  top=find(x(1,:)<=prctile(x(1,:),20));
               % ind = union(bott,top);
                %x = x(:,ind);

            %else
                groupID = dbscan(x',5,5);
                groupID = groupID';
                if max(groupID)== 1
                    bott=find(x(2,:)>=prctile(x(2,:),80)); 
                    top=find(x(2,:)<=prctile(x(2,:),20));
                    ind = union(bott,top);
                    x = x(:,ind);
                else
                    row_means = [];
                    col_means = [];
                    for group = 1:max(groupID)
                        row_means = [row_means mean(x(1,groupID == group))];
                    end
                    for group = 1:max(groupID)
                        col_means = [col_means mean(x(2,groupID == group))];
                    end
                    [~,ridx] = min(abs(center_row(cnt-1)-row_means));
                    %all_ridx(cnt) = ridx;
                    [~,cidx] = min(abs(center_column(cnt-1)-col_means));
                    %all_ridx(cnt) = ridx;
                    TFmatch = ridx == cidx;
                    if TFmatch==0
                        %x = x(:,groupID == max(ridx));
                        x = x(:,groupID == 1);
                        all_ridx(cnt) = 1;
                        all_cidx(cnt) = 1;
                        bott = find(x(2,:)>=prctile(x(2,:),80));
                        top = find(x(2,:)<=prctile(x(2,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    else
                        x = x(:,groupID == ridx);
                        all_ridx(cnt) = ridx;
                        all_cidx(cnt) = cidx;
                        bott = find(x(2,:)>=prctile(x(2,:),80));
                        top = find(x(2,:)<=prctile(x(2,:),20));
                        ind = union(bott,top);
                        x = x(:,ind);
                    end
                end
          end
      end
      
      
      
      
      
      
      try
          [z, r, residual] = fitcircle_mcc(x,'linear');
      catch ME
          z = [];
          r = [];
      end
      
      %how to handle blank frames
      TF = isempty(r);
      if TF == 1
          radius = 0;
          center = zeros(2,1);
      else
          [val,idx] = min(abs(raw_radii(cnt-1)-r));
          radius = r(idx);
          z([1 2]) = z([2 1]);
          center = z;
      end
      
      figure(9)
      clf;
        imshow(the_image)
        viscircles(z',r)
        pause(.01)
        
        raw_radii = [raw_radii radius];
        area = (radius^2)*pi;
        the_areas = [the_areas area];
        center_row = [center_row center(2,1)];
        center_column = [center_column center(1,1)];
    end
    %% 

    first_index = find(raw_radii,1,'first'); %2p acquisition onset
    last_index = find(raw_radii,1,'last'); %2p offset
    the_radii_cut = raw_radii(first_index:last_index);
    center_row_cut = center_column(first_index:last_index);
    center_column_cut = center_column(first_index:last_index);
    %converting pix^2 to mm^2
    tf_unit = strcmp('mm^2', unit);
    if tf_unit ==1
        the_radii = the_radii_cut.*0.00469426267; 
   %Adjust conversion factor according to camera and settings: 
    %Camera on 2P investigator:
        %1024 x 1280 pix res --> conversion factor = 0.00469426267
        %512 x 640 pix res --> conversion factor = 0.00949848
    %Camera on 2P+:
        %1024 x 1280 pix res --> conversion factor = 0.01171303
        %512 x 640 pix res --> conversion factor = 0.02324933
        the_areas = (the_radii.^2).*pi;
        the_areas_compare = (the_radii.^2).*pi;
        blink_threshold = .1;
    else
        the_radii= the_radii_cut;
        the_areas = (the_radii.^2).*pi;
        the_areas_compare = (the_radii.^2).*pi;
        blink_threshold = 2000;
    end
    
    %eliminating blinks
    sampling_rate_in_hz = 10;
    blinks_data_positions = noise_blinks_v3(the_areas,sampling_rate_in_hz,blink_threshold);
       % if isempty(blinks_data_positions{2})==1
        %    blinks_data_positions(2) =[];
        %end
        if isempty(blinks_data_positions);
            fprintf('no blinks \n')
        else
            for i = 1:length(blinks_data_positions)
                the_areas(blinks_data_positions{1,i}) = NaN;
            end
            for i = 2:length(blinks_data_positions)
                if blinks_data_positions{1,i}(1)-blinks_data_positions{1,i-1}(end)<=10
                    the_areas(blinks_data_positions{1,i-1}(end):blinks_data_positions{1,i}(1)) = NaN;
                end
            end
            if isnan(the_areas(1,1))==1
                fr_replacement_ind=find(isnan(the_areas)==0,1,'first');
                fr_replacement_val=the_areas(fr_replacement_ind);
                fr_nan_inds = find(isnan(the_areas),fr_replacement_ind-1,'first');
                the_areas(fr_nan_inds)=fr_replacement_val;
            end
            if isnan(the_areas(1,end))==1
                lt_replacement_ind=find(isnan(the_areas)==0,1,'last');
                lt_replacement_val=the_areas(lt_replacement_ind);
                lt_nan_inds = find(isnan(the_areas),length(the_areas)-lt_replacement_ind,'last');
                the_areas(lt_nan_inds)=lt_replacement_val;
            end
        end
        
        %eliminate measurements outside of physiologically possible range
        %the_areas(the_areas >5) = NaN; 
        %the_areas(the_areas<.05) = NaN;

%interpolate across eliminated artifacts
x = 1:length(the_areas);
y = the_areas;
xi = x(find(~isnan(y)));
yi = y(find(~isnan(y)));

corrected_areas = interp1(xi,yi,x);
%corrected_areas_mm_test = interp1(xi,yi,x);
%figure(91)
%clf
%plot(corrected_areas_mm) 
%hold on 
%plot(corrected_areas_mm_test)
%corrected_areas_mm = interp1(xi,yi,x);

blink_inds=find(isnan(the_areas)==1); 
%the_centers_cut(blink_inds)=NaN;
%a = 1:length(the_centers_cut);
%b = the_centers_cut;
%ai = a(find(~isnan(b)));
%bi = b(find(~isnan(b)));
%corrected_centers = interp1(ai,bi,a); %centers with blinks interpolated 
%corrected_centers(1:20)=corrected_centers(21);


pupil_smoothed10=smooth_median(corrected_areas,10,'gaussian','median');
pupil_smoothed30=smooth_median(corrected_areas,30,'gaussian','median');


figure(1)
clf
plot(corrected_areas)
hold on
plot(the_areas_compare)
%pause


the_areas_compare = (the_radii.^2).*pi;
pupil.center_position.center_column = center_column_cut;
pupil.center_position.center_row = center_row_cut;
pupil.area.corrected_areas=corrected_areas;
pupil.area.uncorrected_areas = the_areas_compare;
pupil.area.smoothed_30_timeframes = pupil_smoothed30;
pupil.area.smoothed_10_timeframes = pupil_smoothed10;
pupil.radii.uncut_uncorrected_radii =  raw_radii;
pupil.radii.cut_uncorrected_radii = the_radii;
pupil.blink = blink_inds;
pupil.galvo_on = first_index; 
pupil.galvo_off = last_index;

if block<10
    save(strcat(mouse,'_000',num2str(block),'.mat'),'pupil');
else
    save(strcat(mouse,'_00',num2str(block),'.mat'),'pupil');
end


%save(strcat(mouse,'_smoothed_000',num2str(block),'_.mat'),'the_areas','the_areas','corrected_areas','center_row_cut','center_row','center_column','center_column_cut','blink_inds','raw_radii','the_radii','pupil_smoothed10','pupil_smoothed30','first_index','last_index');  

pause;
end

keep mouse blocks date cont alignment km dilcon base_path base_path_wav tot_file_save_path save_path_pass save_path_spont ;

position_blocks = (1:12);
cd(base_path)
%   Horizontally concatenates blocks
d = dir(strcat('*.mat'));
for i=position_blocks
    load(d(i).name)
    pupil_all{i} = pupil;
end

if strcmp('tight',alignment)
    make_pupil_aligned_tight(base_path,tot_file_save_path,base_path_wav,mouse,date,blocks,cont,pupil_all);
else
    make_pupil_aligned_rough(base_path,tot_file_save_path,base_path_wav,mouse,date,blocks,cont,save_path_pass,save_path_spont);
end


if ~strcmp('none',cont)
    concatenate_contexts(mouse,date,tot_file_save_path,save_path_pass,save_path_spont);
end


if strcmp('y',km)
    kmeans_pupil_v3(tot_file_save_path,mouse,date)
end

if strcmp('y',dilcon)
    dil_con_events_no_constraints_v2(tot_file_save_path,mouse,date,blockTransitions);
end



    