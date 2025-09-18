% run burst suppression detection on the edfs in the 
% todo_files_list defined in Config.m
% plots the global zs, bsr, and full eeg signal

code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
save_dir_name = fullfile(Config.get_configs('save_images_dir'), 'visualize_bs_detection');
[status, ~, ~] = mkdir(save_dir_name);

addpath(genpath(code_folder));

files = get_todo_files();
num_files = size(files, 2);


winlength = 30; % window length (secs) for plotting
num_plots = 5; % number of plots to make for each edf

for i=1:length(files)
    file_path = files{i};
    [file_folder, filename_no_ext, ext] = fileparts(file_path);
    
    [eeg, is_artifact] = prep_and_artifact(file_path);
    data = eeg.data;

    disp('Running bs detection...');
    % run bs_detection and get desired outputs
    local_zs = label_local_bs(data, eeg.srate);
    [bs_ranges, global_zs, bsr, burst_ranges_cell] = detect_bs(eeg, is_artifact);

    colors = {'k', 'c', 'b', 'm'};
    color_indices = ones(size(eeg.data, 1)+2, size(eeg.data, 2));
    for j=1:size(bs_ranges,1)
        start_ind = bs_ranges(j, 1);
        end_ind = bs_ranges(j, 2);
        color_indices(1:end,start_ind:end_ind) = 2;
        burst_ranges = burst_ranges_cell{j};
        num_bursts = size(burst_ranges, 1);
        for k=1:num_bursts
            burst_k_start = burst_ranges(k, 1);
            burst_k_end = burst_ranges(k, 2);
            color_indices(1:end, burst_k_start:burst_k_end) = 3;
        end
    end
    color_indices(end-1:end, :) = 4;
    
    % save plots 
    j = 0;
    while j < num_plots
        start_index = randi([winlength*eeg.srate, size(eeg.data, 2) - winlength*eeg.srate], 1, 1);
        end_index = start_index+winlength*eeg.srate;
%         if (mean(bsr(start_index:end_index)) > 0.95) || mean(bsr(start_index:end_index)) < 0.30
%             % too much or too little burst, don't plot
%             continue
%         end
   
        save_eeg_plot(eeg, save_dir_name, filename_no_ext, ...
            'start_index', start_index, 'end_index', end_index, ...
            'is_shaded', is_artifact, 'bsr', bsr, 'global_zs', global_zs, ...
            'color_indices', color_indices, 'colors', colors);
    
        j = j+1;
    end
end
