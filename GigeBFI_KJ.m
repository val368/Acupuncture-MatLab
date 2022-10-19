%% Initialize by clearing all the memory
clear, clc, close all

%% Obtain Experiment Name from the user, and makes a data directory
%
% background mat file has to be in the current directory,
% and all the data files should be saved in the data directory
%
% ex) save([DataDir '\filename'], 'fulltrans')

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

%% Setting GigE camera
g.AcquisitionFrameRateAbs = 10;
g.AcquisitionFrameRateEnable ='True';
g.Width = 128;
g.Height = 128;
g.OffsetY = 447;
g.OffsetX = 570;
g.GainRaw = 3;
g.ExposureTimeAbs = 2000;   % 2ms exposure time

%% checking speckle image
f = figure;

maxVal = 0;
while true

    % put your loop code here
    test_img = snapshot(g);
    maxVal = max([maxVal max(test_img(:))]);
    colormap("hot");
    imagesc(test_img,[0 maxVal]);
    colorbar();
    title("press any key to stop the image")
    pause(0.01)
    if f.CurrentCharacter > 0
        close(f)
        break;
    end
end

%% Set up channl plot and calcuation for plot range
channel_num = 1;
totalTime_in_min = input('How many minutes do you want to acquire data for? ');
totalframe = totalTime_in_min*600;
frameline = 0:300:totalframe;
timeline = frameline/10;
stringframe = string(timeline);
number_box = zeros(1,totalframe);


%% pixel location
%                    b     g     o     r     s     y     p
pixel_location = [  75    35    15    99    79    33    55;
                    95    55    35   119    99    53    75;
                    19    95    59    56    94    21    57;
                    39   115    79    76   114    41    77;    ];

%% Set up variable for BFI calculation
frame_label = zeros(1,totalframe,'double');
final_BFI = zeros(7,totalframe,'double');
final_BFI_std = zeros(7,totalframe,'double');

%background_array = zeros(128,128,'double');   % shouldn't be initialized
load('background_array_128.mat');

baseline_array = zeros(128,128,'double');
frame_array = zeros(128,128,'double');
BSsumimage = zeros(128,128,'double');
final_BFI_used = zeros(3,totalframe,'double');
mean_bfi = [];
median_location = [];
img_array = zeros(128,128,totalframe);

%% make array for BFI value plot
for i = 1:totalframe
    number_box(1,i) = fix(i/10);

end

%% main loop

N = totalframe; % total number of frames
tic
for j = 1:N
    img = snapshot(g);
    frame_label(1,j) = j;
    while 1      % wait until img is read from the camera
        if ~isempty(img)
            break
        else
            continue
        end
    end
    img = cast(img,'double'); % change data type because img of initial condiditon is uint16
    img = img - background_array;
    img_array(:,:,j) = img;

    for label = 1 : 7     % BFI calculation for all 7 channels
        BFI_box = zeros(9,1);

        for count = 1 : 9
            y = pixel_location(1,label) : 7 : pixel_location(1,label) + 20;
            x = pixel_location(3,label) : 7 : pixel_location(3,label) + 20;
            [Y,X] = meshgrid(y,x);
            y_n = numel(Y);
            X_m = numel(X);
            Y_pixel = reshape(Y, [y_n ,1]);
            X_pixel = reshape(X, [X_m ,1]);
            MEAN = mean(img(Y_pixel(count):Y_pixel(count)+6,X_pixel(count):X_pixel(count)+6),"all");
            STD = std(img(Y_pixel(count):Y_pixel(count)+6,X_pixel(count):X_pixel(count)+6),1,'all');
            K = STD/MEAN;
            BFI = 1/(K)^2;
            BFI_box(count,1) = BFI;
        end

        BFI_box_mean = mean(BFI_box(:,1));
        BFI_box_std = std(BFI_box(:,1));

        final_BFI(label,j) = BFI_box_mean;
        final_BFI_std(label,j)= BFI_box_std;
    end

    if rem(j,10) == 0
        mean_bfi = [mean_bfi median(j-9:j,'all')];
        median_location = [median_location mean(final_BFI(1,j-9:j),'all')];
        hold on

        plot(frame_label,final_BFI(1,:),'.','Color','#0000FF')
        plot(mean_bfi(1,:),median_location(1,:),'r','LineWidth',3);
        xlabel("time (sec)","FontSize",12)
        ylabel("BFI (AU)","FontSize",12)
        xticks(frameline)
        xticklabels(stringframe)
        title(titlename,"FontSize",16)
        axis([-100 (totalframe+100) 0 max(final_BFI(1,:))+ max(final_BFI(1,:))*0.2])
    end

end


total_time = toc
eachtime = toc/totalframe
framerate = 1/eachtime
%% selection for used channel

final_BFI_used(1,:) = final_BFI(1,:)';
%final_BFI_used = transpose(final_BFI_used); % very bad example of coding
bfi_mean = mean(final_BFI_used,"all");
bfi_std = std(final_BFI_used,1,"all");
bfi_box_set = [DataDir,bfi_mean,bfi_std];

%% test : saving a variable in the Data Directory
% DataDir_2 = 'C:\Users\LENOVO\Desktop\10월\1010\datasum';
filename_BFI = strcat('\',DataDir,'-BFIdata');
filename_csv = strcat(filename_BFI,'.csv');
filename_png = strcat(filename_BFI,'.png');
filename_img = strcat('\',DataDir,'-image');
filename_name = strcat('\',DataDir,'mean and std');
save([DataDir filename_BFI],'final_BFI_used');
save([DataDir filename_img],'img_array');
saveas(gcf,[DataDir filename_png])
writematrix(final_BFI_used,[DataDir filename_csv])