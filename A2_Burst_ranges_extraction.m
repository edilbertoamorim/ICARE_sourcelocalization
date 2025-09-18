%% Burst Ranges Extraction
% Author: A.Faloppa
% 1/08/2025
%
% Purpose of the code: Extract Burst ranges as csv files
%
% Usage:
%   Be sure to have eeglab2025.0.0, fieldtrip-20250106 and Source_localization_files 
%   in the current directory (if the version is not up to date 
%   change the version in 'Default variables and allocations' section)
%
%   Be sure to have the output of A1_Burst_detection.m Script
% 
%   Provide the same input directory provided in A1_Burst_detection.m Script
%
%   Run the script
%
% Input : 
%   directory INPUT_X with INPUT_X/EDF_converted/outpud_burst_detection folders inside
%
% Output : 
%   Located the input directory provided INPUT_X: 
%       burst_ranges_detected folder containing one or multiple csv files. 
%       The burst detection pipeline could have divided the burst detected
%       in multiple episodes (Part 1, Part 2, etc...).
clear; close all; clc;

%% Configurable variables:
dataset_name = 'ICARE_Wynton_0758_Data';
dataset_name = 'TRIAL_EDF';
dir_input = './Data/ICARE_Wynton_0758_Data/';

%% Default variables and allocations
% Define output directory
dir_data = './Data';
dir_input = fullfile(dir_data, dataset_name);
dir_output = fullfile(dir_data, 'OUTPUT', dataset_name);

dir_burst_ranges = fullfile(dir_output, 'Burst_ranges');
if ~exist(dir_burst_ranges, 'dir')
    mkdir(dir_burst_ranges);
end

% Get current script folder
baseDir = fileparts(mfilename('fullpath'));

% Add desired subfolders to the path
addpath(fullfile(baseDir, 'eeglab2025.0.0'));
addpath(fullfile(baseDir, 'fieldtrip-20250106'));
addpath(fullfile(baseDir, 'fieldtrip-20250106', 'external', 'eeglab'));
addpath(fullfile(baseDir, 'Source_localization_files'));
addpath(fullfile(baseDir, dir_input));
% addpath(fullfile(baseDir, 'wynton_log_files'));

%% Load and write csv files
load(fullfile(dir_output, 'Burst_detection', 'burst_summary.mat'))

% Loop through each result
for i = 1:numel(results)
    % Get filename and convert to .mat.csv
    original_name = results(i).filename;  % e.g., 'subject001.edf'
    base_name = erase(original_name, '.edf');

    % Extract burst start/end index pairs
    burst_ranges = results(i).burst_ranges_cell;
    
    for j = 1:numel(burst_ranges)
       burst_data{1,j} = burst_ranges{1,j}; 
       T = array2table(burst_data{1}, 'VariableNames', {'burst_start_index', 'burst_end_index'});
       csv_filename = [base_name, '_Part_', num2str(j), '.csv'];
       csv_fullpath = fullfile(dir_burst_ranges, csv_filename);
       writetable(T, csv_fullpath);
    end

end

fprintf('✅ All burst CSV files saved to %s\n', dir_burst_ranges);