function [episode_bursts_cell, bs_ranges, burst_ranges_cell, srate] = load_detect_bs(edf_filename)
% LOAD_DETECT_BS - reads and loads the already detected bs for a patient
%
% Params:
%   edf_filename - name of edf for which to read and load results. Assumes
%               that results do exist. 
%
% Output:
%   episode_bursts_cell - cell of length num_bs_episodes, where each
%       element is a cell of length num_bursts containing vectors of 
%       the signal data for each burst in the episode
%   bs_ranges - bs_ranges matrix as outputted by detect_bs.m
%   burst_ranges_cell - cell of burst ranges as outputted by detect_bs.m
%   srate - srate used when bs detection was performed. Assumed to be 200.

    output_dir = fullfile(Config.get_configs('output_dir'), 'describe_bs');
    
    % assume srate = 200; 
    srate = 200;

    [~, filename_no_ext, ext] = fileparts(edf_filename);
    patient_id = get_pt_from_fname(edf_filename);

    results_folder = fullfile(output_dir, patient_id, filename_no_ext);
    
    episode_files = dir(fullfile(results_folder, '*.json'));
    num_episodes = length(episode_files);
    bs_ranges = zeros(num_episodes, 2);
    episode_bursts_cell = cell(1, num_episodes);
    burst_ranges_cell = cell(1, num_episodes);
    
    for i=1:num_episodes
        episode_file = episode_files(i).name;
        episode_file_path = fullfile(results_folder, episode_file);
        episode_struct = loadjson(episode_file_path);
        episode_name_c = fieldnames(episode_struct);
        episode_name = episode_name_c{1};

        [episode_start_index, episode_end_index] = parse_episode_name(episode_name);
        bs_ranges(i, :) = [episode_start_index, episode_end_index];

        bursts_structs_cell = episode_struct.(episode_name);
        num_bursts = length(bursts_structs_cell);
        bursts_cell = cell(1, num_bursts);
        burst_ranges_matrix = zeros(num_bursts, 2);
        for j=1:num_bursts
            burst_struct = bursts_structs_cell{j}{1};
            burst_start_index = burst_struct.burst_start_index;
            burst_data = burst_struct.burst_data;
            burst_end_index = burst_start_index + length(burst_data) - 1;
            bursts_cell{j} = burst_data;
            burst_ranges_matrix(j, :) = [burst_start_index burst_end_index];
        end
        episode_bursts_cell{i} = bursts_cell;
        burst_ranges_cell{i} = burst_ranges_matrix;
    end
end

function [start_index, end_index] = parse_episode_name(name)
    [~, name, ~] = fileparts(name);
    pieces = strsplit(name, '_');
%     episode_index = find(strcmp(pieces, 'episode'));
    start_index = str2num(pieces{2});
    end_index = str2num(pieces{3});
end


    

