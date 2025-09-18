%% Runs burst suppression detection and saves output for a list of edfs
% To run:
% 1. Create a txt file containing the path to all edf files to process
%       For the NFS dataset, this can be done using a script in the python
%       directory. 
% 2. Create a directory in which to save output. 
%     (NOTE: If running for a lot of edfs, make sure this directory has a lot of space!)
% 3. Inside 'src/matlab/config_and_params/Config.m':
%     a. Set 'todo_files_list' to the path of the txt file created in step 1
%     b. Set 'repo_dir' to the path of the 'coma_EEG_alice_zhan' repository
%     c. Set 'output_dir' to the path of the output directory created in step 2
    
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
    [file_folder, filename_no_ext, ext] = fileparts(file_path);
    filename = strcat(filename_no_ext, ext);
    patient_id = get_pt_from_fname(file_path);
    
    % if results already exists, continue
    results_exist = do_describe_bs_results_exist(file_path);
    if results_exist
        disp(['Results already exist for ' filename ', skipping...']);
        continue
    end
    
    tic;
    [eeg, bs_ranges, global_zs, bsr, burst_ranges_cell, local_zs] = pipeline_up_to_detect_bs(file_path);
    toc;
    
    write_detect_bs_output(file_path, eeg, bs_ranges, global_zs, bsr, burst_ranges_cell, local_zs)
	disp(['Done with file ' filename_no_ext]);

end
disp('All done with all files! Woohoo!');


