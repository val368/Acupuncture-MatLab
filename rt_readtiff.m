% RT_READTIFF.M
%
% Basler realtime tiff reader
% make sure the data directory doesn't have any previous tiff data
% before starting the acquisition

clear all
clc

DataDir = 'C:\Users\Kijoon\Desktop\0906\';

%% acquire header of tiff filenames

while 1
    fn0 = dir([DataDir '*0000.tiff']);
    if size(fn0,1)
        Header = extractBefore(fn0.name,'0000');
        break;
    else
        pause(0.001)
    end
end
disp('tiff file detected. Starting the main loop ...')

%% main loop

N = 20; % total number of frames

for i = 0:N-1
    str4 = sprintf('%04.0f',i);
    filename = [Header str4 '.tiff'];

    while 1
        if isfile([DataDir filename])
            disp(filename)
            break
        else
            pause(0.001);
        end
    end
end
