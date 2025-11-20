function plot_chan_features(patient_info, output_folder)
%PLOT_PATIENT_FEATURES Combine and plot EEG feature data for a single patient
%
%   INPUTS:
%       patient_info - structure with field "Patient" (e.g., patient_info.Patient = '0284')
%       base_folder  - base directory containing the OUTPUT folder
%
%   OUTPUT:
%       - Saves combined Excel file with all patient segments.
%       - Saves one PNG figure per feature, segment, and part.
%
%   FILE NAMING REQUIREMENT:
%       The script assumes each segment file follows the format:
%       <patient_ID>_<segment>_EEG_Features.xlsx
%
%   The Excel files must have columns similar to:
%       Patient | Segment | Part | Feature_Name | Resolution | CPC | FP1 | FP2 | ...

    % Setup Resources
    patient_ID = patient_info.Patient;

    leadfield_file = fullfile('Source_localization_files', 'leadfield_output', 'leadfield_19elec.mat');
    load(leadfield_file, 'elec_aligned'); 

    chanNames=elec_aligned.label;

    % Optional : rename old channels
    chanNames{13} = 'T7'; % T3
    chanNames{14} = 'T8'; % T4
    chanNames{15} = 'P7'; % T5
    chanNames{16} = 'P8'; % T6

    chanNames=string(chanNames);

    %% Set up paths
    dir_results = fullfile(output_folder, '03_FeaturesCHAN');
    if ~exist(dir_results, 'dir')
        error('Results folder for patient %s not found: %s', patient_ID, dir_results);
    end

    % Create output folder for plots
    dir_plots = fullfile(output_folder, '04_FeaturePlots');
    if ~exist(dir_plots, 'dir')
        mkdir(dir_plots);
    end

    %% Locate feature files
    files = dir(fullfile(dir_results, sprintf('%s_*_EEG_Features.csv', patient_ID)));

    if isempty(files)
        error('No Sensor feature files found for patient %s in folder: %s', patient_ID, dir_results);
    end

    fprintf('Found %d files for patient %s\n', length(files), patient_ID);

    %% Load and combine feature data
    all_data = [];
    for i = 1:length(files)
        file_path = fullfile(files(i).folder, files(i).name);
        fprintf('Loading file: %s\n', files(i).name);

        T = readtable(file_path);

        % Add a column indicating which file/segment this row came from
        T.FileIndex = repmat(i, height(T), 1);

        if isempty(all_data)
            all_data = T;
        else
            all_data = [all_data; T];
        end
    end

    % Save combined table to a single Excel file
    combined_file = fullfile(dir_results, sprintf('%s_All_Segments_Features.csv', patient_ID));
    writetable(all_data, combined_file);
    fprintf('Combined table saved to: %s\n', combined_file);

    %% Identify features and load electrode layout
    feature_names = unique(all_data.Feature_Name);
    channel_labels = all_data.Properties.VariableNames(8:end-1); % assuming columns 8:end-1 are channels
    n_channels = numel(channel_labels);

    % Load standard 10-20 channel positions (adjust path if needed)
    try
        chanlocs = readlocs('Standard-10-20-Cap81.ced'); % or 'standard-10-5-cap385.elp'
    catch
        error('Could not load EEGLAB channel locations. Ensure the .elp file is on the path.');
    end

    % Filter to match available channels
    chanlocs = chanlocs(ismember({chanlocs.labels}, channel_labels));


    %% Loop over each feature
    for f = 1:length(feature_names)
        feature = feature_names{f};
        
        fprintf('Processing feature: %s\n', feature);

        % Filter rows for this feature
        rows = strcmp(all_data.Feature_Name, feature);
        T_feat = all_data(rows, :);

        unit = string(unique(T_feat.Unit));

        % Sort by Segment and Part
        [~, sort_idx] = sortrows(T_feat, {'Segment','Part'});
        T_feat = T_feat(sort_idx, :);

        %% Loop through each segment and part
        unique_segments = unique(T_feat.Segment);

        for s = 1:length(unique_segments)
            seg = unique_segments{s};

            % Filter by this segment
            rows_seg = (string(T_feat.Segment) == seg);
            T_seg = T_feat(rows_seg, :);

            unique_parts = unique(T_seg.Part);

            for p = 1:length(unique_parts)
                % Filter by this part
                part = unique_parts(p); 
                rows_part = (T_seg.Part == part);
                T_part = T_seg(rows_part, :);

                % Extract Channel data
                chan_values = table2array(T_part(:,chanNames)); % Channels columns
                mean_values = mean(chan_values, 1, 'omitnan'); % average if multiple rows per part

                % Plot topomap
                figure('Visible','off');
                topoplot(mean_values, chanlocs, 'maplimits','maxmin','style','both','electrodes','on');
                colorbar;
                title(sprintf('%s - Seg %s Part %d\n%s (%s)', ...
                    patient_ID, seg, part, feature, unit), 'Interpreter','none');
              

                %% Save figure
                fig_name = sprintf('%s_Seg%s_%s_Part%d_EEG.png', ...
                    patient_ID, seg, feature, part);
                saveas(gcf, fullfile(dir_plots, fig_name));
                close(gcf);
            end
        end
    end

    fprintf('Plots saved to: %s\n', dir_plots);

end


