

% Basler realtime tiff reader
% make sure the data directory is empty before acquisition


clear all
clc

DataDir = 'C:\Users\Kijoon\Desktop\0906\';

%% acquire header of tiff filenames

fn0 = dir([DataDir '*0000.tiff']);
Header = extractBefore(fn0.name,'0000');

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
