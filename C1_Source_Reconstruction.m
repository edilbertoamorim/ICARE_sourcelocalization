%% Source Reconstruction
% Author: A.Faloppa
% 1/09/2025
%
% Purpose of the code: Reconstruct Source Level time series (SBL-Beamforming)
%
% Usage:
%   Be sure to have eeglab2025.0.0, fieldtrip-20250106 and Source_localization_files 
%   in the current directory (if the version is not up to date 
%   change the version in 'Default variables and allocations' section)
% 
%   Be sure to have Fetaures_loc_time_ROSC_local.xlsx matching the .mat filenames in input 
%   Be sure to have the MNI_DKA_Standard_Lead_Field.mat file with the leadfield matrix
% 
%   Provide as input the directory containing the features extracted for eeg files
%
%   Run the script
%
% Input : 
%   directory INPUT_X with: 
%       .mat EEG files containing fetures data : feat = [19_channels x n_samples]
%
% Output : 
%   Located OUTPUT_SourceRec:
%       Source Reconstucted .mat files? 
%
% This code uses the Source_Localization_DKA_MNI.m function adapted by 
% G.Velasquez and running F.Jiang's CHAMPAGNE source localization algorithm 
% (modified by A.Faloppa)
% 
% Contact details : Amorim De Cerqueira Filho, Edilberto <Edilberto.Amorim@ucsf.edu>
clear; close all; clc;

%% Configurable variables:
dataset_name = 'ICARE_Wynton_0758_Data'; % EEG files directory
dataset_name = 'TRIAL_EDF';
max_hr = 10;
VERBOSE = 0; % Intermediate plot

%% Default variables and allocations
dir_data = './Data';
dir_input = fullfile(dir_data, dataset_name);
dir_output = fullfile(dir_data, 'OUTPUT', dataset_name);
dir_burst_ranges = fullfile(dir_output, 'Burst_ranges');

% Get current script folder
baseDir = fileparts(mfilename('fullpath'));

% Add desired subfolders to the path
addpath(fullfile(baseDir, 'eeglab2025.0.0'));
addpath(fullfile(baseDir, 'fieldtrip-20250106'));
addpath(fullfile(baseDir, 'fieldtrip-20250106', 'external', 'eeglab'));
addpath(fullfile(baseDir, 'Source_localization_files'));
addpath(fullfile(baseDir, dir_input));
% addpath(fullfile(baseDir, 'wynton_log_files'));
ft_defaults

% Get Patient ID
%Excel sheet containing the patient IDs, feature file names, and time from ROSC (in a single folder of .\Data)
rosc_times = readtable('Source_loc_time_ROSC_local.xlsx');
job_id = unique(rosc_times.ptid_og);

% Run sourcelocalization
for i= 1:length(job_id)
    try
        Source_Reconstruction_DKA_MNI(job_id{i}, dir_input, dir_output, dir_burst_ranges, max_hr, VERBOSE)
    catch
        fprintf('No file found for Patient ID: %d\n', char(job_id(i)));
    end
end
disp("Complete")