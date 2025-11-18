function Source_Reconstruction_DKA_MNI(patient_info, dir_output, max_time, max_segments, plot_flag)
% SIGNAL_SOURCE_RECONSTRUCTION
% Performs EEG source reconstruction on raw signals.
% Runs Champagne, use Beamforming, PCA for dimensionality reduction, and
% compute and save PSDs (average per ROI)
%
% Parameters
% ----------
% patient_info : struct
%     Patient metadata from physionet.
% dir_ouput : char
%     Path to directory for output files.
% max_time : numeric
%     Maximum number of minutes to include in analysis for each file.
% max_segments : numeric
%     Maximum number of files per patient to analyse.
% plot_flag : logical
%     If true, plots intermidiate figures.
%
% Output
% ------
% PSDs mat files.

    ft_info off

    % --- Configurations ---
    % c.Preprocessing
    F_interpolation = 100;       % Resampling Frequency [Hz]
    heavy_artifact_rej = false;  % TRUE = Use dipole fitting for ICA artifact rejection

    band_pass = [0.5 45];        % Band pass cut-off freqencies [Hz]

    plot_y_scale = [-7 7]*1e3;   % Fixed amplitude scaling [µV]

    % c.Features
    feature_resolution = 30;     % features time resolution [sec]

    % c.Spectral Analysis
    epoch_length = 10;      %[s]
    overlap = 0.5;         %[a.u.]

    % c.Reconstruction
    champ_iter = 80;                  %[Champagne iterations]
    n_dir = 3;                        %[Reconstruction directions (x,y,z)]
    reconstruction_resolution = 1;    %[min] (PSDs - Signal time window [minutes])

    
    

    %% --- Load resources ---
    leadfield_file = fullfile('Source_localization_files', 'leadfield_output', 'leadfield_19elec.mat');
    load(leadfield_file, 'LF_low', 'LF_high', 'elec_aligned', 'roi_list', 'ROI_mask'); 

    sensor_labels=elec_aligned.label;

    clear('leadfield','inside_idx', 'elec_aligned') 

    % leadfield_file = fullfile('Source_localization_files', 'MNI_DKA_Standard_Files.mat');
    % load(leadfield_file, 'LFmatrix', 'leadfdc', 'insideix', 'atlas', 'labels');

    % --- Create output directories ---
    dir_out = fullfile(dir_output);
    dir_eegplot = fullfile(dir_out, '01_EEGsegmentPlots');
    dir_psd  = fullfile(dir_out, '02_SourcePSDs');
    dir_table_plain  = fullfile(dir_out, '03_FeaturesCHAN');
    dir_table  = fullfile(dir_out, '03_FeaturesROI');
    dir_figs  = fullfile(dir_out, '04_FeaturePlots');
    cellfun(@(d) ~exist(d,'dir') && mkdir(d), {dir_table, dir_table_plain, dir_figs, dir_eegplot, dir_psd});

    % --- Preapre data ---
    patient_ID = patient_info.Patient;
    time_from_ROSC = patient_info.ROSC;
    CPC = patient_info.CPC;

    % Get patient filenames from physionet
    [eegFiles, segments] = get_ICARE_EEG_files(patient_ID);

    % Resume from last feature table produced if existent
    [start_file_idx, p_start, last_seg, last_part] = get_resume_point(dir_table, patient_ID, segments); 

    i_file = start_file_idx;

    while i_file < i_file+3
        
        fprintf('File: %s  | Segment: %s\n', eegFiles{i_file}, segments{i_file});
        file_name_prefix = sprintf('%s_%s_', patient_ID, segments{i_file});
    
        % Load EEG (supposed in microvolts)
        [signal, Fs_acquisition, chanNames, utilityFreq, start_h, ~] = ...
            load_ICARE_EEG(patient_ID, segments{i_file});

        % If the segment is not long enough skip
        if Fs_acquisition*length(signal) < 60*max_time
            disp("Segment too short - Skipping...")
            continue
        end

        % Sort and drop channels labels
        [signal, chanNames] = filter_ch_labels(signal, chanNames, sensor_labels);

        % Optional : rename old channels
        chanNames{1,13} = 'T7'; % T3
        chanNames{1,14} = 'T8'; % T4
        chanNames{1,15} = 'P7'; % T5
        chanNames{1,16} = 'P8'; % T6

        % Convert start time to datetime
        if strcmp(start_h(1:2), '24')
            start_h = ['00' start_h(3:end)];  % replace 24 with 00
            t_start = datetime(start_h, 'InputFormat', 'HH:mm:ss') + days(1);
        else
            t_start = datetime(start_h, 'InputFormat', 'HH:mm:ss');
        end
                
        % Segmenting EEG into chunks of reconstruction_resolution minutes
        segment_samples = max_time * 60 * Fs_acquisition;

        % Extract segment
        segment_signal = signal(1:segment_samples+1, :)';
        clear("signal");
        
        try 
        
        % Preprocess
        [segment_signal_clean, time_clean, Fs, n_bad_interp] = preprocess_eeg_segment(segment_signal, chanNames, Fs_acquisition, ...
            'Bandpass', band_pass, ...
            'Downsample', F_interpolation, ...
            'BadThresh', 5, ...
            'useDipoleFit', heavy_artifact_rej, ...
            'LineFreq', utilityFreq);
        n_samples = size(segment_signal_clean, 2);      % number of time samples
        
        fprintf('Segment %s processed. Bad channels interpolated: %d\n', segments{i_file}, n_bad_interp);

        if n_bad_interp > 5
            % Skip further processing for segments with too many bad channels
            fprintf('Skipping segment %d due to excessive bad channels.\n', s);
            continue;
        end

        % Plot signal
        plot_sensors_signals(segment_signal_clean, time_clean, chanNames, Fs, plot_y_scale)
        
        image_name_full = fullfile(dir_eegplot, strcat(file_name_prefix, "EEG_signal"));
        ui_controls = findall(gcf, 'Type', 'uicontrol');
        delete(ui_controls);
        saveas(gcf, image_name_full, 'png');
        close(figure(1)); 

        %% Extract sensor space features
        features_samples = feature_resolution*Fs;
        feature_segments = n_samples/features_samples;

        info = struct( ...
            'Fs', Fs, ...
            'patientID', char(patient_ID), ...
            'CPC', CPC, ...
            't_start', t_start,...
            'segmentID', segments{i_file}, ...
            'partID', '', ...
            'resolution', feature_resolution, ...
            'epoch_length', epoch_length, ...   % in samples or seconds 
            'overlap', overlap);

        Features_plain_EEG = [];

        for part = 1:feature_segments

            signal_part_index = (part-1)*features_samples+1:part*features_samples;

            signal_part = segment_signal_clean(:, signal_part_index);

            info.partID = part;
            info.t_start = info.t_start + seconds((part-1)*feature_resolution);
            partial_features = extract_eeg_features(signal_part, info, chanNames, []);

            Features_plain_EEG = [Features_plain_EEG; partial_features];
        end
  
        % tmp_EEG = [];
        % tmp_EEG.setname = strcat(file_name_prefix, "EEG_Features");
        % tmp_EEG.srate = Fs;
        % tmp_EEG.nbchan = length(chanNames);
        % tmp_EEG.pnts = size(segment_signal_clean,2);
        % tmp_EEG.data = segment_signal_clean;
        % sensor_features = EEG_extract_feature_chan(tmp_EEG, feature_resolution);
        % Features_plain_EEG = format_features(sensor_features, info, feature_segments, chanNames);

        excel_filename = fullfile(dir_table_plain, strcat(file_name_prefix, "EEG_Features"));
        writetable(Features_plain_EEG, excel_filename, "FileType", "spreadsheet");

        clear('Features_plain_EEG','cfg','segment_signal', 'image_name_full', 'partial_features', ...
              'excel_filename', 'n_bad_interp', 'data_fieldtrip') 

        %% === Run Champagne ===
        disp("Running Champagne...")

        total_cols_low = size(LF_low,2);
        total_cols_high = size(LF_high,2);
    
        disp(['Number of voxels champagne low res: ', num2str(total_cols_low / n_dir)]);
        disp(['Number of voxels reconstruction high res: ', num2str(total_cols_high / n_dir)]);

        voxel_ts = zeros(total_cols_high / n_dir, n_samples);

        % Divide the segment in single minutes for reconstruction
        for reconstruction_minute=1:max_time/reconstruction_resolution
            
            reconstruction_index = (reconstruction_minute-1)*60*Fs+1:reconstruction_minute*60*Fs;

            signal_clean_part = segment_signal_clean(:,reconstruction_index);

            % Run Reconstruction
            voxel_ts_part = run_SBL_Beamformer(signal_clean_part, LF_low, LF_high, champ_iter, n_dir, plot_flag);
            voxel_ts(:,reconstruction_index) = voxel_ts_part;

        end

        n_voxels = size(voxel_ts, 1);
          
        disp('Source reconstruction complete');

        %% Spectral Analysis
        disp("Spectral Analysis...")
        % Preallocate PSD storage
        % Using pwelch: output will be [n_freqs x n_voxels]
        % Compute PSD for the first voxel to get freq vector
        n_samples_epoch = epoch_length * Fs;
        n_overlap = floor(n_samples_epoch * overlap);
        [pxx,freqs] = pwelch(voxel_ts(1,:), n_samples_epoch, n_overlap, n_samples_epoch, Fs);
        n_freqs = length(freqs);
        psd_voxels = zeros(n_voxels, n_freqs);
        psd_voxels(1,:) = pxx';

        % Compute PSD for all voxels
        for v = 2:n_voxels
            [pxx,~] = pwelch(voxel_ts(v,:), n_samples_epoch, n_overlap, n_samples_epoch, Fs);
            psd_voxels(v,:) = pxx';
        end

        % Average PSD per ROI
        PSD_data = struct();
        ROI_psd = struct();

        % Save needed info
        ind_freq = freqs>0 & freqs<=45;
        freqs=freqs(ind_freq);

        % Average according to ROI mask
        for i = 1:length(roi_list)
            mask = ROI_mask.(roi_list{i});
            if any(mask)
                ROI_psd.(roi_list{i}) = mean(psd_voxels(mask,ind_freq),1);
            else
                ROI_psd.(roi_list{i}) = nan(1,length(ind_freq));
            end
        end


        % Plot random ROI PSDs
        n_rand = 5;  % number of random PSDs to plot
        n_rois = size(roi_list, 1);

        % Random selection of voxel indices
        %rng('shuffle');  % ensures different random picks each run
        rand_idx = randperm(n_rois, min(n_rand, n_rois));

        % Plot
        fig = figure('Visible','on');
        for i = 1:length(rand_idx)
            plot(freqs, 10*log10(ROI_psd.(roi_list{rand_idx(i)})), 'LineWidth', 1.2);
            hold on;
        end
        xlabel('Frequency (Hz)');
        ylabel('Power (dB)');
        title('10 Random ROI PSDs');
        legend({roi_list{rand_idx}})
        grid on;
        hold off;
        image_name =sprintf('%s_PSD_%s', patient_ID, segments{i_file});
        image_name_full = fullfile(dir_psd,image_name);
        saveas(gcf,image_name_full,'png');
        close(figure);

        % Save average PSD per ROI
        disp("Saving average PSD per ROI")

        % Build a structure to save
        PSD_data.patient_ID = patient_ID;
        PSD_data.psd_resolution = max_time;
        PSD_data.CPC = CPC;
        PSD_data.ROI_names = roi_list;
        PSD_data.freqs = freqs;
        PSD_data.ROI_psd = ROI_psd;

        % Save as .mat
        mat_filename = fullfile(dir_psd, sprintf('%s_Seg%s_ROI_PSD', patient_ID, segments{i_file}));
        save(mat_filename, '-struct', 'PSD_data');
        disp(['Saved ROI PSD data to: ', mat_filename]);
        
        %% Compute average bandpower per ROI (source space)
        disp("Computing average features per ROI...")

        Features_source_EEG = [];

        for part = 1:feature_segments

            signal_part_index = (part-1)*features_samples+1:part*features_samples;

            signal_part = voxel_ts(:, signal_part_index);

            info.partID = part;
            info.t_start = info.t_start + seconds((part-1)*feature_resolution);
            partial_features = extract_eeg_features(signal_part, info, roi_list, ROI_mask);

            Features_source_EEG = [Features_source_EEG; partial_features];
        end
        
        % tmp_EEG = [];
        % tmp_EEG.setname = strcat(file_name_prefix, "ROI_Features");
        % tmp_EEG.srate = Fs;
        % tmp_EEG.nbchan = length(voxel_ts);
        % tmp_EEG.pnts = size(voxel_ts,2);
        % tmp_EEG.data = voxel_ts;
        % sources_features = EEG_extract_feature_chan(tmp_EEG);
        % Features_source_EEG = format_features(sources_features, info, feature_segments, roi_list);

        
        % Save to Excel
        excel_filename = fullfile(dir_table, strcat(file_name_prefix, "ROI_Features"));
        writetable(Features_source_EEG, excel_filename, "FileType", "spreadsheet");

        disp(['Saved ROI features to: ', excel_filename]);

        clear('Features_source_EEG','PSD_data','mat_filename', 'image_name_full', 'partial_features', ...
              'excel_filename', 'voxel_ts', 'voxel_ts_part', 'ROI_psd', 'fig', 'psd_voxels', 'signal_part', ...
              'ui_controls', 'time_clean', 'pxx', 'segment_signal_clean', 'signal_clean_part');

        % Next file
        i_file=i_file+1;

        catch
        fprintf("Problems with Segment %s. Skipping...\n", segments{i_file});
        end
          
    end  
end



%% --- Helper functions ---


function [eegFiles, segments] = get_ICARE_EEG_files(patientID)
%GET_ICARE_EEG_FILES Fetch all EEG filenames for a given patient from PhysioNet.
%
%   [eegFiles, segments] = get_ICARE_EEG_files(patientID)
%
%   Inputs:
%       patientID - string or char, e.g., '0284'
%
%   Outputs:
%       eegFiles  - cell array of EEG filenames (including _EEG.mat)
%       segments  - cell array of segment IDs, e.g., '001_004'

    if ischar(patientID), patientID = string(patientID); end

    % Base URL
    baseURL = 'https://physionet.org/files/i-care/2.1/training/';
    patientURL = sprintf('%s%s/', baseURL, patientID);

    % Read HTML of patient folder
    try
        listingHTML = webread(patientURL);
    catch
        error('Could not access folder for patient %s', patientID);
    end

    % Extract EEG filenames ending with _EEG.mat
    matches = regexp(listingHTML, 'href="([^"]+_EEG\.mat)"', 'tokens');
    eegFiles = [matches{:}];  % convert from cell of cells to cell array

    % Extract segment IDs from filenames
    segments = cell(size(eegFiles));
    for k = 1:length(eegFiles)
        [~, name, ~] = fileparts(eegFiles{k});
        tokens = split(name, '_');
        if length(tokens) >= 3
            segments{k} = strjoin(tokens(2:3), '_');  % e.g., '001_004'
        else
            segments{k} = '';
        end
    end
end

function formatted_features = format_features(feature_struct, infoStruct, feature_segments, chanNames)

    Fs         = infoStruct.Fs;
    epochLen   = infoStruct.epoch_length;
    overlap    = infoStruct.overlap;

    patientID  = infoStruct.patientID;
    segmentID  = infoStruct.segmentID;
    CPC        = infoStruct.CPC;
    resolution = infoStruct.resolution;

    f_names = fieldnames(feature_struct);

    formatted_features = [];

    for part = 1:feature_segments
        for ft = 1:length(f_names)-1

            ft_name = f_names(ft+1);
            ft_values = feature_struct.(ft_name{1})(:,part)';

            partID  = part;
            t_start = infoStruct.t_start + seconds((part-1)*10);

            featTable = table({patientID}, {segmentID}, partID, {CPC}, {t_start}, resolution, Fs, ft_name, "nan", ...
                'VariableNames', {'Patient','Segment','Part','CPC','Start_Time','Sec_Resolution','Fs','Feature_Name','Unit'});
            featValues = array2table(ft_values, 'VariableNames', matlab.lang.makeValidName(chanNames));

            partial_feature = [featTable, featValues];


            formatted_features = [formatted_features; partial_feature];
        end
    end

end

function plot_sensors_signals(segment_signal_clean, time_clean, chanNames, Fs, plot_y_scale)
    % --- Convert to FieldTrip format for plotting ---
    data_fieldtrip = [];
    data_fieldtrip.trial{1} = segment_signal_clean;   % channels × samples
    data_fieldtrip.time{1}  = time_clean;             % seconds
    data_fieldtrip.label    = chanNames;
    data_fieldtrip.fsample  = Fs;
    
    % --- Save segment plot ---
    cfg = [];
    cfg.viewmode = 'vertical';
    cfg.blocksize = time_clean(end) - time_clean(1) +1;
    cfg.ylim = plot_y_scale;   % Fixed amplitude scaling (in µV)
    % Create invisible figure
    fig = figure('Visible','off');
    ft_databrowser(cfg, data_fieldtrip);
end
