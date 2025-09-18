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
use_saved_detect_bs_output = 1;
save_detect_bs_output = 1;



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

for i=1:num_files
    disp(['File num ' num2str(i) ' out of ' num2str(num_files)]);
    file_path = files{i};
    disp(file_path)
    run_and_write_similarity_for_file(file_path, use_saved_detect_bs_output, save_detect_bs_output);
end

function [] = run_and_write_similarity_for_file(file_path, use_saved_detect_bs_output, save_detect_bs_output)

    results_exist = do_similarity_results_exist(file_path);
    if results_exist
        disp('similarities file(s) already exists, continuing');
        return
    end
    
    %% Cross-correlation
    [similarities_cell_xcorr, filtered_burst_ranges_cell, bs_ranges, srate,  burst_ranges_cell, burst_data_obj] = pipeline_up_to_similarity(file_path, 'correlation', use_saved_detect_bs_output, save_detect_bs_output);

    disp('writing xcorr similarity output...');
    tic
    write_similarity_output(file_path, similarities_cell_xcorr, bs_ranges, 'xcorr', filtered_burst_ranges_cell);
    toc
    % done with xcorr similarities, so can clear from memory
    clearvars('similarities_cell_xcorr');
    clearvars('filtered_burst_ranges_cell');
    
    %% DTW, using detect_bs results from the earliest xcorr run
    tic;
    [similarities_cell_dtw, ~] = similarity('dtw', srate, burst_ranges_cell, burst_data_obj);
    toc;

    disp('writing dtw similarity output...');
    tic
    write_similarity_output(file_path, similarities_cell_dtw, bs_ranges, 'dtw');
    toc
    % done with dtw similarities, so can clear from memory
    clearvars('similarities_cell_dtw');
end





