function [aligned_pupil_unsmoothed,framesperblock] = make_pupil_aligned_tseries(mouse,year,day,cont,pupil_full)
%tf=strcmp('pass',cont);
%[framesperblockpass framesperblockspont]=findframes_nf(base_path_tseries);
[framesperblock]=findframes_nf(base_path_tseries);


% if tf==1 
%     framesperblock=framesperblockpass;
% else
%     framesperblock=framesperblockspont;
% end

%horizontally cat frames per block

totframes=sum(framesperblock);

aligned_pupil_unsmoothed=imresize(pupil_full,[1,totframes]);





