function [pt_excel_feat] = Source_Localization_DKA_MNI_new(job_id, dir_input, dir_output, dir_burst_ranges)
% SOURCE_LOCALIZATION_DKA_MNI : Adapted by A.Faloppa
% Perform burst EEG source localization using MNI lead field and Champagne inverse solution.
%
% Parameters
% ----------
% job_id : integer
%     Index of the EEG .mat file to process from dir_input.
% dir_input : char
%     Path to directory containing preprocessed EEG data files (.mat).
% dir_output : char
%     Path to directory for output.
% dir_burst_ranges : char
%     Path to directory containing CSV files with burst start and end indices.
%
% Returns
% -------
% pt_excel_feat : char
%     Filename of the Excel file containing averaged ROI power features.

%% CONFIGURATIONS
max_segment_hour = 73;
feature_name = 'Burst';
tolerance = 1e-6;

% Create output folders
out_dir = fullfile(dir_output, 'Burst_Source_Localization');
out_dir_source_loc = fullfile(out_dir, 'Burst_Sources'); % Table
out_dir_hrs = fullfile(out_dir, 'Burts_hours');          % Burst included in hr
out_dir_plots = fullfile(out_dir, 'Burst_plots');        % Visualizations\      \
cellfun(@(d) ~exist(d,'dir') && mkdir(d), {out_dir_source_loc, out_dir_hrs, out_dir_plots});

%% Load resources
leadfield_file = fullfile('Source_localization_files', 'MNI_DKA_Standard_Files.mat');
load(leadfield_file, 'LFmatrix', 'leadfdc', 'insideix', 'atlas', 'labels');
load('Source_localization_files/mri_data.mat', 'mri');
rosc_times = readtable('Source_localization_files/Source_loc_time_ROSC_local.xlsx');
all_preproc_files = dir(fullfile(dir_input, '*.mat'));
preproc_file = all_preproc_files(1).name;
preproc_data = load(fullfile(dir_input, preproc_file));
Fs = preproc_data.x.srate;

rosc_idx = find(contains(rosc_times.preproc_file, preproc_file));
t_rosc = rosc_times.time_from_rosc(rosc_idx);
time_vec = t_rosc + (1:length(preproc_data.x.data))/Fs;
preproc_data.x.time = time_vec;

%% Load burst ranges
feature_files = dir(fullfile(dir_burst_ranges, '**', '*.csv'));
[~, fileName, ~] = fileparts(preproc_file);
patient_indx = find(contains({feature_files.name}, fileName));

features_table = load_burst_ranges(feature_files, patient_indx, t_rosc);
if size(features_table,1) < 1
        disp("Signal clean...\n");
        return;
end

preproc_data.feature = features_table;

%% Prepare ROI structure
atlas.tissuelabel{10} = 'Third_Ventricle';
atlas.tissuelabel{11} = 'Fourth_Ventricle';
roi_list = strrep(atlas.tissuelabel(2:end), '-', '_');
ROI_struct = cell2struct(cell(length(roi_list),1), roi_list);

%% Initialize metadata arrays
metadata = [];
checktable = [];

%% Time loop
start_h = floor(min(time_vec)/3600);
end_h = ceil(max(time_vec)/3600);

for h = start_h:end_h-1
    if h >= max_segment_hour, continue; end
    t_start = h*3600;
    t_end = t_start + 3600;
    burst_idx = find(features_table.burst_start_index >= t_start & features_table.burst_start_index < t_end);

    if isempty(burst_idx)
        checktable = append_check(checktable, rosc_times.ptid_og(rosc_idx), preproc_file, h, 0);
        continue;
    end

    checktable = append_check(checktable, rosc_times.ptid_og(rosc_idx), preproc_file, h, 1);

    for ft = 1:min(10, length(burst_idx)) % Max 10 burst per hour
        % Get burst indices
        b_idx = burst_idx(ft);
        [ix_start, ix_end] = get_index_from_time(preproc_data.x.time, features_table{b_idx, :}, tolerance);

        % Extract segment
        segment = preproc_data.x.data(:, ix_start:ix_end);
        time_segment = preproc_data.x.time(ix_start:ix_end);

        % Plot and save EEG
        plot_filename = fullfile(out_dir_plots, sprintf('%s_Hour_%d_featNum_%d_SIGNAL.png', rosc_times.ptid_og{rosc_idx}, h, ft));
        save_eeg_plot(segment, Fs, time_segment, labels, plot_filename);

        % Run Champagne
        avg_pow = run_champagne(segment, LFmatrix, 0);

        % Map power to ROIs
        rsource = build_rsource(avg_pow, insideix, leadfdc, insideix);
        rsourceInt = interpolate_source(rsource, mri);
        sourcemodel2 = interpolate_atlas(atlas, rsourceInt);

        ROI_struct = update_roi_struct(ROI_struct, sourcemodel2, rsourceInt.pow, roi_list);

        %% Plot ROI-averaged power on MRI slices
        cfg = [];
        cfg.method        = 'slice';
        cfg.funparameter  = 'pow';
        cfg.funcolorlim   = [prctile(rsourceInt.pow, [0], "all"), ...
                             prctile(rsourceInt.pow, [100], "all")];
        cfg.maskparameter = 'pow';
        cfg.funcolormap   = 'plasma';
        cfg.opacitymap    = 'rampup';
        cfg.locationcoordinates = 'voxel';
        cfg.ori           = 'x';
        cfg.crosshair     = 'yes';
        cfg.opacitylim    = [prctile(rsourceInt.pow, [0], "all"), ...
                             prctile(rsourceInt.pow, [100], "all")];
        
        figure;
        ft_sourceplot(cfg, rsourceInt);
        
        % Save figure
        image_name = sprintf('%s_Hour_%d_featNum_%d_SOURCE.png', rosc_times.ptid_og{rosc_idx}, h, ft);
        image_name_full = fullfile(out_dir_plots, image_name);
        saveas(gcf, image_name_full)
        close(figure(1));

        % Append metadata
        metadata = append_metadata(metadata, rosc_times.ptid_og(rosc_idx), preproc_file, h, ft, feature_name);
    end
end

%% Finalize tables
Source_loc_features = [struct2table(metadata), struct2table(ROI_struct)];
feat_hours_checks = struct2table(checktable);

% Write tables
pt_excel_feat = sprintf('Source_loc_pow_feats_%s.xlsx', fileName);
writetable(Source_loc_features, fullfile(out_dir_source_loc, pt_excel_feat));

pt_excel_ft_hrs = sprintf('Source_loc_feat_hours_%s.xlsx', fileName);
writetable(feat_hours_checks, fullfile(out_dir_hrs, pt_excel_ft_hrs));
end

%% === HELPER FUNCTIONS ===

function tbl = load_burst_ranges(files, indices, t_rosc)
% Load and adjust burst start/end indices from CSV files.
%
% Parameters
% ----------
% files : struct
%     File listing from dir() containing CSV burst files.
% indices : array
%     Indices of files corresponding to the current patient.
% t_rosc : double
%     Time offset from ROSC in seconds.
%
% Returns
% -------
% tbl : table
%     Table with burst start and end times adjusted for ROSC.

    tbl = table();
    
        for i = 1:length(indices)
            T = readtable(fullfile(files(indices(i)).folder, files(indices(i)).name));
            T{:,:} = T{:,:} / 100 + t_rosc;
            tbl = [tbl; T];
        end
        if size(tbl,1) < 1
            disp("No Burst detected for this file...\n");
            return;
        end

        tbl.Properties.VariableNames = {'burst_start_index', 'burst_end_index'};
    
end

function [ix_start, ix_end] = get_index_from_time(time_vec, times, tol)
% Find the closest indices in a time vector for given start and end times.
%
% Parameters
% ----------
% time_vec : array
%     Array of time points.
% times : array
%     Two-element array with start and end times.
% tol : double
%     Tolerance for matching times.
%
% Returns
% -------
% ix_start, ix_end : integer
%     Indices in time_vec corresponding to start and end times.

    ix_start = find(abs(time_vec - times(1)) < tol, 1);
    ix_end = find(abs(time_vec - times(2)) < tol, 1);
end

function save_eeg_plot(segment, Fs, time, labels, filename)
% Save a FieldTrip EEG plot of a burst segment.
%
% Parameters
% ----------
% segment : matrix
%     EEG data segment (channels x samples).
% Fs : int
%     Sample rate.
% time : array
%     Time vector for the EEG segment.
% labels : cell array
%     Channel labels.
% filename : char
%     Path to save the generated plot.

    data.trial{1} = segment;
    data.time{1} = time;
    data.label = labels;
    % Replace bad names
    label_map = {'T7','T3'; 'T8','T4'; 'P7','T5'; 'P8','T6'};
    for i = 1:size(label_map,1)
        idx = find(strcmp(data.label, label_map{i,2}));
        if ~isempty(idx), data.label{idx} = label_map{i,1}; end
    end
    cfg.viewmode = 'vertical'; 
    cfg.blocksize = round(time(end)-time(1));
    ft_databrowser(cfg, data);
    delete(findall(gcf, 'Type', 'uicontrol'));
    saveas(gcf, filename); close(gcf); close(figure);
end

function avg_pow = run_champagne(Y, LF, plot_flag)
% Perform Champagne inverse solution and compute average power per source.
%
% Parameters
% ----------
% Y : matrix
%     EEG segment (channels x samples).
% LF : matrix
%     Lead field matrix.
% plot_flag : bool
%     Bool for plotting champagne loop.
%
% Returns
% -------
% avg_pow : matrix
%     Average power per source (sources x samples).

    y = Y';
    sigu_init = norm(y'*y)*eye(size(y,2))*1e-6;
    [~, X, ~, ~, ~, ~] = champ_noise_up(Y, LF, sigu_init, 80, 1, 0, plot_flag, 0, 0, 0, 1e-16);
    if plot_flag, close(figure(1)); end
    % Extract directional components
    N = size(X,1)/3;
    ap1 = X(1:3:end,:).^2; ap2 = X(2:3:end,:).^2; ap3 = X(3:3:end,:).^2;
    avg_pow = (ap1 + ap2 + ap3)/3;
end

function rsource = build_rsource(avg_pow, index, leadfdc, insideix)
% Build FieldTrip source structure with average power values.
%
% Parameters
% ----------
% avg_pow : matrix
%     Average power per source.
% index : array
%     Mapping indices from Champagne sources to leadfield positions.
% leadfdc : struct
%     Lead field structure.
% insideix : array
%     Inside brain voxel indices.
%
% Returns
% -------
% rsource : struct
%     FieldTrip source structure with .pow, .inside, .outside, and .pos fields.

    %Create avg.pow variable with NaN for those positions outside the brain
    rsource.avg.pow = NaN(size(leadfdc.pos,1),1);
    % Assign mean power per source to the proper spatial location
    [~, I] = sort(mean(avg_pow,2));
    for i = 1:length(I)
        rsource.avg.pow(index(I(i))) = mean(avg_pow(I(i),:));
    end
    rsource.inside = insideix;
    rsource.outside = find(~leadfdc.inside);
    rsource.method = 'average';
    rsource.pos = leadfdc.pos;
end

function rInt = interpolate_source(rsource, mri)
% Interpolate source power onto MRI volume.
%
% Parameters
% ----------
% rsource : struct
%     FieldTrip source structure.
% mri : struct
%     MRI volume.
%
% Returns
% -------
% rInt : struct
%     Interpolated source structure.

    cfg = [];
    cfg.downsample = 1; cfg.parameter = 'pow'; cfg.interpmethod = 'nearest';
    rInt = ft_sourceinterpolate(cfg, rsource, mri);
end

function sm2 = interpolate_atlas(atlas, rsourceInt)
% Interpolate atlas tissue labels onto source model.
%
% Parameters
% ----------
% atlas : struct
%     Atlas structure.
% rsourceInt : struct
%     Interpolated source structure.
%
% Returns
% -------
% sm2 : struct
%     Source model with interpolated atlas labels.
    cfg=[];
    %cfg.interpmethod = 'nearest'; 
    cfg.parameter = 'tissue';
    sm2 = ft_sourceinterpolate(cfg, atlas, rsourceInt);
end

function ROI_struct = update_roi_struct(ROI_struct, sm2, pow, roi_list)
% Update ROI structure with mean power values per region.
%
% Parameters
% ----------
% ROI_struct : struct
%     Structure holding ROI power arrays.
% sm2 : struct
%     Source model with atlas labels.
% pow : array
%     Power values for each voxel.
% roi_list : cell array
%     List of ROI names.
%
% Returns
% -------
% ROI_struct : struct

    pow(sm2.tissue == 1) = NaN; % remove 'Other'
    for i = 2:length(roi_list)+1
        voxels = sm2.tissue == i;
        m = nanmean(pow(voxels));
        ROI_struct.(roi_list{i-1})(end+1,1) = m;
    end
end

function metadata = append_metadata(metadata, id, file, hour, feat, fname)
    m.id = id; m.Preprocessed_File = file;
    m.Hour = hour; m.Feat_Number = feat; m.Feature = {fname};
    metadata = [metadata; m];
end

function checktable = append_check(checktable, id, file, hour, feat_flag)
% Append new feature metadata entry.
%
% Parameters
% ----------
% metadata : struct array
%     Existing metadata entries.
% id : char
%     Patient ID.
% file : char
%     Preprocessed file name.
% hour : integer
%     Hour of EEG recording.
% feat : integer
%     Feature number within hour.
% fname : char
%     Feature type name.
%
% Returns
% -------
% metadata : struct array
%     Updated metadata entries.

    c.id_feat_hrs = id;
    c.preproc_file_ft_hr = file;
    c.hour_ft_hr = hour;
    c.feat_yn = feat_flag;
    checktable = [checktable; c];
end