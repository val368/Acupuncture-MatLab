% postprocess_KJ.m

% Automatically visit all the data directories
% and generate .csv data file
% and generate a table that contains mean and std information

% coded by KJ on Oct 7, 2022

clear all

dirinfo = dir;
N = size(dirinfo,1); % get the number of files and folders in this folder
datestr = '19-Oct-2022';  % Change this date appropriately

% starts the loop from i=3 as first two directories are always . and ..
outputCell = {'Filename','Mean','Std'};
for i = 3:N
    if dirinfo(i).isdir
        if strfind(dirinfo(i).name, datestr) % see if dir name contains datestr
            s = what(dirinfo(i).name);
            str = [dirinfo(i).name '/' s.mat{1}];
            disp(['processing ' str ' ...'])
            load(str)
            if exist('final_BFI_used')
                tempCell{1,1} = s.mat{1};
                tempCell{1,2} = mean(final_BFI_used);
                tempCell{1,3} = std(final_BFI_used);
                outputCell = [outputCell; tempCell];
                clear final_BFI_used
            end
        end
    end
end
writecell(outputCell,'mean and std.csv')

