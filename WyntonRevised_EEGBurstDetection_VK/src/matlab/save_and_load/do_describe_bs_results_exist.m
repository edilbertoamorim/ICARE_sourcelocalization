function [results_exist] = do_describe_bs_results_exist(file_path)
% DO_DESCRIBE_BS_RESULTS_EXIST - returns if saved detect bs results already exist
%
% Params:
%   file_path - name of edf for which to check if results exist
%
% Output:
%   results_exist - boolean, true if saved results from running detect bs
%       for file_path already exist. 

[~, filename_no_ext, ~] = fileparts(file_path);

patient_id = get_pt_from_fname(file_path);
detect_bs_output_dir = fullfile(Config.get_configs('output_dir'), 'describe_bs');
detect_bs_results_folder = fullfile(detect_bs_output_dir, patient_id, filename_no_ext);
if exist(detect_bs_results_folder, 'dir')~=7
    results_exist = false;
    return
end
% folder exists

% check that zs_bsr file exists
zs_bsr_filename = strcat(filename_no_ext, '_zs_bsr.csv');
zs_bsr_filepath = fullfile(detect_bs_results_folder, zs_bsr_filename);
if exist(zs_bsr_filepath, 'file') == 2
    results_exist = true;
else
    results_exist = false;
end
end

