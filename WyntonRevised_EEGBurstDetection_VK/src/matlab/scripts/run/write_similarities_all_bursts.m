%% Runs similarity for a list of edfs
% For each file in the "todo_files_list" (defined in Config.m), runs
% the entire pipeline up to and including similarity with both dtw and 
% cross-correlation, and writes the
% results to the 'similarity' subdirectory of the output_dir (defined in
% Config.m)

% User may set the following two variables as desired:
%     use_saved_detect_bs_output - boolean. if true and saved results exist
%           for the detect_bs portion of the pipeline, loads and uses the saved results
%           rather than recomputing them.
%     save_detect_bs_output - boolean. if true, saves any newly computed
%           detect_bs results to the 'describe_bs' subdirectory of the 'output_dir' 
%           defined in Config.m
clear
use_saved_detect_bs_output = 1;
save_detect_bs_output = 1;
% bursts_to_analyze = [1 50]; %[1st_burst_number last_burst_number]
bursts_to_analyze = 'all';
units = 'bursts';%bursts 

addpath(genpath('../..'));
code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');

addpath(genpath(code_folder));
addpath(genpath(ale_code_folder));

disp(Config);
disp(SimilarityParams);
disp(DetectBsParams);
files = get_todo_files();
num_files = length(files);

uniquePts = unique(cellfun(@(x) get_pt_from_fname(x),files,'UniformOutput',0));
uniquePtFiles = cell(size(uniquePts));
badFiles = {'/wynton/protected/group/lee-phi/CDAC_Arrest_EEG/UTW_whole/21138f2fc157f8af4184382729284c2a9826c9baeaf39671de05b205a75444be_20130608_115301.edf','/wynton/protected/group/lee-phi/CDAC_Arrest_EEG/UTW_whole/24f29cf1a462a38b79a1db6c4701c534e363c82f0df46d2e4a37c42a3bf59bb4_20130329_192900.edf','/wynton/protected/group/lee-phi/CDAC_Arrest_EEG/UTW_whole/d1375c2cc3734a5dc80817014d8bf27909e2bc3fd2e4add5035d4f78ffdb574b_20120229_092400.edf'};
for i=1:num_files
    if any(ismember(badFiles,files{i}))
%         fprintf('skip');
        continue
    end
    pt_id = get_pt_from_fname(files{i});
    idx = cellfun(@(x) strcmp(x,pt_id),uniquePts,'UniformOutput',1);
    uniquePtFiles{idx} = [uniquePtFiles{idx} {files{i}}];
end

badHolder = [];
%Bad: 127, 150, 819, 892
%Start of Jon2:723
jon1Inds = [1:126 128:149 151:722];
jon2Inds = [723:818 820:891 893:length(uniquePts)];
for i=1:length(uniquePts)
    pt_id = uniquePts{i};
    patient_files = uniquePtFiles{i};
%     disp(patient_files)
    run_and_write_similarity_for_pt(pt_id,patient_files, use_saved_detect_bs_output, save_detect_bs_output, bursts_to_analyze, units);
end



% for i=1:num_files
%     disp(['File num ' num2str(i) ' out of ' num2str(num_files)]);
%     file_path = files{i};
%     disp(file_path)
%     run_and_write_similarity_for_pt(file_path, use_saved_detect_bs_output, save_detect_bs_output);
% end

function [] = run_and_write_similarity_for_pt(pt_id,patient_files, use_saved_detect_bs_output, save_detect_bs_output, bursts_to_analyze,units)

    results_exist = do_similarity_all_bursts_results_exist(pt_id);
    if results_exist
        disp('similarities file(s) already exists, continuing');
        return
    end
    
    %% Cross-correlation
    [similarities_cell_xcorr, filtered_burst_ranges_cell, similarities_matrix_xcorr, bs_ranges, srate,  burst_ranges, burst_data_obj,cardiac_arrest_present,selected_sorted_all_episodes_data_xcorr,distance_of_episode_from_target] = pipeline_up_to_similarity_all_bursts(pt_id,patient_files, 'correlation', use_saved_detect_bs_output, save_detect_bs_output,bursts_to_analyze,units);
    if cardiac_arrest_present == 0
        return
    end
    disp('writing xcorr similarity output...');
    tic
   
    write_similarity_all_bursts_output(pt_id, similarities_cell_xcorr, similarities_matrix_xcorr, 'xcorr',bursts_to_analyze,units,filtered_burst_ranges_cell,selected_sorted_all_episodes_data_xcorr,distance_of_episode_from_target);
    toc
    % done with xcorr similarities, so can clear from memory
    clearvars('similarities_cell_xcorr');
    clearvars('filtered_burst_ranges_cell');
    clearvars('similarities_matrix_xcorr');
    
    %% DTW, using detect_bs results from the earliest xcorr run
    tic;
    [similarities_cell_dtw, filtered_burst_ranges_cell, similarities_matrix_dtw, bs_ranges, srate,  burst_ranges, burst_data_obj,cardiac_arrest_present,selected_sorted_all_episodes_data_dtw,distance_of_episode_from_target] = pipeline_up_to_similarity_all_bursts(pt_id,patient_files, 'dtw', use_saved_detect_bs_output, save_detect_bs_output,bursts_to_analyze,units);
%     [similarities_cell_dtw, similarities_matrix_dtw, selected_sorted_all_episodes_data_dtw,distance_of_episode_from_target_dtw] = similarity_all_bursts('dtw', srate, burst_ranges, burst_data_obj,bursts_to_analyze,units);
    toc;

    disp('writing dtw similarity output...');
    tic
    write_similarity_all_bursts_output(pt_id, similarities_cell_dtw, similarities_matrix_dtw, 'dtw',bursts_to_analyze,units,filtered_burst_ranges_cell,selected_sorted_all_episodes_data_dtw,distance_of_episode_from_target);
    toc
    % done with dtw similarities, so can clear from memory
    clearvars('similarities_cell_dtw');
    clearvars('similarities_matrix_dtw');
end



