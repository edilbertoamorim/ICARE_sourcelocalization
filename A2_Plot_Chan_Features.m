%% Features ROI Map Plot
% Author: A.Faloppa
% 1/08/2025
%
% Purpose of the code: Map features for patients EEG
%
%   Be sure to have the following toolboxes in the pipeline directory : 
%           eeglab
%           Source_localization_files (utility folder)
%    
%   (rename folders accordingly, used toolboxes version is 2024 or later)
% 
%   Be sure to have the patient list running Get_patinets_IDs.m 
% 
%   Change the .xlm patient table filename if needed in 'patient_table'
%
%   Be sure to have the output from A1_Source_Reconstruction.m script
%
%   Run the script
%
% Input : 
%   Patient table and IDs to process from I-CARE dataset
%   Features tables in the Output folders per patient
%
% Output : 
%   Located Data/OUTPUT/Source_Reconstruction:
%       Patient_ID/04_FeaturesPlots   : Topoplots of mapped features  
%
% This code is an adaptation of previous work by 
% G.Velasquez and running F.Jiang's CHAMPAGNE source localization algorithm 
% (adapted by A.Faloppa)
% 
% Contact details : Amorim De Cerqueira Filho, Edilberto <Edilberto.Amorim@ucsf.edu>
clear; close all; clc;

%% Configurable variables:
patient_table = 'ICARE_patient_metadata';
VERBOSE = 0; % Intermediate plot

%% Default variables and allocations
dir_data = './Data';

% Get current script folder
baseDir = fileparts(mfilename('fullpath'));

% Add desired subfolders to the path
addpath(genpath(fullfile(baseDir, 'eeglab')));
addpath(genpath(fullfile(baseDir, 'Source_localization_files')));

% Get Patient ID
patient_list = readtable(patient_table);
job_id = unique(patient_list.Patient);

% Loop over each patient
for i = 1:length(job_id)

    pid = job_id{i};  % current patient ID (string)
    
    % Find the row corresponding to this patient
    rowIdx = find(strcmp(patient_list.Patient, pid));
    
    % Convert the row to a struct
    patient_info = table2struct(patient_list(rowIdx, :));
    
    dir_output = fullfile(dir_data, 'OUTPUT', 'Source_Reconstruction', pid);

    try
        plot_chan_features(patient_info, dir_output);
    catch ME
        warning(ME.identifier, 'Process failed (%s)', ME.message);
        disp(strcat("Problems with Patient : ", string(pid), " - Skipping..."))
    end
end

disp("Complete")