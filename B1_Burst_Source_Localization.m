%% Burst Source Localization
% Author: A.Faloppa
% 1/08/2025
%
% Purpose of the code: Localize burst sources from patients EEG
%
% Usage:
%   Be sure to have eeglab2025.0.0, fieldtrip-20250106 and Source_localization_files 
%   in the current directory (if the version is not up to date 
%   change the version in 'Default variables and allocations' section)
%
%   Be sure to have the output of A2_Burst_reange_extraction.m Script 
%   Be sure to have Source_loc_time_ROSC_local.xlsx matching the .mat EEG filenames in input 
%   Be sure to have the MNI_DKA_Standard_Lead_Field.mat file with the leadfield model
% 
%   Provide the same input directory provided in A2_Burst_detection.m Script
%
%   Run the script
%
% Input : 
%   directory INPUT_X with: 
%       .mat EEG files analyzed with the A1 and A2 scripts
%       INPUT_X/EDF_converted/outpud_burst_detection folder inside
%
% Output : 
%   Located the input directory provided INPUT_X:
%       Burst_Source_Localization_OUTPUT containing : 
%           Burst_Sources : table with voxel power in each ROI per hour 
%           Burts_hours : Burst hours table
%           Burst_plots : Plots of eeg segments analyzed;
%
% This code uses the Source_Localization_DKA_MNI.m function adapted by 
% G.Velasquez and running F.Jiang's CHAMPAGNE source localization algorithm 
% (modified by A.Faloppa)
% 
% Contact details : Amorim De Cerqueira Filho, Edilberto <Edilberto.Amorim@ucsf.edu>
clear; close all; clc;

%% Configurable variables:
dataset_name = 'ICARE_Wynton_0758_Data';
dataset_name = 'TRIAL_EDF';

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


% Get Patient ID
%Excel sheet containing the patient IDs, feature file names, and time from ROSC
rosc_times = readtable('Source_loc_time_ROSC_local.xlsx');
job_id = unique(rosc_times.ptid_og);

% Run sourcelocalization
for i= 1:length(job_id)
    try
        Source_Localization_DKA_MNI_new(job_id{i}, dir_input, dir_output, dir_burst_ranges)
    catch
        fprintf('No file found for Patient ID: %d\n', char(job_id(i)));
    end
     
end


