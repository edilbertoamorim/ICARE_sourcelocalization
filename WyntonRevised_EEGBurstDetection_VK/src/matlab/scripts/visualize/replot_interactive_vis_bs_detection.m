%% Use this to replot the current eeg/edf at a different index
% This will be faster than interactive_vis_bs_detection.m because it uses
% the global_zs and bsr that have already been calculated

%% Variables to edit

start_index = 513600; % index to start plotting at
window_length = 60; % number of seconds to dispaly at a time

%% Plot
plot_eeg_interactive(eeg, 'bsr', bsr, 'global_zs', global_zs, 'is_shaded',...
    is_artifact, 'color_indices', color_indices, 'colors', colors, ...
    'start_index', start_index, 'winlength', window_length);