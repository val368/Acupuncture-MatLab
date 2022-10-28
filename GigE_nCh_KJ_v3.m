% GigE_nCh_KJ.m
% 
% v1 - Now dealing with n-channel
% v3 - adjusting x,y coord of 21x21 boxes further

%% Initialize by clearing all the memory
clear, clc, close all

%% Obtain Experiment Name from the user, and makes a data directory
%
% background mat file has to be in the current directory,
% and all the data files should be saved in the data directory

CurDir = pwd;
CurDate = date;
disp(['The present working directory is ' CurDir])
ExpName = input('Type a new experiment name : ', 's');
DataDir = [CurDate '-' ExpName];
titlename = DataDir;
disp(['Creating a new data directory : ' DataDir])
mkdir(DataDir)

%% Obtain GigE camera information
disp('Wait a bit until camera initializes ...')
gc = gigecamlist;
gc_address = gc.IPAddress;
gc_string = string(gc_address);
g = gigecam(gc_string, 'PixelFormat', 'Mono12');

fps = 10;  % frames per second
g.AcquisitionFrameRateAbs = fps;
g.AcquisitionFrameRateEnable ='True';
g.Width = 128;
g.Height = 128;
%g.OffsetY = 447; - as 2 channels are found to be vertically shifted a lot
g.OffsetY = 405;
g.OffsetX = 570;
g.GainRaw = 3;
g.ExposureTimeAbs = 2000;   % 2ms exposure time

% pixel location
%channel_text = 'bgorsyp';  - old color configuration
channel_text = 'rgbcmyw';
channel_text4xlabel = {};
for i = 1:7
    xtickarray(i) = 14 + (i-1)*23;
    channel_text4xlabel{i} = channel_text(i);
end
% coordinates of upper left corner of each ROI
pixel_location = [  75    35    15    99    69    43    55; % x coord
                    19    95    59    56    94    21    57; % y coord
    ];

%% checking speckle image
h0 = figure;

maxVal = 0;
while true
    test_img = snapshot(g);
    maxVal = max([maxVal max(test_img(:))]);
    colormap("hot");
    imagesc(test_img,[0 maxVal]);
    axis image
    colorbar();
    title("press SPACEBAR to proceed, or Q to quit")
    for i = 1:7
        y1 = pixel_location(2,i);
        y2 = pixel_location(2,i) + 20;
        x1 = pixel_location(1,i);
        x2 = pixel_location(1,i) + 20;
        line([y1,y1],[x1 x2],'color',channel_text(i));
        line([y2,y2],[x1 x2],'color',channel_text(i));
        line([y1,y2],[x1 x1],'color',channel_text(i));
        line([y1,y2],[x2 x2],'color',channel_text(i));
    end
    pause(0.1)
    if h0.CurrentCharacter == 'Q'
        disp('Quitting the program ...')
        %close(h0)
        return;
        break;
    elseif h0.CurrentCharacter == ' '
        break;
    end
end

%% showing sampled images in realtime for double checking
h1 = figure;
int_img = zeros(21,2);

% pre-calculating 9 coordinates for sampling
y = [1 8 15];
x = [1 8 15];
[Y,X] = meshgrid(y,x);
Y_px = reshape(Y, [9 1]);
X_px = reshape(X, [9 1]);

while true
    test_img = snapshot(g);
    col_img = [];
    for i = 1:7
        y1 = pixel_location(2,i);
        y2 = pixel_location(2,i) + 20;
        x1 = pixel_location(1,i);
        x2 = pixel_location(1,i) + 20;
        col_img = [col_img int_img test_img(y1:y2,x1:x2)];        
    end
    imagesc(col_img)
    colormap('hot')
    xticks(xtickarray);
    xticklabels(channel_text4xlabel)
    yticklabels({})
    axis image
    colorbar();
    title("press SPACEBAR to proceed, or Q to quit")

    pause(0.1)
    if h1.CurrentCharacter == 'Q'
        disp('Quitting the program ...')
        close(h1)
        return
        break;
    elseif h1.CurrentCharacter == ' '
        break;
    end
end

%% Set up channl plot and calcuation for plot range
ch = 'rgbcmy';
ch_len = length(ch);
ch_num = zeros(1,ch_len);
for i = 1:ch_len
    ch_num(i) = strfind(channel_text,ch(i));
end

totalTime_in_min = input('How many minutes do you want to acquire data for? ');
totalTime_in_sec = totalTime_in_min*60;
totalframe = totalTime_in_sec*fps;

%% Set up variable for BFI calculation
final_BFI = zeros(7,totalframe,'double');
final_BFI_std = zeros(7,totalframe,'double');

%background_array = zeros(128,128,'double');   % shouldn't be initialized
if isfile('background_array_128.mat')
    load('background_array_128.mat');
else
    disp('No background image detected. Proceeding without one.')
end

for i = 1:ch_len
    img_array{i} = zeros(21,21,totalframe);
end

%% main loop

tic

h2 = figure;
axis([0 totalTime_in_sec 0 80])
xlabel("time (sec)","FontSize",12)
ylabel("BFI (AU)","FontSize",12)
title(titlename,"FontSize",16)
hold on


for j = 1:totalframe
    img = snapshot(g);
    while 1      % wait until img is read from the camera
        if ~isempty(img)
            break
        else
            continue
        end
    end
    img = cast(img,'double'); % change data type because img of initial condiditon is uint16
    %img = img - background_array; % - let's bypass bg subtraction for now

    for i = 1:ch_len    % BFI calculation for selected channels
        y1 = pixel_location(1,ch_num(i));
        y2 = pixel_location(1,ch_num(i)) + 20;
        x1 = pixel_location(2,ch_num(i));
        x2 = pixel_location(2,ch_num(i)) + 20;
        samp_img = img(y1:y2,x1:x2);
        img_array{i}(:,:,j) = samp_img;

        BFI_box = zeros(9,1);
        for co = 1 : 9
            MEAN = mean(samp_img(Y_px(co):Y_px(co)+6,X_px(co):X_px(co)+6),"all");
            STD = std(samp_img(Y_px(co):Y_px(co)+6,X_px(co):X_px(co)+6),1,'all');
            K = STD/MEAN;
            BFI_box(co) = 1/K^2;
        end

        BFI_box_mean = mean(BFI_box);
        BFI_box_std = std(BFI_box);

        final_BFI(i,j) = BFI_box_mean;
        final_BFI_std(i,j)= BFI_box_std;

    if rem(j,5) == 0
        errorbar(j/fps,BFI_box_mean,BFI_box_std,'color',ch(i));
        %plot(j/fps,BFI_box_mean,'.','Color',ch(label))
        %plot(j,median_location(1,:),ch(label),'LineWidth',3);
        hold on

    end
    end

end

total_time = toc
eachtime = toc/totalframe
framerate = 1/eachtime
%% selection for used channel

final_BFI_used = final_BFI';

filename_BFI = strcat('\',DataDir,'-BFIdata');
filename_csv = strcat(filename_BFI,'.csv');
filename_png = strcat(filename_BFI,'.png');
filename_img = strcat('\',DataDir,'-image');
filename_name = strcat('\',DataDir,'mean and std');
save([DataDir filename_BFI],'final_BFI_used');
save([DataDir filename_img],'img_array');
saveas(gcf,[DataDir filename_png])
writematrix(final_BFI_used,[DataDir filename_csv])