addpath(genpath('../..'));
code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');

addpath(genpath(code_folder));
addpath(genpath(ale_code_folder));

disp(Config);
files = get_todo_files();
num_files = length(files);

describe_bs_dir = fullfile(Config.get_configs('output_dir'), 'describe_bs');
similarity_dir = fullfile(Config.get_configs('output_dir'), 'similarity_no_clip');

for i=1:num_files
    disp(['File num ' num2str(i) ' out of ' num2str(num_files)]);
    file_path = files{i};
    [file_folder, filename_no_ext, ext] = fileparts(file_path);
    disp(file_path);
    
    patient_id = get_pt_from_fname(file_path);
    detect_bs_results_folder = fullfile(describe_bs_dir, patient_id, filename_no_ext);
    zs_bsr_path = fullfile(detect_bs_results_folder, [filename_no_ext '_zs_bsr' '.csv']);
    similarity_results_folder = fullfile(similarity_dir, patient_id, filename_no_ext);
    burst_ranges_paths = dir(fullfile(similarity_results_folder, '*burst_ranges*.csv'));
    
    fix_write_matrix(zs_bsr_path);
    for j=1:length(burst_ranges_paths)
        burst_range_filename = burst_ranges_paths(j).name;
        burst_range_filepath = fullfile(similarity_results_folder, burst_range_filename);
        fix_write_matrix(burst_range_filepath);
    end
end


