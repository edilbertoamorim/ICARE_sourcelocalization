%{
    This file contains a script to process the an EEG dataset.
    IMPORTANT: assumes EEGLab is installed in folder eeglab_folder, with
    the necessary plug-ins (PREP pipeline)
%}

%% Preliminaries.

% Constants.
eeglab_folder = '/home/aledepo93/Programs/matlab-MIT/eeglab_current/eeglab14_1_1b';
code_folder = '/home/aledepo93/Documents/MIT/Thesis/distributed_lsh_alessandro_de_palma/EEG/scripts';
filename = 'CA_BIDMC_14_21_20120409_044314.edf';
folder = '/home/aledepo93/Documents/MIT/Thesis/distributed_lsh_alessandro_de_palma/EEG/scripts/';
SAMPLING_FREQUENCY = 256;  % Make it 100 Hz, the final sampling frequency, after the merging.
SUB_EPOCH_LENGTH = SAMPLING_FREQUENCY*5;  % 5s sub-epochs.
EPOCH_LENGTH = SAMPLING_FREQUENCY*60*5;  % 5 min epochs.
visualize = false;  % Do not perform visualization after preprocessing.

cd(eeglab_folder);  % Move to eeglab's folder, as it expects.
eeglab;  % Load eeglab paths. This needs to be executed with -nodisplay -nosplash -nodesktop.
addpath(genpath(code_folder))  % Add code's folder and its possible subpaths.

%% Preprocessing + sub-epoching + statistics.

%TODO: iterate over files.

% Read file to a struct.
eeg_struct = edf_to_struct(filename, folder);

% Unify nomenclature across hospitals, downsample, retrieve channel locations, convert to EEGLab.
standardized_struct = standardize_struct(eeg_struct);
eeg_eeglab_unprocessed = struct_to_EEGLab(standardized_struct, SUB_EPOCH_LENGTH);

% Apply PREP pipeline for basic preprocessing.
eeg_eeglab_processed = PREP_EEGLab(eeg_eeglab_unprocessed, true);

% Sub-Epoch the Data. The data matrix now becomes 3d: channels x
% subepoch_length x n_subepochs
eeg_eeglab_epoched = pop_editset(eeg_eeglab_processed,'pnts',SUB_EPOCH_LENGTH);

% Compute file's statistics.
stats = compute_statistics_EEGLab(eeg_eeglab_epoched, SAMPLING_FREQUENCY);

%% Visualization.
if visualize
    save('unprocessedEEG', 'eeg_eeglab_unprocessed');
    save('processedEEG', 'eeg_eeglab_processed');

    snapshot_length = 5;
    offset = 100;
    x = (1:SAMPLING_FREQUENCY*snapshot_length)./SAMPLING_FREQUENCY + offset;    
    
    % Plot the first channel.
    figure
    fig = plot(x, eeg_eeglab_unprocessed.data(2, SAMPLING_FREQUENCY*offset:SAMPLING_FREQUENCY*(offset+snapshot_length)-1));
    grid on
    title('Unprocessed Fp2 channel, 5s snapshot')
    xlabel('Time [s]')
    ylabel('uV')
    saveas(fig, 'unprocessed-single-5s.png')
    figure
    fig = plot(x, eeg_eeglab_processed.data(1, SAMPLING_FREQUENCY*offset:SAMPLING_FREQUENCY*(offset+snapshot_length)-1));
    grid on
    title('Processed Fp2 channel, 5s snapshot')
    xlabel('Time [s]')
    ylabel('uV')
    saveas(fig, 'processed-single-5s.png')
    % Plot the average channel.
    figure
    fig = plot(x, mean(eeg_eeglab_unprocessed.data(:, SAMPLING_FREQUENCY*offset:SAMPLING_FREQUENCY*(offset+snapshot_length)-1)));
    grid on
    title('Unprocessed average channel, 5s snapshot')
    xlabel('Time [s]')
    ylabel('uV')
    saveas(fig, 'unprocessed-5s.png')
    figure
    fig = plot(x, mean(eeg_eeglab_processed.data(:, SAMPLING_FREQUENCY*offset:SAMPLING_FREQUENCY*(offset+snapshot_length)-1)));
    grid on
    title('Processed average channel, 5s snapshot')
    xlabel('Time [s]')
    ylabel('uV')
    saveas(fig, 'processed-single-5s.png')
    saveas(fig, 'processed-5s.png')
end

%% Artifact detection and evaluation.

%TODO: compute population statistics for artifact detection.

%TODO: in the artifact_find functions, re-compute the local
    %statistics (it's clearer).
    
%TODO: add EKG artifact.


