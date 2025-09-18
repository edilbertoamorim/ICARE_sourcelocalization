function [time_passed_since_cardiac_arrest_in_samples] = get_time_passed_since_cardiac_arrest_in_samples_all_eegs(pt_id,spreadsheet_with_cardiac_arrest_time_filepath,updated_patient_data_table,mat_file_path)
% OUTPUTS THE TIME ELAPSED IN SECONDS BETWEEN ALL EEGS AFTER
% CARDIAC ARREST AND THE CARDIAC ARREST

pt_id = remove_underscores(pt_id);
[num,txt,raw] = xlsread(spreadsheet_with_cardiac_arrest_time_filepath);
importfile = raw;

for i=1:size(importfile,2)
    currentcell = importfile{1,i};
    found_id = strfind(currentcell,'sid');
    found_datearrest = strfind(currentcell,'dateArrest');
    if found_id == 1
        id_column = i;
    end
    if found_datearrest == 1
        arrest_column = i;
    end
end

arrest_date = [];
index_pt_id_importfile = find(strcmp(importfile(:,1),pt_id));
if ~isempty(index_pt_id_importfile)
    arrest_date = importfile(index_pt_id_importfile,arrest_column);
    formatIn = 'mm/dd/yyyy HH:MM:SS AM';
end

if isempty(arrest_date)
    load(updated_patient_data_table,'patient_data_table');
    index_pt_id = find(strcmp(patient_data_table(:,2),pt_id));
    if ~isempty(index_pt_id)
        arrest_date = patient_data_table{index_pt_id,26};
        formatIn = 'dd-mmm-yyyy HH:MM:SS';
    end
end

if isempty(arrest_date) == 1
    time_passed_since_cardiac_arrest_in_samples = [];
    return
end
    
arrest_vec = datevec(arrest_date,formatIn);

[EEG_timestamps] = EEG_times(pt_id,mat_file_path);


% [earliest_eeg_start_time] = get_earliest_eeg_start_time(pt_id,mat_file_path);

EEG_start_times = EEG_timestamps.start;

EEG_files_to_exclude = [];
time_elapsed_values = [];
for j=1:size(EEG_start_times,1)
    time_elapsed = etime(EEG_start_times(j,:),arrest_vec);
%     if time_elapsed < 0
%         EEG_files_to_exclude = vertcat(EEG_files_to_exclude,j);
%         disp('EEG start time was before the time of cardiac arrest. The EEG of the patient occurred before the cardiac arrest. Therefore, this patient will be excluded.')
%     end
    time_elapsed_values = vertcat(time_elapsed_values,time_elapsed);
end
% time_elapsed_values(time_elapsed_values<0)=[];
time_elapsed_seconds = time_elapsed_values;
% time_elapsed_seconds = min(time_elapsed_values); %gets the EEG closest to the cardiac arrest time

time_elapsed_samples = time_elapsed_seconds * 200;
time_passed_since_cardiac_arrest_in_samples = time_elapsed_samples;




end
    
%     
% eeg_start_vec = earliest_eeg_start_time;
% time_elapsed_seconds = etime(arrest_vec,eeg_start_vec);
% % time_elapsed_seconds = abs(time_elapsed_seconds);
% time_elapsed_samples = time_elapsed_seconds * 200;
% time_passed_since_cardiac_arrest_in_samples = time_elapsed_samples;

% if isempty(time_passed_since_cardiac_arrest_in_samples) == 1
%     
%     load(updated_patient_data_table,'patient_data_table')
%     index_pt_id = find(strcmp(patient_data_table(:,2),pt_id))
%     cardiac_arrest_date = patient_data_table(index_pt_id,26)
%     
%     
%     arrest_vec = datevec(cardiac_arrest_date,formatIn);
%     [earliest_eeg_start_time] = get_earliest_eeg_start_time(pt_id,mat_file_path);
%     eeg_start_vec = earliest_eeg_start_time;
%     time_elapsed_seconds = etime(arrest_vec,eeg_start_vec);
%     time_elapsed_seconds = abs(time_elapsed_seconds);
%     time_elapsed_samples = time_elapsed_seconds * 200;
%     time_passed_since_cardiac_arrest_in_samples = time_elapsed_samples;
% end
    
