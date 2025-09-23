function plot_patient_features(patient_info, output_folder, plot_flag, unit)
%PLOT_PATIENT_FEATURES Combine and plot EEG feature data for a single patient
%
%   plot_patient_features(patient_info, base_folder, plot_flag, unit)
%
%   INPUTS:
%       patient_info - structure with field "Patient" (e.g., patient_info.Patient = '0284')
%       base_folder  - base directory containing the OUTPUT folder
%       plot_flag    - logical flag, if true intermediate ROI plots are shown
%       unit         - 'dB' or 'linear' (default = 'dB')
%
%   OUTPUT:
%       - Saves combined Excel file with all patient segments.
%       - Saves one PNG figure per feature, segment, and part.
%
%   FILE NAMING REQUIREMENT:
%       The script assumes each segment file follows the format:
%       <patient_ID>_<segment>_ROI_Features.xlsx
%
%   The Excel files must have columns:
%       Patient | Segment | Part | Feature_Name | Resolution | CPC | ROI1 | ROI2 | ...

    if nargin < 4
        unit = 'dB'; % default to decibels
    end

    patient_ID = patient_info.Patient;

    %% Set up paths
    dir_results = fullfile(output_folder, '03_FeaturesTables');
    if ~exist(dir_results, 'dir')
        error('Results folder for patient %s not found: %s', patient_ID, dir_results);
    end

    % Create output folder for plots
    dir_plots = fullfile(output_folder, '04_FeaturePlots');
    if ~exist(dir_plots, 'dir')
        mkdir(dir_plots);
    end

    %% Locate feature files
    files = dir(fullfile(dir_results, sprintf('%s_*_ROI_Features.xls', patient_ID)));

    if isempty(files)
        error('No ROI feature files found for patient %s in folder: %s', patient_ID, dir_results);
    end

    fprintf('Found %d files for patient %s\n', length(files), patient_ID);

    %% Prepare atlas and ROI masks
    leadfield_file = fullfile('Source_localization_files', 'MNI_DKA_Standard_Files.mat');
    load(leadfield_file, 'leadfdc', 'insideix', 'atlas');
    load('Source_localization_files/mri_data.mat', 'mri');

    % Add missing tissue labels if required
    atlas.tissuelabel{10} = 'Third_Ventricle';
    atlas.tissuelabel{11} = 'Fourth_Ventricle';
    roi_list = strrep(atlas.tissuelabel(2:end), '-', '_'); 

    % --- Interpolate atlas to source model ---
    [atlas_on_source, source_model] = interpolate_atlas_to_source(leadfdc, insideix, mri, atlas, roi_list, plot_flag);

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

    %% Identify features and ROIs
    % roi_names = all_data.Properties.VariableNames(8:end);  % ROI columns start at column 8
    feature_names = unique(all_data.Feature_Name);

    %% Loop over each feature
    for f = 1:length(feature_names)
        feature = feature_names{f};
        fprintf('Processing feature: %s\n', feature);

        % Filter rows for this feature
        rows = strcmp(all_data.Feature_Name, feature);
        T_feat = all_data(rows, :);

        % Sort by Segment and Part
        [~, sort_idx] = sortrows(T_feat, {'Segment','Part'});
        T_feat = T_feat(sort_idx, :);

        %% Loop through each segment and part
        unique_segments = unique(T_feat.Segment);

        for s = 1:length(unique_segments)
            seg = unique_segments(s);

            % Filter by this segment
            rows_seg = (string(T_feat.Segment) == seg{s});
            T_seg = T_feat(rows_seg, :);

            unique_parts = unique(T_seg.Part);

            for p = 1:length(unique_parts)
                % Filter by this part
                rows_part = (T_seg.Part == p);
                T_part = T_seg(rows_part, :);

                %% Extract ROI data
                roi_values = table2array(T_part(:,8:end)); % ROI columns
                mean_feat = mean(roi_values, 1);           % mean value per ROI

                %% Prepare atlas for plotting
                atlas_tmp = atlas_on_source;
                for r = 1:length(roi_list)
                    atlas_tmp.pow(source_model.tissue == (r+1)) = mean_feat(r);
                end

                %% Determine color limits
                clim = [nanmean(mean_feat)-1.5*nanstd(mean_feat) nanmean(mean_feat)+1.5*nanstd(mean_feat)];

                %% Plot using FieldTrip
                cfg = [];
                cfg.method               = 'slice';
                cfg.funparameter         = 'pow';
                cfg.funcolormap          = 'hot';
                cfg.funcolorlim          = clim;
                cfg.maskparameter        = 'pow';
                cfg.locationcoordinates  = 'voxel';
                cfg.crosshair            = 'yes';
                cfg.verbose              = 'no';

                figure;
                ft_sourceplot(cfg, atlas_tmp);

                % Title includes segment and part
                title(sprintf('%s - %s | Segment: %s, Part: %d (%s)', ...
                    patient_ID, feature, seg{s}, p, unit), ...
                    'Interpreter', 'none');

                % Colorbar
                h = colorbar;
                if strcmpi(unit, 'dB')
                    h.Label.String = 'Source Power [10log_{10}(\muV^2)]';
                else
                    h.Label.String = 'Source Power [a.u.]';
                end
                h.Label.Interpreter = 'tex';

                %% Save figure
                fig_name = sprintf('%s_Seg%s_Part%d_%s.png', ...
                    patient_ID, seg{s}, p, feature);
                saveas(gcf, fullfile(dir_plots, fig_name));
                close(gcf);
            end
        end
    end

    fprintf('Plots saved to: %s\n', dir_plots);

    %% Save combined table to a single Excel file
    combined_file = fullfile(dir_results, sprintf('%s_All_Segments_Features.xlsx', patient_ID));
    writetable(all_data, combined_file);
    fprintf('Combined table saved to: %s\n', combined_file);

end


