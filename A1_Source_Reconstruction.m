%% Source Reconstruction
% Author: A.Faloppa
% 1/09/2025
%
% Purpose of the code: Reconstruct Source Level time series (SBL-Beamforming)
%
% Usage:
%
%   Be sure to have the following toolboxes in the pipeline directory : 
%           eeglab
%           fieldtrip 
%           wfdb-app-toolbox
%           Source_localization_files (utility folder)
%    
%   (rename folders accordingly, used toolboxes version is 2024 or later)
% 
%   Be sure to have the patient list running Get_patinets_IDs.m 
% 
%   Be sure to have the leadfield output files. These can be obtained
%   running LFM_generation.m.
% 
%   Change the .xlm patient table filename if needed in 'patient_table'
%
%   Run the script
%
% Input : 
%   Patient table and IDs to process from I-CARE dataset
%
% Output : 
%   Located Data/OUTPUT/Source_Reconstruction:
%       Patient_ID/01_EEGsegmentPlots : Figures of EEG segment processed 
%       Patient_ID/02_SourcePSDs      : .mat file with PSDs per ROI for each segment 
%       Patient_ID/03_FeaturesCHAN    : .xls files with Features computed per sensor
%       Patient_ID/03_FeaturesROI     : .xls files with Features computed per ROI
%
% This code is an adaptation of previous work by 
% G.Velasquez and running F.Jiang's CHAMPAGNE source and burst localization  
% (adapted by A.Faloppa)
% 
% Contact details : Amorim De Cerqueira Filho, Edilberto <Edilberto.Amorim@ucsf.edu>
clear; close all; clc;

%% Configurable variables:
PATIENT_TABLE  =  'ICARE_patient_metadata';
MAX_TIME       = 5;     % [minutes] Maximum minutes to analyze per patient file (suggested 5 minutes up to 10)
MAX_SEGMENTS   = 3;     % [int]     Maximum file number to analyze per patient (use >200 if want to analyse all)
VERBOSE        = 1;     % Intermediate champagne plot
split = 'training';     % I-CARE dataset split to look at (only 'training at the moment', ICARE_patient_metadata must be modified)


%% Default variables and allocations
dir_data = './Data';

% Get current script folder
baseDir = fileparts(mfilename('fullpath'));

% Add desired subfolders to the path
addpath(genpath(fullfile(baseDir, 'eeglab')));
addpath(fullfile(baseDir, 'fieldtrip'));
addpath(genpath(fullfile(baseDir, 'wfdb-app-toolbox')))
addpath(genpath(fullfile(baseDir, 'Source_localization_files')));
ft_defaults

% Get Patient ID
patient_list = readtable(PATIENT_TABLE);
job_id = unique(patient_list.Patient);


%% Run sourcelocalization
% Loop over each patient
for i = 1:length(job_id)

    pid = job_id{i};  % current patient ID (string)
    
    % Find the row corresponding to this patient
    rowIdx = find(strcmp(patient_list.Patient, pid));
    
    % Convert the row to a struct
    PATIENT_INFO = table2struct(patient_list(rowIdx, :));
    
    % Output directory for the patient
    DIR_OUTPUT = fullfile(dir_data, 'OUTPUT', 'Source_Reconstruction', pid);

    try
        Source_Reconstruction_DKA_MNI(split, PATIENT_INFO, DIR_OUTPUT, MAX_TIME, MAX_SEGMENTS, VERBOSE);
    catch ME
        warning(ME.identifier, 'Process failed (%s)', ME.message);
        disp(strcat("Problems with Patient : ", string(pid), " - Skipping..."))
    end
end

disp("Complete")