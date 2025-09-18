function [ ] = artifact_detection( PREPed_folder, output_foldern, n_workers )
%artifact_detection Applies artifact detection on all the PREPed patients.
% Assumes all the PREPed patients are stored in PREPed_folder.
% Will store the result in output_folder.
% Assumes that compute_population_statistics.m has already been run.

%   Divide the input (EEGLab format) into sub-epochs and mark them as
%   dirty/clean depending on the presence of artifacts.
%   List of artifacts: saturation, disconnect, eye movement, muscle,
%   statistical moment.
%
%   Aggregate subepochs into an epoch and compute an artifact index as the
%   ratio of dirty subepochs.
%
%   IMPORTANT: a lot of copy-paste from Ghassemi.

    %% Preliminaries.
    N_CHANNELS = 19;

    % Load patient names.
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

    %% Compute population statistics aggregations.
    stats_mat = load('stats_cell');
    stats_cell = stats_mat.stats_cell;

    % Compute global statistics aggregations
    power_0_2_band_means = cell(length(stats_cell));
    power_20_40_band_means = cell(length(stats_cell));
    kurts_aggregator = cell(length(stats_cell));
    skews_aggregator = cell(length(stats_cell));
    variance_aggregator = cell(length(stats_cell));
    for j = 1:length(stats_cell)
        power_0_2_band_means{j} = mean(stats_cell.power_0_2_band{j});
        power_20_40_band_means{j} = mean(stats_cell.power_20_40_band{j});
        kurts_aggregator{j} = reshape(stats_cell.kurtosis{j},1,size(stats_cell.kurtosis{j},1)*size(stats_cell.kurtosis{j},2));
        skews_aggregator{j} = reshape(stats_cell.skew{j},1,size(stats_cell.skew{j},1)*size(stats_cell.skew{j},2));
        variance_aggregator{j} = reshape(stats_cell.variance{j},1,size(stats_cell.variance{j},1)*size(stats_cell.variance{j},2));
    end

    %Eye_Movements where +/- 50 db from the mean in 0-2Hz Band
    eye_upper = mean(mean([power_0_2_band_means{:}]))*316;
    eye_lower = mean(mean([power_0_2_band_means{:}]))* 0.00001;.

    % Compute kurtosis' mean and std.
    this_kurt = [kurts_aggregator{:}]; this_kurt = reshape(this_kurt,1, size(this_kurt,1)*size(this_kurt,2));
    pop_m_kurt = nanmean(this_kurt);
    pop_s_kurt = nanstd(this_kurt);

    %Muscle where + 25 or -100 db from the mean in 20-40Hz band
    muscle_upper = mean(mean([power_20_40_band_means{:}]))*10^(25/10);
    muscle_lower = mean(mean([power_20_40_band_means{:}]))*10^(-100/10);

    % Compute skewness' mean and std.
    %TODO: in case interpolated data must not be used, this might have to be modified.
    this_skew = [skews_aggregator{:}]; this_skew = reshape(this_skew,1, size(this_skew,1)*size(this_skew,2));
    pop_m_skew = nanmean(this_skew);
    pop_s_skew = nanstd(this_skew);

    % Compute variance's mean and std.
    %TODO: in case interpolated data must not be used, this might have to be modified.
    this_var  = [variance_aggregator{:}]; this_var = reshape(this_var,1, size(this_var,1)*size(this_var,2));
    pop_m_var = nanmean(this_var(this_var ~= 0));
    pop_s_var = nanstd(this_var(this_var ~= 0));

    % Set various thresholds/constants.
    threshold = 1000;
    numstds = 3;
    variance_lower_threshold = 0.001;

    %% Find artifacts in all patients.
    parpool(n_workers);
    parfor index = 1:length(patient_cell)

        % Load eeg and epoch it.
        PREPed_patient_filename = char(patient_cell{k});
        ['Processing patient: ' char(PREPed_patient_filename)]
        eeg = load_mat(PREPed_patient_filename);
        eeg = pop_editset(eeg,'pnts',SUB_EPOCH_LENGTH);

        %TODO: plug in artifact related functions.
        %TODO: in case interpolated data must not be used, all these functons will have to be modified.
        rejeye = eye_artifact(stats_cell, eye_upper, eye_lower, N_CHANNELS, index);
        rejkurt = kurt_artifact( stats_cell, pop_m_kurt, pop_m_kurt, numstds, index);

    end

end
