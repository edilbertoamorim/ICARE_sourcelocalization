%% Features ROI Map Plot
% Author: A.Faloppa
% 1/08/2025
%
% Purpose of the code: Map features to DKA from patients EEG
%
% Usage:
%   Be sure to have eeglab2025.0.0, fieldtrip-20250106 and Source_localization_files 
%   in the current directory (if the version is not up to date 
%   change the version in 'Default variables and allocations' section)
% 
%   Be sure to have Fetaures_loc_time_ROSC_local.xlsx matching the .mat features filenames in input 
%   Be sure to have the MNI_DKA_Standard_Lead_Field.mat file with the leadfield model
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
%   Located the input directory provided INPUT_X:
%       Excel table with voxel power in each ROI per hour for that specific feature 
%
% This code uses the Source_Localization_DKA_MNI.m function adapted by 
% Velasquez Gerardo <Gerardo.Velasquez@ucsf.edu> and running Fei Jiang's
% CHAMPAGNE source localization algorithm 
% 
% Contact details : Amorim De Cerqueira Filho, Edilberto <Edilberto.Amorim@ucsf.edu>
clear; close all; clc;

%% Configurable variables:
dir_input = '.\Data\BWH_1005\features'; % Feature files directory
% selected_feats = [5:8, 11, 31:37];
% max_hr = 100;
% VERBOSE = 0; % Intermediate plot

%% Default variables and allocations

% Get current script folder
baseDir = fileparts(mfilename('fullpath'));

% Add desired subfolders to the path
addpath(fullfile(baseDir, 'eeglab2025.0.0'));
addpath(fullfile(baseDir, 'fieldtrip-20250106'));
addpath(fullfile(baseDir, 'fieldtrip-20250106', 'external', 'eeglab'));
addpath(fullfile(baseDir, 'Source_localization_files'));
addpath(fullfile(baseDir, dir_input));

% Get Patient ID
%Excel sheet containing the patient IDs, feature file names, and time from ROSC
rosc_times = readtable('Features_loc_time_ROSC_local.xlsx');
job_id = unique(rosc_times.ptid_og);

% Run sourcelocalization
for i= 1:length(job_id)
    plot_ROIs(job_id, dir_input)
end