function [] = write_detect_bs_output(file_path, eeg, bs_ranges, global_zs, bsr, burst_ranges_cell, local_zs)
% WRITE_DETECT_BS_OUTPUT - writes the output of running bs detection
%   to files
%   
% file_path -       name of the edf for which this is the output for  
% eeg - the eeglab eeg object returned from prep_and_artifact
% bs_ranges - matrix of burst suppression episodes as outputted by
%               detect_bs.m
% global_zs - vector of global zs as outputted by detect_bs.m
% bsr - vector of bsr values as outputted by detect_bs.m
% burst_ranges_cell - cell of burst_ranges as outputted by detect_bs.m
% local_zs - optional. matrix of local_zs. If given, it will be written to
%                       output.

    if nargin < 8
        save_local_zs = false;
    end
    output_dir = fullfile(Config.get_configs('output_dir'), 'describe_bs');
    [status, ~, ~] = mkdir(Config.get_configs('output_dir'), 'describe_bs');

    [~, filename_no_ext, ~] = fileparts(file_path);
    patient_id = get_pt_from_fname(file_path);
    
    % create results folder
    [status, ~, ~] = mkdir(output_dir, patient_id);
    [status, ~, ~] = mkdir(fullfile(output_dir, patient_id), filename_no_ext);

    results_folder = fullfile(output_dir, patient_id, filename_no_ext);
    
	disp('writing zs_bsr');
    tic;
    write_matrix(fullfile(results_folder, [filename_no_ext '_zs_bsr' '.csv']), ...
        [global_zs' bsr'], '%f', '\t', {'global_zs', 'bsr'});
    toc;
    
    if save_local_zs
        disp('writing local_zs');
        tic;
        write_matrix(fullfile(results_folder, [filename_no_ext '_local_zs' '.csv']), ...
            local_zs', '%f', '\t', get_channel_labels_cell(eeg));
        toc;
    end
   
    channel = 1;
    channel_labels = get_channel_labels_cell(eeg);
    channel_label = channel_labels{channel};
    if strcmp(channel_label, 'Fp1-F7')~=1
        disp(['Warning warning WARNING: channel label is ' channel_label]);
    end
    disp(['writing ' num2str(size(bs_ranges, 1)) ' episodes with channel ' channel_label]);
    tic;
    for j=1:size(bs_ranges,1)
        start_ind = bs_ranges(j, 1);
        end_ind = bs_ranges(j, 2);
        bs_episode_filename_no_ext = [filename_no_ext '_episode_' num2str(start_ind) '_' num2str(end_ind)];
        bs_episode_filepath = fullfile(results_folder, [bs_episode_filename_no_ext '.json']);

        burst_ranges = burst_ranges_cell{j};
        num_bursts = size(burst_ranges, 1);
        
        burst_structs = cell(num_bursts, 1);
        % iterate through all bursts
        for k=1:num_bursts
            burst_k_start = burst_ranges(k, 1);
            burst_k_end = burst_ranges(k, 2);
            burst_k = eeg.data(channel, burst_k_start:burst_k_end);
            burst_structs{k} = struct('burst_start_index', burst_k_start, 'burst_data', burst_k);
        end
        savejson([num2str(start_ind) '_' num2str(end_ind)], burst_structs, struct('FileName',bs_episode_filepath));
%         write_matrix(fullfile(results_folder, bs_episode_filename), burst_ranges, ...
%             '%.0f', '\t', {'burst_start_idx', 'burst_end_idx'});
    end
    toc;
	disp(['Done with file ' filename_no_ext]);
end
