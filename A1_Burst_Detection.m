%% Burst Detection
% Author: A.Faloppa
% 1/08/2025
%
% Purpose of the code: Open EEG edf files, convert them in edf and run bs_detection pipeline
%
% Usage:
%   Be sure to have eeglab2025.0.0, fieldtrip-20250106, Source_localization_files and 
%   WyntonRevised_EEGBurstDetection_VK in the current directory 
%   (if the version is not up to date change the version in 'Default variables and allocations' section)
%
%   In the pipeline directory create a folder named 'Data'
%
%   Set the files (.mat or .edf) in a folder inside 'Data' called 'dataset_name'
%   and set input dir = 'dataset_name'
%   
%   Set the variable matlab_data = 1 if .at data used or 0 otherwise
%   (if .edf files used, in Data/OUTPUT you will find the .mat associated files: 
%       move them to the 'dataset_name folder' and update the Source_loc_time_ROSC_local.xlsx if necessary)
%
%   Run the script
%
% Input : 
%   directory with .mat/.edf raw EEG files inside (fieldtrip/eeglab format if .mat)
%
% Output : 
%   Located the input directory provided: 
%       - dir_input/EDF_converted : Contains edf converted eeg files
%       - dir_input/EDF_converted/output_burst_detection : contains a variable reporting all the burst detected
clear; close all; clc;

%% Configurable variables:
dataset_name = 'TRIAL_EDF';
matlab_data = 0;

%% Default variables and allocations
dir_data = './Data';
dir_input = fullfile(dir_data, dataset_name);
dir_output = fullfile(dir_data, 'OUTPUT', dataset_name);

% Directory containing EDF files
dir_edf = fullfile(dir_output, 'EDF_converted');
if ~exist(dir_edf, 'dir')
       mkdir(dir_edf);
end

% Define output folder and file
dir_burst_ranges = fullfile(dir_output, 'Burst_detection');
if ~exist(dir_burst_ranges, 'dir')
    mkdir(dir_burst_ranges);
end

% Get current script folder
baseDir = fileparts(mfilename('fullpath'));

% Add desired subfolders to the path
addpath(fullfile(baseDir, 'eeglab2025.0.0'));
addpath(fullfile(baseDir, 'fieldtrip-20250106'));
addpath(genpath(fullfile(baseDir, 'fieldtrip-20250106', 'external', 'eeglab')));
addpath(genpath(fullfile(baseDir, 'Source_localization_files')));
addpath(genpath(fullfile(baseDir, 'WyntonRevised_EEGBurstDetection_VK')));
addpath(fullfile(baseDir, dir_input));
% addpath(fullfile(baseDir, 'wynton_log_files'));

%% .mat to .edf conversion

if matlab_data 
    % Convert and save
    batch_mat_to_edf(dir_input, dir_edf);

else
    % Move files to EDF folder
    % Get list of all EDF files in the directory
    edf_files = dir(fullfile(dir_input, '*.edf'));
    % Loop through and move each file
    for i = 1:length(edf_files)
        src = fullfile(dir_input, edf_files(i).name);   % full path to source file
        dst = fullfile(dir_edf, edf_files(i).name);     % full path to destination
        movefile(src, dst);
    end
end

%% Run Burst detection

% Get list of all EDF files in the directory
edf_files = dir(fullfile(dir_edf, '*.edf'));

% Preallocate results struct array with only desired fields
results(length(edf_files)) = struct( ...
    'filename', '', ...
    'bs_ranges', [], ...
    'burst_ranges_cell', [] ...
);

% Loop over files and process
for i = 1:length(edf_files)
    fname = edf_files(i).name;
    full_path = fullfile(dir_edf, fname);
    fprintf('Processing %s (%d of %d)...\n', fname, i, length(edf_files));
    
    % Call your pipeline function (skip unwanted outputs with ~)
    [~, bs_ranges, ~, ~, burst_ranges_cell, ~] = pipeline_up_to_detect_bs(full_path);
    
    % Store only selected outputs
    results(i).filename = fname;
    results(i).bs_ranges = bs_ranges;
    results(i).burst_ranges_cell = burst_ranges_cell;
end

fprintf('Processing complete. Results stored in variable "results".\n');

output_file = fullfile(dir_burst_ranges, 'burst_summary.mat');

% Save results directly (no need to remove fields)
save(output_file, 'results');

fprintf('✅ Saved results to:\n%s\n', output_file);


