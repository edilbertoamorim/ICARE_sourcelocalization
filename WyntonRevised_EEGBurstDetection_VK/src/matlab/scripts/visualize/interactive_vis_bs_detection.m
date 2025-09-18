%% Note
% Before running, change the 'repo_dir' property of Config.m (located in
% config_and_params)

%% Variables to edit

% path to the edf file you wish to visualize bs detection for
file_path = '/Users/tzhan/src/thesis/sample_data/analyze/ynh_117_6_1_20130827T024151.edf';
start_index = 513600; % index to start plotting at
window_length = 60; % number of seconds to dispaly at a time

%% Calculate bsr and plot

addpath(genpath('../../'))
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');
addpath(genpath(ale_code_folder));

disp('Loading eeg/prep/artifact...');
[eeg, is_artifact] = prep_and_artifact(file_path);
data = eeg.data;

disp('Running bs detection...');

% run bs_detection and get desired outputs
local_zs = label_local_zs(data, eeg.srate);
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

% Plot. 
% Shaded blue -> region is artifact
% Colored black -> normal eeg signal, not part of burst suppression episode
% Colored blue -> eeg signal, suppression part of burst suppression episode
% Colored cyan -> eeg signal, burst part of burst suppression episode
% Colored m -> global_zs and bsr signals

% To go forward: press 'f', to go back: press 'b'. To exit, press 'e'.

% You can also change the optional arguments 'start_index' and 'winlength'
% to change where it starts plotting, and how large in seconds the window
% is
plot_eeg_interactive(eeg, 'bsr', bsr, 'global_zs', global_zs, 'is_shaded',...
    is_artifact, 'color_indices', color_indices, 'colors', colors, ...
    'start_index', start_index, 'winlength', window_length);