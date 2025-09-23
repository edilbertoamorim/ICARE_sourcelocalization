%% Features ROI Map Plot
% Author: A.Faloppa
% 1/08/2025
%
% Purpose of the code: Map features to DKA from patients EEG
%
%   Be sure to have the following toolboxes in the pipeline directory : 
%           eeglab2025.0.0 
%           fieldtrip-20250106  
%           wfdb-app-toolbox
%           Source_localization_files (utility folder)
%    
%   (if different versions change the version in 'Default variables and allocations' section)
% 
%   Be sure to have the patient list running Get_patinets_IDs.m 
% 
%   Be sure to have the MNI_DKA_Standard_Files.mat file with the LFmatrix, 
%   atlas, insideix, leadfdc variables needed. These can also be obtained
%   running LFM_generation.m and manually adjusted.
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
%       Patient_ID/04_FeaturesPlots   : Figures of mapped features on Atlas  
%
% This code is an adaptation of previous work by 
% G.Velasquez and running F.Jiang's CHAMPAGNE source localization algorithm 
% (modified by A.Faloppa)
% 
% Contact details : Amorim De Cerqueira Filho, Edilberto <Edilberto.Amorim@ucsf.edu>
clear; close all; clc;

%% Configurable variables:
patient_table = 'ICARE_patient_metadata';
VERBOSE = 0; % Intermediate plot

%% Default variables and allocations
dir_data = './Data';
% dir_input = fullfile(dir_data, dataset_name);

% Get current script folder
baseDir = fileparts(mfilename('fullpath'));

% Add desired subfolders to the path
addpath(fullfile(baseDir, 'eeglab2025.0.0'));
addpath(fullfile(baseDir, 'fieldtrip-20250106'));
addpath(fullfile(baseDir, 'fieldtrip-20250106', 'external', 'eeglab'));
addpath(genpath(fullfile(baseDir, 'Source_localization_files')));
ft_defaults

% Get Patient ID
patient_list = readtable(patient_table);
job_id = unique(patient_list.Patient);


% Run sourcelocalization
% Loop over each patient
for i = 1:length(job_id)

    pid = job_id{i};  % current patient ID (string)
    
    % Find the row corresponding to this patient
    rowIdx = find(strcmp(patient_list.Patient, pid));
    
    % Convert the row to a struct
    patient_info = table2struct(patient_list(rowIdx, :));
    
    
    dir_output = fullfile(dir_data, 'OUTPUT', 'Source_Reconstruction', pid);

    try
        plot_features(patient_info, dir_output, VERBOSE);
    catch ME
        warning('Process failed (%s)', ME.message);
        disp(strcat("Problems with Patient : ", string(pid), " - Skipping..."))
    end
end

disp("Complete")