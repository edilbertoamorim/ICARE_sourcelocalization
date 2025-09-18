% preprocess and plot the before and after signals of the edfs in the 
% todo_files_list defined in Config.m

code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
save_dir_name = fullfile(Config.get_configs('save_images_dir'), 'visualize_preprocessing');

[status, ~, ~] = mkdir(save_dir_name);

addpath(genpath(code_folder));

files = get_todo_files();

num_files = size(files, 2); 

use_saved_eeglab = 1;
save_eeglab_result = 1;

winlength = 15;  % number of seconds to show in each plot
num_plots = 5;   % number of plots to make for each edf
    
for i=1:num_files
    filename = files{i}
    [file_folder, filename_no_ext, ext] = fileparts(filename);
	disp(file_folder);
	disp([filename_no_ext ext]);
    
    filepath = filename;
    [eeg_eeglab_unprocessed] = load_eeglab_eeg(filepath, use_saved_eeglab, save_eeglab_result);
    if contains(filepath, 'ynh') || contains(filepath, 'bwh')
        % These need to be inverted.
        eeg_eeglab_unprocessed.data = eeg_eeglab_unprocessed.data * -1;
    end
    eeg_eeglab_processed = preprocess(eeg_eeglab_unprocessed);
    disp([filename_no_ext, 'artifact detection...']);
    is_artifact = detect_artifacts(eeg_eeglab_processed);
    
    
    eeg_processed = eeg_eeglab_processed;
    eeg_unprocessed = eeg_eeglab_unprocessed;
    
    disp([filename_no_ext, 'saving plots...']);

    num_samples = min(size(eeg_processed.data, 2), size(eeg_unprocessed.data, 2));
    start_indices = randi([winlength*eeg_processed.srate, num_samples - winlength*eeg_processed.srate], num_plots, 1);
    end_indices = start_indices+winlength*eeg_processed.srate;
    for j=1:num_plots
        start_index = start_indices(j);
        end_index = end_indices(j);
        save_eeg_plot(eeg_processed, save_dir_name, filename_no_ext, ...
            'save_info', 'processed', ...
            'start_index', start_index, 'end_index', end_index, ...
            'is_shaded', is_artifact)
        save_eeg_plot(eeg_unprocessed, save_dir_name, filename_no_ext, ...
            'save_info', 'unprocessed', ...
            'start_index', start_index, 'end_index', end_index, ...
            'is_shaded', is_artifact)
    end
end
