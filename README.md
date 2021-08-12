# Pupil-processing
Code for intial processing of pupil movies of rodents with optional, possibly useful analysis of processing output, implemented in MATLAB. Works for grayscale and RGB .avis. Exmaple movies to test the code and its capabilities can be found here. 

# Data acquisition info - good practices to ensure optimal and reliable processing

# How to use
NOTE: This code is compatible with MATLAB 2015 and later

Getting started
1. Download the repository to a single overhead directory
2. Make sure overhead directory and all subdirectories are added to your current MATLAB path 
3. Open 'forfitcircles.m' and edit variables related to base_path, base_path_wav, base_path_tseries, tot_file_save_path, save_path_pass, save_path_spont
base_path: the path where your unprocessed AVIs for dataset are saved
base_path_wav: the path where your wavesurfer files for dataset are saved
base_path_tseries: (optional) this will only be used by the code if you choose to do rough alignment rather than tight. The path where your tseries .tiff files for dataset are saved
tot_file_save_path: the location you would like final output file of processing to be saved. If you have context set to anything other than 'none' this is where the data for all contexts concatenated will be saved
save_path_pass: (optional) this will only be used if you input a context type other than 'none'. This is the location where the final output file for the passive context only will be saved
save_path_spont: (optional) this will only be used if you input a context tupe other than 'none'. This is the location nwhere the final output file for the spontaneous context only will be saved
NOTE: in these path names you should replace mouse ID in path name with mouse variable, date with date  variable and information about conext with cont variable, these will be variables you input once code is run

Once all paths have been properly edited to suit your data, you may run code with command 'forforcirles' or by hitting the RUN button in the Editing toolbar

In the command line you will be prompted to input:

Mouse ID: The name of the mosue exactly as it appears in your paths 

Date: Date of imaging session, exactly as it appears in your paths

Context: The experimental context of the data you are processing. If you data does not multiple contexts you would like to separate, set this variable to 'none'. Otherwise, input the current context 'pass' for passive or 'spont' for spontaneous.

Threshold: Threshold is the level used to generate BW pixel image. This code will turn each frame of your movie into a binary matrix of 0s and 1s related to each pixel's intesesity, and the assignment of 0 or 1 to each pixel is detemined by the set threshold value. We want pixels part of the pupil ROI to be set to 1 and all other pixels to be set to 0. So in simpler terms, the threshold is the unique value set to dictate which pixels will be included as part of the pupil ROI or excluded. 
                    Pixels with luminence > threshold value are set to 1 (white)
                    Pixels with luminance < threhsold value are set to 0 (black)
                    
                    Therefore:
                    Higher threshold value --> fewer pixels get contained in pupil ROI
                    Lower thresold value --> more pixels get contained in pupil ROI
             You must test out different thresholds to find the value that works best for you data


Orientation:The orienation of the camera. If the camer is upright and pupil displays in natural orienation set this value to '0' (as it is on 2p+), if camera is rotated 180 degrees and the pupil displays rotated from its natrual orientation, set this value to '180'( as it is on 2P investigator). This is important because a circle is fit to the pupil by using only the 20% rightmost pixels and 20% leftmost pixels - this produces an accurately fit cirlce to frames where the mouse's eye is partially close and the eyelid covers top and bottom regions of the pupil (insert an image here for ease of understanding)

Unit: The units in which pupil area output will be given. Inputting 'm' will convert output to mm^2 (this is recommended if data was collected using investigator rig, coversion has been verified for this camera). Input of 'p' will keep the output in pix^2 (this is recommened if data was collected using 2p+, at the moment there is not a consistent conversion factor verified for this camera due to its adjustable zoom).

Alignment: The method for aligning pupil movies to all other simultaneous recordings (ie. 2P imaging, running signal, stimulus, etc). Input of 'r' means rought alighment will be executed. Rough alighment will rely on tseries .tiff files to count number of frames present in each imaging block and stretch/upsample the pupil signal in order to match this number. For recordings without wavesurfer recorded pupil camera signal this is the onyl option for alignment, however this is not the preferred option if tight alignment can be done, since this relies on the assumption that the camera frame rate is realiable and consistent.

km: Should kmeans clustering analysis be completed? This function will cluster the normalized pupil data into 3 clusters: high arousal, low arousal and transition state periods. Inputting 'y' will run this function and save all relevant variables into the file within tot_file_save_path. Inputting 'n' will skip running this function.

dilcon: should dilation/constriction detection analysis be completed? This function will . without constraint, constraints may be added to eliminate dilation/constriction events of small magnitudes or ones that occur within a larger event of interest. Inputting 'y' will run this function and save all relevant variables into the file within tot_file_save_path. Inputting 'n' will skip running this function.



Once all of these prompted inputs have been entered the code should run until completion.


# Output of processing
Individual files for each block will be saved in the base_path folder. Each file will contain the following:
- pupil: structure contating all pupil related fields below
          - center_position: sub-struct containing variable related to the pupil's position in the field of view
                    - center_column: column vector containing column index where center of pupil is located. if your movie is not rotated this is analogous to x position, if movie                        is rotated 180 degrees this is analogous to y position 
                    - center_row: vector containing row index where center of pupil is located.if your movie is not rotated this is analogous to y position, if movie                                     is rotated 180 degrees this is analogous to x position 
          -  area: sub-struct containing variables related to the pupil area (note: all of these variables have been cut to only frames where 2P imaging is occurring)
                    - corrected_areas: column vector of pupil areas after artifact correction (elimination of blink frames, saccades, physiologically impossible values and 
                    - uncorrected_areas: column vecort of pupil areas without artifact correction
                    - smoothed_30_timeframes:pupil areas after artifact correction gaussian smoothed over 30 frames
                    - smoothed_10_timeframes: pupil area for each frame after artifact correction and smoothed by gaussian curve over 10 frames
          - radii: sub-struct containing variables realted to the pupil radius for each frame (if conversion to area is not desired - could maybe add a blink corrected radii                          vector so that ppl wouldnt need to do this themselves
                    - uncut_uncorrected_radii: vector containing pupil radius measurement for each frame, not artifact corrected, not cut to galvo
                    - cut_uncorrected_radii: vector containing pupil radius measurement for each frame, not artifact corrected, cut to galvo
          - blink: vector containing the indices of frames where pupil measurement is inaccurate due to a blink
          - galvo_on: the frame of pupil movie where 2P imaging starts (the relative first frame of vectors that have been cut to galvo)
          - galvo_off: the frame of pupil movie where 2P imaging ends (the relative last frame of vectors that have been cut to galvo)
  
 
 if you have different contexts and choose to save the indiviual contexts individually you will see files in tehs save paths for respective context with pupil these variabls:
 list all the alignedmnet variabes from below so tah tyou can say in the final you will see all the same variables from above but now they are contatenated across contexts (or not if you did not input existence of contexts)... if you choose to do kmeans clustereing the following variabels will also be present... if you opt to do dilcon the following variabels will alos be present 
 
Final file saved to tot_file_save_path
- pupil_all: cell array where each cell is the pupil struct from an individual block (see above to definition of variables with individual structures but with addition of fields below 
          - alignement:
                     - matched fraesm ..
          - velocity:
                    - matched loco ...
              
- aligned_pupil_unsmoothed
- aligned_pupil_smoothed_10
- aligned_pupil_smoothed_30
- aligned_pupil_x_position
- aligned_pupil_y_position
- Cpts
- Dpts
- C
- cluster1
- cluster2
- classification 
- 
                
