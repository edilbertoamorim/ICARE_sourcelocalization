function [similarities_cell, filtered_burst_ranges_cell, similarities_matrix, bs_ranges, srate, burst_ranges, burst_data_obj, cardiac_arrest_present,selected_sorted_all_episodes_data,distance_of_episode_from_target] = pipeline_up_to_similarity_all_bursts(pt_id,patient_files, similarity_fn, use_saved_detect_bs_output, save_detect_bs_output,bursts_to_analyze,units)
% ASSUMES SAMPLE RATE 200

%PIPELINE_UP_TO_SIMILARITY - Runs entire pipeline up to and including similarity
%
% Input:
%     file_path - path to edf to run pipeline on
%     similarity_fn - "dtw" or "xcorr" - name of similarity function to use when
%         computing similarity
%     use_saved_detect_bs_output - boolean. if true and saved results exist
%           for the detect_bs portion of the pipeline, loads and uses the saved results
%           rather than recomputing them.
%     save_detect_bs_output - boolean. if true, saves any newly computed
%           detect_bs results to the 'describe_bs' subdirectory of the 'output_dir'
%           defined in Config.m
%
% Output
%     similarities_cell, filtered_burst_ranges_cell - output of simlarity.m
%           Note: if no burst suppression episodes, similarities_cell is
%           empty
%     bs_ranges, burst_ranges_cell - output of detect_bs.m
%     srate - sample rate used during calculations
%     burst_data_obj - if pipeline was actually run, the matrix of eeg data
%         if results were loaded, the episode_bursts_cell as returned by load_detect_bs.m

if nargin < 3
    use_saved_detect_bs_output = 1;
end
if nargin < 4
    save_detect_bs_output = 1;
end

episode_bursts_cell = [];
bs_ranges = [];
burst_ranges_cell = [];
srate =200;
burst_data_obj = [];

ptDataTablePath = Config.get_configs('patient_data_table');
output_normal_dir = Config.get_configs('output_dir');
ptDataTable = readtable(ptDataTablePath);

currentPtRow = find(strcmpi(ptDataTable.pat_deid,pt_id));
currentPtArrest2EEGSeconds = ptDataTable.time_of_CA_to_EEG_sec(currentPtRow);

%This is to correct for if pt not found
if isempty(currentPtArrest2EEGSeconds)
    currentPtArrest2EEGSeconds = 0;
end

cardiac_arrest_present = 1;

target_sample_after_cardiac_arrest = 24*60*60*srate;

patient_files = sort_nat(patient_files);

[~,EEGStartFile,~] = fileparts(patient_files{1});
pieces = strsplit(EEGStartFile,'_');
EEGStartDate = strcat(pieces{2},pieces{3});
EEGStartDatetime = datetime(EEGStartDate,'InputFormat','yyyyMMddHHmmss');

all_data_from_EEGs = [];
for j=1:length(patient_files)
    file_path = patient_files{j};
    [~, filename_no_ext, ~] = fileparts(file_path);
    pieces = strsplit(filename_no_ext,'_');
    CurrentEEGDate = strcat(pieces{2},pieces{3});
    CurrentEEGDatetime = datetime(CurrentEEGDate,'InputFormat','yyyyMMddHHmmss');
    time_after_cardiac_arrest = seconds(CurrentEEGDatetime-EEGStartDatetime)+currentPtArrest2EEGSeconds;
    samples_after_cardiac_arrest = time_after_cardiac_arrest*srate;                 
    describe_bs_results_exist = do_describe_bs_results_exist(file_path);
    if use_saved_detect_bs_output && describe_bs_results_exist
        disp('loading saved detect_bs results...');
        tic
        [current_EEG_episode_bursts_cell, current_EEG_bs_episode_ranges, current_EEG_burst_ranges_cell, current_EEG_srate] = load_detect_bs(filename_no_ext);
    else
        % Run burst suppression detection stuff
        disp('running pipeline_up_to_detect_bs...');
        t = tic;
        [eeg, bs_ranges, global_zs, bsr, burst_ranges_cell, local_zs] = pipeline_up_to_detect_bs(file_path);
        disp('done pipeline up to detect bs, time taken: ');
        toc(t);
        srate = eeg.srate;
        burst_data_obj = eeg.data;
        % Write the results of burst suppression detection
        if save_detect_bs_output
            disp('saving detect_bs results');
            write_detect_bs_output(file_path, eeg, bs_ranges, global_zs, bsr, burst_ranges_cell);
        end
        disp('loading saved detect_bs results...');
        tic
        [current_EEG_episode_bursts_cell, current_EEG_bs_episode_ranges, current_EEG_burst_ranges_cell, current_EEG_srate] = load_detect_bs(filename_no_ext);
        
    end
    all_data_from_EEGs{j,1} = filename_no_ext;              
    all_data_from_EEGs{j,2} = samples_after_cardiac_arrest;
    all_data_from_EEGs{j,3} = current_EEG_episode_bursts_cell;
    all_data_from_EEGs{j,4} = current_EEG_bs_episode_ranges;
    all_data_from_EEGs{j,5} = current_EEG_burst_ranges_cell;
    all_data_from_EEGs{j,6} = current_EEG_srate;
    all_data_from_EEGs{j,7} = do_describe_bs_results_exist(file_path);
end

all_bursts = all_data_from_EEGs(:,3);
empty_counter = 0;

for i=1:length(all_bursts)
    current_cell = all_bursts{i};
    if isempty(current_cell)
        empty_counter = empty_counter + 1;
    end
end
if empty_counter == length(all_bursts)
    similarities_cell = [];
    filtered_burst_ranges_cell = [];
    similarities_matrix = [];
    burst_ranges = [];
    selected_sorted_all_episodes_data = [];
    distance_of_episode_from_target = [];
    return
end

all_episodes_data = [];
counter = 0;
for j=1:size(all_data_from_EEGs,1)
    current_EEG_name = all_data_from_EEGs{j,1};
    current_EEG_start_sample = all_data_from_EEGs{j,2};
    current_EEG_bursts_cell = all_data_from_EEGs{j,3};
    current_EEG_burst_ranges_cell = all_data_from_EEGs{j,5};
    current_EEG_srate = all_data_from_EEGs{j,6};
    current_EEG_bs_episode_ranges = all_data_from_EEGs{j,4};
    current_EEG_bs_episode_ranges=current_EEG_start_sample+current_EEG_bs_episode_ranges;
    %         current_EEG_bs_episode_ranges = cellfun(@(x) x+current_EEG_start_sample,current_EEG_bs_episode_ranges,'un',0);
    current_EEG_do_bs_results_exist = all_data_from_EEGs{j,7};
    all_data_from_EEGs{j,4} = current_EEG_bs_episode_ranges;

    for k=1:size(current_EEG_bs_episode_ranges,1)
        current_episode_bs_start_sample = current_EEG_bs_episode_ranges(k,1);
        current_episode_bs_end_sample = current_EEG_bs_episode_ranges(k,2);
        if target_sample_after_cardiac_arrest < current_episode_bs_end_sample && target_sample_after_cardiac_arrest > current_episode_bs_start_sample
            current_EEG_bs_episode_ranges(k,3) = 0;
            distance_from_episode_to_target = 0;
            position = 'includes';
        end
        distance_from_episode_start_to_target = target_sample_after_cardiac_arrest - current_episode_bs_start_sample;
        distance_from_episode_end_to_target = target_sample_after_cardiac_arrest - current_episode_bs_end_sample;
        if distance_from_episode_end_to_target > 0
            %episode is on left side of target
            distance_from_episode_to_target = distance_from_episode_end_to_target;
            position = 'left';
        end
        if distance_from_episode_start_to_target < 0
            %episode is on the right side of target
            distance_from_episode_to_target = distance_from_episode_start_to_target;
            position = 'right';
        end
        current_EEG_bs_episode_ranges(k,3) = distance_from_episode_to_target;
        counter = counter+1;
        all_episodes_data{counter,1} = current_EEG_name;
        all_episodes_data{counter,2} = current_EEG_start_sample;
        all_episodes_data{counter,3} = current_episode_bs_start_sample;
        all_episodes_data{counter,4} = current_episode_bs_end_sample;
        all_episodes_data{counter,5} = distance_from_episode_to_target;
        all_episodes_data{counter,6} = position;
        all_episodes_data{counter,7} = current_EEG_bursts_cell(k);
        all_episodes_data{counter,8} = current_EEG_burst_ranges_cell{k};
        all_episodes_data{counter,9} = current_EEG_srate;
        all_episodes_data{counter,10} = current_EEG_do_bs_results_exist;
    end
end

all_episode_distances = all_episodes_data(:,5);
all_episode_distances = cellfun(@(x) abs(x),all_episode_distances,'un',0);
[sorted_episode_distances index] = sort(cell2mat(all_episode_distances));

sorted_all_episodes_data = all_episodes_data(index,:);

similarities_cell = [];
similarities_matrix = [];
filtered_burst_ranges_cell = [];

for i=1:size(sorted_all_episodes_data,1)
    current_episode_EEG_bursts = sorted_all_episodes_data{i,7};
    current_episode_EEG_bursts = current_episode_EEG_bursts{1,1};
    no_bursts = length(current_episode_EEG_bursts);
    %         if no_bursts < 20
    %             continue
    %         end

    describe_bs_results_exist = sorted_all_episodes_data{i,10};

    srate = sorted_all_episodes_data{i,9};
    burst_ranges = sorted_all_episodes_data{i,8};
    burst_data_obj = current_episode_EEG_bursts;

    %% run similarity
    if use_saved_detect_bs_output && describe_bs_results_exist
        [similarities_cell, similarities_matrix, filtered_burst_ranges_cell] = similarity_all_bursts(similarity_fn, srate, burst_ranges, burst_data_obj,bursts_to_analyze,units);
        disp('similarity run!')
    end
    sorted_all_episodes_data{i,11} = similarities_cell;
    sorted_all_episodes_data{i,12} = similarities_matrix;
    sorted_all_episodes_data{i,13} = filtered_burst_ranges_cell;

end

index_to_be_removed=[];
over50_sorted_all_episodes_data = sorted_all_episodes_data;
for i=1:size(over50_sorted_all_episodes_data,1)
    temp_similarity_vector = over50_sorted_all_episodes_data{i,11};
    if length(temp_similarity_vector)<1225
        index_to_be_removed = [index_to_be_removed {i}];
    end
end

over50_sorted_all_episodes_data(cell2mat(index_to_be_removed),:)=[];

if ~isempty(over50_sorted_all_episodes_data(:,11))
    similarities_cell = over50_sorted_all_episodes_data{1,11};
    similarities_matrix= over50_sorted_all_episodes_data{1,12};
    filtered_burst_ranges_cell= over50_sorted_all_episodes_data{1,13};
    distance_of_episode_from_target = over50_sorted_all_episodes_data{1,5};
    selected_sorted_all_episodes_data = over50_sorted_all_episodes_data;
end

if isempty(over50_sorted_all_episodes_data(:,11))
    over20_sorted_all_episodes_data = sorted_all_episodes_data;
    for i=1:size(over20_sorted_all_episodes_data,1)
        temp_similarity_vector = over20_sorted_all_episodes_data{i,11};
        if length(temp_similarity_vector)<190
            index_to_be_removed = [index_to_be_removed {i}];
        end
    end
    over20_sorted_all_episodes_data(cell2mat(index_to_be_removed),:)=[];
    if ~isempty(over20_sorted_all_episodes_data(:,11))
        similarities_cell = over20_sorted_all_episodes_data{1,11};
        similarities_matrix= over20_sorted_all_episodes_data{1,12};
        filtered_burst_ranges_cell= over20_sorted_all_episodes_data{1,13};
        distance_of_episode_from_target = over20_sorted_all_episodes_data{1,5};
        selected_sorted_all_episodes_data = over20_sorted_all_episodes_data;
    end
    if isempty(over20_sorted_all_episodes_data(:,11))
        similarities_cell = [];
        similarities_matrix= [];
        filtered_burst_ranges_cell= [];
        distance_of_episode_from_target = [];
        selected_sorted_all_episodes_data = [];
    end

end
% similarities_cell = [];
% filtered_burst_ranges_cell = [];
% similarities_matrix = [];
% burst_ranges = [];
% selected_sorted_all_episodes_data = [];
% distance_of_episode_from_target = [];
return

