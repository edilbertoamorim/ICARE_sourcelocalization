%{
    Preprocess with PREP (after standardization) an edf file and visualize it with EEGLab tools.
%}

%% Preliminaries.
eeglab_folder = '/home/aledepo93/Programs/matlab-MIT/eeglab_current/eeglab14_1_1b';
code_folder = '/home/aledepo93/Documents/MIT/Thesis/distributed_lsh_alessandro_de_palma/EEG/scripts';
filename = 'CA_BIDMC_14_21_20120409_044314.edf';
file_folder = '/home/aledepo93/Documents/MIT/Thesis/distributed_lsh_alessandro_de_palma/EEG/scripts/';
visualize = false;  % Do not perform visualization after preprocessing.
bipolar = false;  % Use bipolar montage.
remove_channels = false;
save_mat = false;

cd(eeglab_folder);  % Move to eeglab's folder, as it expects.
eeglab;  % Load eeglab paths. This needs to be executed with -nodisplay -nosplash -nodesktop.
addpath(genpath(code_folder))  % Add code's folder and its possible subpaths.

%% Preprocessing + sub-epoching + statistics.

% Read file to a struct.
eeg_struct = edf_to_struct(filename, file_folder);

SAMPLING_FREQUENCY = eeg_struct.header.frequency(1);  % This assumes that the sampling frequency does not change across channels.
SUB_EPOCH_LENGTH = SAMPLING_FREQUENCY*5;  % 5s sub-epochs.

% Unify nomenclature across hospitals, downsample, retrieve channel locations, convert to EEGLab.
standardized_struct = standardize_struct(eeg_struct);
eeg_eeglab_unprocessed = struct_to_EEGLab(standardized_struct, SUB_EPOCH_LENGTH);

% Apply PREP pipeline for basic preprocessing.
eeg_eeglab_processed = PREP_EEGLab(eeg_eeglab_unprocessed);

%% Visualization.
if bipolar
    eeg_eeglab_processed = get_bipolar_montage_EEGLab(eeg_eeglab_processed);
    eeg_eeglab_unprocessed = get_bipolar_montage_EEGLab(eeg_eeglab_unprocessed);
end

pop_eegplot(eeg_eeglab_processed)

if save_mat
    save('eeg_eeglab_processed', 'eeg_eeglab_processed')
    save('eeg_eeglab_unprocessed', 'eeg_eeglab_unprocessed')
end
