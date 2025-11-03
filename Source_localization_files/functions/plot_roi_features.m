function plot_roi_features(patient_info, output_folder)
%PLOT_PATIENT_FEATURES Combine and plot EEG feature data for a single patient
%
%   plot_patient_features(patient_info, base_folder, plot_flag, unit)
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
%       <patient_ID>_<segment>_ROI_Features.xlsx
%
%   The Excel files must have columns similar to:
%       Patient | Segment | Part | Feature_Name | Resolution | CPC | ROI1 | ROI2 | ...

    patient_ID = patient_info.Patient;

    %% Set up paths
    dir_results = fullfile(output_folder, '03_FeaturesROI');
    if ~exist(dir_results, 'dir')
        error('Results folder for patient %s not found: %s', patient_ID, dir_results);
    end

    % Create output folder for plots
    dir_plots = fullfile(output_folder, '04_FeaturePlots');
    if ~exist(dir_plots, 'dir')
        mkdir(dir_plots);
    end

    % Create output folder for nifti files
    dir_nifti = fullfile(output_folder, '05_Niftis');
    if ~exist(dir_nifti, 'dir')
        mkdir(dir_nifti);
    end

    %% Locate feature files
    files = dir(fullfile(dir_results, sprintf('%s_*_ROI_Features.xls', patient_ID)));

    if isempty(files)
        error('No ROI feature files found for patient %s in folder: %s', patient_ID, dir_results);
    end

    fprintf('Found %d files for patient %s\n', length(files), patient_ID);

    %% Prepare atlas and ROI masks
    leadfield_file = fullfile('Source_localization_files', 'leadfield_output', 'leadfield_19elec.mat');
    load(leadfield_file, 'source_on_mri', 'roi_list', 'atlas_model'); 

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
    combined_file = fullfile(dir_results, sprintf('%s_All_Segments_Features.xlsx', patient_ID));
    writetable(all_data, combined_file);
    fprintf('Combined table saved to: %s\n', combined_file);

    %% Identify features and ROIs
    feature_names = unique(all_data.Feature_Name);

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

                % Extract ROI data
                roi_values = table2array(T_part(:,8:end-1)); % ROI columns
                mean_feat = mean(roi_values, 1);             % mean value (useless now)

                %% Prepare atlas for plotting

                cfg_funparam = 'pow';

                atlas_tmp = source_on_mri;
                for r = 1:length(roi_list)
                    atlas_tmp.(cfg_funparam)(atlas_model.tissue == r) = mean_feat(r);
                end

                % Negative values are in dB, so use symmetric scaling around 0
                max_abs_val = max(abs(mean_feat));    % strongest magnitude
                clim = [-max_abs_val max_abs_val];   % symmetric around zero
                clim = [min(mean_feat) max(mean_feat)];   % symmetric around zero

                %% Save atlas_tmp as nifti for Surfice if Relative
                if strcmp(unit, "%")
                    cfg            = [];
                    cfg.filetype   = 'nifti';
                    cfg.parameter  = cfg_funparam;    % or 'avg' if changed
                    cfg.filename   = fullfile(dir_nifti, sprintf('%s_Seg%s_%s_Part%d.nii', ...
                                            patient_ID, seg, feature, part));
                    ft_volumewrite(cfg, atlas_tmp);
                    clim = [0, 70]; 
                end
                   
                % Rename the parameter in avg for FieldTrip (optional)
                % atlas_tmp.avg = atlas_tmp.pow;   % FieldTrip expects 'avg' for signed data
                
                %% Plot using FieldTrip
                cfg = [];
                cfg.method              = 'slice';
                cfg.nslices             = 16;
                cfg.funparameter        = cfg_funparam;
                cfg.funcolormap         = 'hot';      % diverging colormap
                cfg.funcolorlim         = clim;       
                cfg.maskparameter       = cfg_funparam;      
                cfg.locationcoordinates = 'mni';
                cfg.crosshair           = 'yes';
                cfg.verbose             = 'no';
                cfg.opacitymap          = 'rampup';
                cfg.opacitylim          = [clim(1)-clim(2)/2 clim(2)];

                % figure;
                fig = figure('Visible','off');
                ft_sourceplot(cfg, atlas_tmp);
                
                % Title includes segment and part
                title(sprintf('%s - %s | Segment: %s, Part: %d (%s)', ...
                    patient_ID, feature, seg, part, unit), ...
                    'Interpreter', 'none');

                % Colorbar
                h = colorbar;
                if strcmpi(unit, 'dB')
                    h.Label.String = 'Source Power [10log_{10}(\muV^2)]';
                else
                    h.Label.String = unit;
                end
                h.Label.Interpreter = 'tex';

                %% Save figure
                fig_name = sprintf('%s_Seg%s_%s_Part%d_SRC.png', ...
                    patient_ID, seg, feature, part);
                saveas(gcf, fullfile(dir_plots, fig_name));
                close(gcf);
            end
        end
    end

    fprintf('Plots saved to: %s\n', dir_plots);

end


