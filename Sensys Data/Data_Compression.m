clc
tic
home_dir = pwd;
if isunix
    dash = "/";
elseif ispc
    dash = "\";
end
BG_sub = false;
DataPoints = strings(1,7000);
for i = 1:7000
    DataPoints(i) = strcat('DataPoint',num2str(i));
end
space = " ";
Fs = 10e12;
t = 0:1/Fs:6999.99/Fs;
ReadSize = 4000;
folders= GetSubDirsFirstLevelOnly(home_dir);
folders = [folders(3:end) folders(1:2)];
%folders = folders(13:end);
num_folder = length(folders);
fruit_num = 10;
interval = ["9AM" "9PM"];
interval_suffix = ["am", "pm"];
interval_length = length(interval);
Fruits = ["PM" "PR", "MA"];
Fruits_length = length(Fruits);
TP_Matrix = zeros(num_folder,length(interval),length(Fruits),length(fruit_num));

% ignore = ["\media\atsutse\Seagate Portable Drive\Sensys Data\May132023\9AM",...
%  "/media/atsutse/Seagate Portable Drive/Sensys Data/May132023/9AM",...
%  "\media\atsutse/Seagate Portable Drive\Sensys Data\Jun022023\9PM",...
%  "/media/atsutse/Seagate Portable Drive/Sensys Data/Jun022023/9PM"];

ignore = ["E:\Sensys Data\May132023\9AM",...
 "/media/atsutse/Seagate Portable Drive/Sensys Data/May132023/9AM",...
 "E:\Sensys Data\Jun022023\9PM",...
 "/media/atsutse/Seagate Portable Drive/Sensys Data/Jun022023/9PM",...
 ];


for i = 1:num_folder
    for j = 1:interval_length
        curr_dir = string(folders(i));
        day = find_day(curr_dir);
        day_num = find_daye_num(day);
        interval_folder = strcat(home_dir,dash,curr_dir,dash,interval(j));
        if(~ismember(interval_folder,ignore))
            cd(interval_folder);
            Background_str = strcat('Background','_',day_num,'_',interval_suffix(j));
            BG_filename_cvs = strcat(interval_folder,dash,Background_str,space,'wfm.csv');
            if isfile(BG_filename_cvs)

                disp(strcat('Reading',space,Background_str ))
                BG_file = strcat(interval_folder,dash,Background_str);
                BG_data = average_TD(BG_file,DataPoints,ReadSize,t);
                matfilename = strcat(Background_str,'.mat');
                save( matfilename,'BG_data');

                Metal_str = strcat('Metal','_',day_num,'_',interval_suffix(j));
                Metal_data = average_TD(Background_str,DataPoints,ReadSize,t);
                matfilename = strcat(Metal_str,'.mat');
                save( matfilename,'BG_data');
            else
                disp(strcat(BG_filename_cvs,space,'is not available' ))
            end

            for k = 1:Fruits_length
                Fruit = Fruits(k);
                Fruit_folder = strcat(interval_folder,dash,Fruit,dash,'Tag');
                cd(Fruit_folder);
                for q = 1:fruit_num
                      Fruit_filename = strcat(Fruit,num2str(q),'_','T','_',day_num,'_',interval_suffix(j));
                      Fruit_filename_cvs = strcat(Fruit_folder,dash,Fruit_filename,space, 'wfm.csv');
                      if isfile(Fruit_filename_cvs)
                        disp(strcat('Reading',space,Fruit_filename ))
                        F_file = strcat(Fruit_folder,dash,Fruit_filename);
                        Fruit_data = average_TD(F_file,DataPoints,ReadSize,t);
                        matfilename = strcat(F_file,'.mat');
                        save( matfilename,'Fruit_data');
                      else
                          disp(strcat(Fruit_filename,space,'is not available' ))
                      end
                end
            end
        else
            disp(strcat('File', space,interval_folder,space,'was skipped'))
        end
    end
end

cd(home_dir)

toc
%% Helper Function
function [subDirsNames] = GetSubDirsFirstLevelOnly(parentDir)
    % Get a list of all files and folders in this folder.
    files = dir(parentDir);
    % Get a logical vector that tells which is a directory.
    dirFlags = [files.isdir];
    % Extract only those that are directories.
    subDirs = files(dirFlags); % A structure with extra info.
    % Get only the folder names into a cell array.
    subDirsNames = {subDirs(3:end).name};
end

function  data_final = average_TD(data_str,DataPoints,ReadSize,t)    
    warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')
    data_file =  strcat(data_str,' wfm.csv' );   
    ds = tabularTextDatastore(data_file);
    ds.SelectedVariableNames = DataPoints;  
    ds.ReadSize = ReadSize;
    average = 0;
    data_unclipped = zeros(1,length(t));
    while(hasdata(ds))
        tmp = (table2array(read(ds)));
        data_unclipped = data_unclipped  + sum(tmp);  
        average = average + (size(tmp,1));
    end                                                        
    data_unclipped = data_unclipped/average;
    data_unclipped = data_unclipped - mean(data_unclipped);
    %data_final = data_unclipped(tlo_index:thi_index);
    data_final = data_unclipped;
end

function day = find_day(curr_dir)
 date = convertStringsToChars(curr_dir);
 day = date(1:end-4);
end

function day_num = find_daye_num(day)
    month = day(1:3);
    day_suffix = day(4:5);
    if(strcmp(month,'Jun'))
        day_prefix = '06';
    elseif(strcmp(month,'May'))
        day_prefix = '05';    
    end
    day_num = strcat(day_prefix,day_suffix);
end