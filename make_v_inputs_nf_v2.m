function [x_velocity,y_velocity]=make_v_inputs_nf_v2(base_path_wav,blocks)
% tf=strcmp('pass',cont); %logical operation asking if the context is passive
% if tf==1
%     cd(strcat('\\runyan-fs-01\Runyan\Christine\passive listening\',num2str(mouse),'\2020',num2str(day)));
% else 
%     cd(strcat('\\runyan-fs-01\Runyan\Christine\spontaneous activity\wavesurfer\',num2str(mouse),'\2020',num2str(day)));
% end
cd(base_path_wav)

z=dir('*.h5');

for block=blocks %going through all blocks

%mouse=num2str(mouse);

%reading the wavesurfer file
if block<10
    for i=1:length(z)
        if  contains(z(i).name,strcat('_000',num2str(block),'.h5'))==1
            hh=h5read(z(i).name,strcat('/sweep_000',num2str(block),'/analogScans'));
        end
    end
else
    for i=1:length(z)
        if contains(z(i).name,strcat('_00',num2str(block),'.h5'))==1
           hh=h5read(z(i).name,strcat('/sweep_00',num2str(block),'/analogScans'));
        end
    end
end


         
    hh=hh';
    hh=double(hh);
    rawFrame=hh(1,:);
    f=zeros(1,length(rawFrame));
    frame=0;
    for i=2:length(rawFrame)-2
        local=(rawFrame(i-1:i+1));
        m=max(local);
        if rawFrame(i)<3000&&rawFrame(i)==m
            if (rawFrame(i)-rawFrame(i+1))>=2500||(rawFrame(i)-rawFrame(i+2))>=2500
                frame=frame+1;
            end
        end
        f(i)=frame;
    end
    frames{block}=f;
    velocity=calculate_velocity_nf_direct(hh);
    v{block}=velocity';
    %v{block}(1,:)=smooth(v{block}(1,:),500,'gaussian');
    %v{block}(2,:)=smooth(v{block}(2,:),500,'gaussian');
    
count=0;
    for i=2:length(v{block})
        if frames{block}(i)>=2&&frames{block}(i)>frames{block}(i-1)
    %         count
            xv{block}(frames{block}(i-1))=xv{block}(frames{block}(i-1))/count;
            yv{block}(frames{block}(i-1))=yv{block}(frames{block}(i-1))/count;
            count=1;
            xv{block}(frames{block}(i))=v{block}(1,i);
            yv{block}(frames{block}(i))=v{block}(2,i);
        elseif frames{block}(i)==1&&frames{block}(i)~=frames{block}(i-1)
            count=1;
            xv{block}(frames{block}(i))=v{block}(1,i);
            yv{block}(frames{block}(i))=v{block}(2,i);


        elseif frames{block}(i)>=1&&frames{block}(i)==frames{block}(i-1)
            count=count+1;
            xv{block}(frames{block}(i))=xv{block}(frames{block}(i))+v{block}(1,i);
            yv{block}(frames{block}(i))=yv{block}(frames{block}(i))+v{block}(2,i);
        end
    end
 
 
end
ind=blocks(1);
if frames{ind}<12000
    x_velocity=xv{ind}(1:max(frames{ind}));
    y_velocity=yv{ind}(1:max(frames{ind}));
else 
x_velocity=xv{ind}(1:round(max(max(frames{1})),-2));
y_velocity=yv{ind}(1:round(max(max(frames{1})),-2));
end

% for b=blocks(2:end)
%     if round(max(max(frames{b})),-2)>length(xv{b})
%         x_velocity=cat(2,x_velocity,xv{b}(1:max(frames{b})));
%         y_velocity=cat(2,y_velocity,yv{b}(1:max(frames{b})));
%     else
%         x_velocity=cat(2,x_velocity,xv{b}(1:round(max(max(frames{b})),-2)));
%         y_velocity=cat(2,y_velocity,yv{b}(1:round(max(max(frames{b})),-2)));
%     end
% end


%alt way of doing it
for b=blocks(2:end)
    if round(max(max(frames{b})),-2)==12000
        x_velocity=cat(2,x_velocity,xv{b}(1:round(max(max(frames{b})),-2)));
        y_velocity=cat(2,y_velocity,yv{b}(1:round(max(max(frames{b})),-2)));
    else
        x_velocity=cat(2,x_velocity,xv{b}(1:max(frames{b})));
        y_velocity=cat(2,y_velocity,yv{b}(1:max(frames{b})));
    end
end





