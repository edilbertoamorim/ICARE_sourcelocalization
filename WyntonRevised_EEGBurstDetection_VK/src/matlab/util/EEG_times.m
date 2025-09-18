function [EEG_times] = EEG_times(patient_id,mat_file_path)

% input example:  EEG_indices('mgh112','C:\Users\Shawn\Desktop\Research\EDF_Files\Output\eeglab')
% EEG_lengths - returns all EEG indices for given patient id

folders = dir(mat_file_path);
folders = folders(~ismember({folders.name},{'.','..'}));

hidden_folders = [];
for i=1:length(folders)
    if isequal(folders(i).name(1),'.') == 1
        hidden_folders = vertcat(hidden_folders,i);
    end
end

folders(hidden_folders) = [];
        
names_folders = {folders.name};

patient_files = [];
patient_file_paths = [];

for i=1:length(names_folders)
    
    current_folder = names_folders{i};
    files = dir(strcat(mat_file_path,'\',current_folder));
    files = files(~ismember({files.name},{'.','..'}));
    
    hidden_files = [];
    for i=1:length(files)
        if isequal(files(i).name(1),'.') == 1
            hidden_files = vertcat(hidden_files,i);
        end
    end
    files(hidden_files) = [];
    names_files = {files.name};
    for j=1:length(names_files)
        current_file = names_files{j};
        current_file_path = strcat(mat_file_path,'\',current_folder,'\',current_file);
        find_patient_id = strfind(current_file,strcat(patient_id,'_'));
        if isempty(find_patient_id) == 0
            patient_files = [patient_files {current_file}];
            patient_file_paths = [patient_file_paths {current_file_path}];
        end
    end
end

patient_files = sort_nat(patient_files);
patient_file_paths = sort_nat(patient_file_paths);

% earliest_file = patient_files(1)
% underlineLocations = find(earliest_file == '_')
% 
% earliest_datetime = earliest_file[underlineLocations(2)+1:length(earliest_file)-4]
% 
% formatIn = 'yyyymmdd_HHMMSS'
% earliest_datenumber = datenum(earliest_datetime,formatIn)
% earliest_datestring = datestr(earliest_datenumber)
% disp(earliest_datestring)
start_end_EEG_files_datevec = struct;
start_datevecs = [];
end_datevecs = [];
for i=1:length(patient_files)
    current_file = patient_files{i};
    underscore_locations = find(current_file == '_');
    character_before_first_underscore = current_file(underscore_locations(1)-1);
%     if isempty(str2num(character_before_first_underscore)) == 0
%         start_datetime = current_file(underscore_locations(1)+1:underscore_locations(3)-1)
%     end
%     if isempty(str2num(character_before_first_underscore)) == 1
        for j=1:length(underscore_locations)
            if j+1 < length(underscore_locations)
                if (underscore_locations(j+1)-underscore_locations(j))>7
                    start_datetime = current_file(underscore_locations(j)+1:underscore_locations(j+2)-1);
                end
            end
%         end
        end
    
    formatIn = 'yyyymmdd_HHMMSS';
    start_datevec = datevec(start_datetime,formatIn);
    start_datenum = datenum(start_datetime,formatIn);
    
%     date_of_file = current_file(1:underlineLocations(2)-1)
%     [filepath,name,ext] = fileparts(current_file)
%     
%     mat_file_path_complete = strcat(mat_file_path,'\',date_of_file,'\',name,'_eeglab.mat')
%     
    mat_file_path_file = patient_file_paths{i};
    
    load(mat_file_path_file,'eeg_eeglab_unprocessed');
    number_of_EEG_recording_samples = size(eeg_eeglab_unprocessed.data,2);
%     [hdr,record] = edfread(strcat(mat_file_path,'\',current_file))
%     number_of_EEG_recording_samples = size(record,2)
%     keyboard %input number_of_EEG_recording_samples = 863232
    milliseconds_length_of_EEG = (number_of_EEG_recording_samples / 200)*1000; %200 samples/sec * 1000 milliseconds
    duration_milliseconds_length_of_EEG = milliseconds_length_of_EEG;
    
    end_datenum = addtodate(start_datenum,duration_milliseconds_length_of_EEG,'millisecond');
    end_datevec = datevec(end_datenum);
    
    start_datevecs = vertcat(start_datevecs,start_datevec) ;
    end_datevecs = vertcat(end_datevecs,end_datevec) ;
end
start_end_EEG_files_datevec.start = start_datevecs;
start_end_EEG_files_datevec.end = end_datevecs;
% earliest_datevec = start_end_EEG_files_datevec{1,1};
% for i=1:size(start_end_EEG_files_datevec,1)
%     for j=1:size(start_end_EEG_files_datevec,2)
%         time_elapsed_since_EEG_start = etime(start_end_EEG_files_datevec{i,j},earliest_datevec);
%         start_end_EEG_files_datevec{i,j} = time_elapsed_since_EEG_start;
%     end
% end

% start_end_EEG_files_datevec = cell2mat(start_end_EEG_files_datevec);
EEG_times = start_end_EEG_files_datevec;
end

