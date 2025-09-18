function [ ] = PREP_merged_files( merged_folder, output_folder, eeglab_folder, code_folder, n_workers )
%PREP_merged_files Applies the preprocessing steps until (including) the PREP
% pipeline to the merged patient files in merged_folder.
% The output is saved in output_folder according to the EEGlab format.

    %% Constants.
    SAMPLING_FREQUENCY = 100;  % We set it so during the merging.
    SUB_EPOCH_LENGTH = SAMPLING_FREQUENCY*5;  % 5s sub-epochs.

    %% Preliminaries.
    addpath(genpath(eeglab_folder)) % Add eeglab to path.
    cd(eeglab_folder);  % Move to eeglab's folder, as it expects.
    eeglab;  % Load eeglab paths. This needs to be executed with -nodisplay -nosplash -nodesktop.
    addpath(genpath(code_folder))  % Add code's folder and its possible subpaths.

    %% Get list of files.
    system(['find ' char(merged_folder) ' -print | grep "merged.mat" > merged_list.txt']);

    %Read the just created file with all patients on separate lines, line by line.
    fid = fopen('merged_list.txt');
    patient_filename = fgetl(fid);  % Merged file associated to a given patient.

    % Create cell array of patient filenames.
    patient_cell = {};
    iteration = 1;
    while ischar(patient_filename)
       patient_cell{iteration} = string(patient_filename);

       patient_filename = fgetl(fid);
       iteration = iteration + 1;
    end
    fclose(fid);

    %% Preprocessing.
    parpool(n_workers);
    % Iterate on patients.
    parfor k=1:length(patient_cell)

        merged_patient_filename = char(patient_cell{k});
        ['Processing patient: ' char(merged_patient_filename)]

        % Load merged patient as a struct.
        merged_struct = load_mat(merged_patient_filename);
        [filepath,name,ext] = fileparts(merged_patient_filename);
        merged_struct.name = name;
        % Retrieve channel locations and convert to EEGLab.
        eeg_eeglab_unprocessed = struct_to_EEGLab(merged_struct, SUB_EPOCH_LENGTH);
        % Apply PREP pipeline for basic preprocessing.
        eeg_eeglab_processed = PREP_EEGLab(eeg_eeglab_unprocessed);

        % Compute per-patient average of removed channels.
        sum = 0;
        for j = 1:length(eeg_eeglab_processed.interpolatedChannels)
            sum = sum + length(eeg_eeglab_processed.interpolatedChannels{j});
        end
        avg_removed = sum/length(eeg_eeglab_processed.interpolatedChannels);
        ['Number of removed channels: ' char(num2str(avg_removed))]

        % Save to file.
        save_eeglab_to_mat(eeg_eeglab_processed, output_folder);

        merged_struct = [];
    end

end
