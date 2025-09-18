%% Writes duration information to a csv file
% For each file in the todo_files_list (defined in Config.m), writes a row
% containing the number of samples, the sample rate, and the number of
% channels in the record.

% Note: In order to completely reliably get the number of samples, the edf 
% must be completely read in. Headers and whatnot should be trusted easily.

addpath(genpath('../..'));
code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');

addpath(genpath(code_folder));
addpath(genpath(ale_code_folder));

disp(Config);
files = get_todo_files();
num_files = length(files);
output_file_path = fullfile(Config.get_configs('output_dir'), 'eeg_data_size_info.csv');

use_saved = 1;
save_result = 1;
fid = fopen(output_file_path, 'w');
fprintf(fid, '%s\t%s\t%s\t%s\n', 'filename', 'nsamples', 'srate', 'nchans');

for i=1:num_files
    disp(['File num ' num2str(i) ' out of ' num2str(num_files)]);
    file_path = files{i};
    [file_folder, filename_no_ext, ext] = fileparts(file_path);
    disp(file_path);
    [eeg_eeglab_unprocessed] = load_eeglab_eeg(file_path, 1, 1);
    [nchans, nsamples] = size(eeg_eeglab_unprocessed.data);
    srate = eeg_eeglab_unprocessed.srate;
    fprintf(fid, '%s\t%d\t%d\t%d\n', filename_no_ext, nsamples, srate, nchans);
end
fclose( fid );