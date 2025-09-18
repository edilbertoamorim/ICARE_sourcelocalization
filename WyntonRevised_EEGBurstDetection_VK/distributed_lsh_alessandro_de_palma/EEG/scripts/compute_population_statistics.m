function [ ] = compute_population_statistics( PREPed_folder, output_folder )
%compute_population_statistics Computes population statistics on all the PREPed patients.
% The output is saved to a "stats_cell.mat" file. Only one field, stats_cell.
% This file contains a cell of stats (format as in compute_statistics_EEGLab) ordered according
% to global_PREPed_list.txt, created here.

    %% Preliminaries.
    SAMPLING_FREQUENCY = 100;
    SUB_EPOCH_LENGTH = SAMPLING_FREQUENCY*5; % 5s subepochs.

    % List all the PREPed files.
    system(['find ' char(PREPed_folder) ' -print | grep "patient_" > global_PREPed_list.txt']);
    % Read the just created file with all patients on separate lines, line by line.
    fid = fopen('global_PREPed_list.txt');
    patient_filename = fgetl(fid);  % File associated to a given patient, containing all the patients.
    % Create cell array of patient filenames.
    patient_cell = {};
    iteration = 1;
    while ischar(patient_filename)
        patient_cell{iteration} = string(patient_filename);

        patient_filename = fgetl(fid);
        iteration = iteration + 1;
    end
    fclose(fid);

    %% Compute statitics.
    stats_cell = cell(length(patient_cell)); % Pre-allocate the cell for the stats.
    % Execute in parallel on 12 workers.
    parpool(12);
    parfor index = 1:length(patient_cell)

        PREPed_patient_filename = char(patient_cell{k});
        ['Processing patient: ' char(PREPed_patient_filename)]

        % Load merged patient as a struct and epoch it.
        eeg = load_mat(PREPed_patient_filename);.
        eeg = pop_editset(eeg,'pnts',SUB_EPOCH_LENGTH); % Epoching.

        stats_cell{index} = compute_statistics_EEGLab(eeg, SAMPLING_FREQUENCY);
    end

    % Save to file.
    save('stats_cell', 'stats_cell', '-v7.3');

end
