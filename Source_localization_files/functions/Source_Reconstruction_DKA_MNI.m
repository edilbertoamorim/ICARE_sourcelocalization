function Source_Reconstruction_DKA_MNI(patient_info, dir_output, max_min, plot_flag)
% SIGNAL_SOURCE_RECONSTRUCTION
% Performs EEG source reconstruction on raw signals (hourly segmentation).
% Runs Champagne, use Beamforming, PCA for dimensionality reduction, and
% compute and save PSDs (average per ROI)
%
% Parameters
% ----------
% patient_info : struct
%     Patient metadata from physionet.
% dir_ouput : char
%     Path to directory for output files.
% max_min : numeric
%     Maximum number of minutes to include in analysis for each file.
% plot_flag : logical
%     If true, plots intermidiate figures.
%
% Output
% ------
% PSDs mat files.

    %ft_defaults

    % --- Configurations ---
    % c.Preprocessing
    F_interpolation = 100;
    heavy_artifact_rej = false;

    % c.Reconstruction
    champ_iter = 15;    %[Champagne iterations]
    n_dir = 3;          %[Reconstruction directions (x,y,z)]

    % c.Spectral Analysis
    epoch_length = 5;      %[s]
    overlap = 0.5;         %[a.u.]
    psd_resolution = 1;    %[min] (Average psds over x minutes)

    % --- Load resources ---
    leadfield_file = fullfile('Source_localization_files', 'leadfield_output', 'leadfield_19elec.mat');
    load(leadfield_file, 'LFmatrix', 'leadfield', 'inside_idx', 'elec_aligned'); 
    leadfdc = leadfield; insideix = inside_idx; labels=elec_aligned.label;
    load(fullfile('Source_localization_files', 'MNI_DKA_Standard_Files.mat'), 'atlas');

    % leadfield_file = fullfile('Source_localization_files', 'MNI_DKA_Standard_Files.mat');
    % load(leadfield_file, 'LFmatrix', 'leadfdc', 'insideix', 'atlas', 'labels');

    % --- Create output directories ---
    dir_out = fullfile(dir_output);
    dir_eegplot = fullfile(dir_out, '01_EEGsegmentPlots');
    dir_psd  = fullfile(dir_out, '02_SourcePSDs');
    dir_table  = fullfile(dir_out, '03_FeaturesTables');
    dir_figs  = fullfile(dir_out, '04_FeaturePlots');
    cellfun(@(d) ~exist(d,'dir') && mkdir(d), {dir_table, dir_figs, dir_eegplot, dir_psd});

    % --- Preapre data ---
    patient_ID = patient_info.Patient;
    time_from_ROSC = patient_info.ROSC;
    CPC = patient_info.CPC;

    % Get patient filenames from physionet
    [eegFiles, segments] = get_ICARE_EEG_files(patient_ID);

    % Resume from last feature table produced if existent
    [start_file_idx, p_start, last_seg, last_part] = get_resume_point(dir_table, patient_ID, segments);

    % --- Prepare ROI structure ---
    atlas.tissuelabel{10} = 'Third_Ventricle';
    atlas.tissuelabel{11} = 'Fourth_Ventricle';
    roi_list = strrep(atlas.tissuelabel(2:end), '-', '_');
    ROI_struct = cell2struct(cell(length(roi_list),1), roi_list);

    % --- Build dummy source model to get voxels mask ---
    ROI_mask = get_ROI_mask(atlas, leadfdc, insideix, roi_list);     

    for i_file = start_file_idx:length(eegFiles)
        
        fprintf('File: %s  | Segment: %s\n', eegFiles{i_file}, segments{i_file});
    
        % Load EEG (supposed in microvolts)
        [signal, Fs_acquisition, chanNames, utilityFreq, start_h, end_h] = ...
            load_ICARE_EEG(patient_ID, segments{i_file});

        % Sort and drop channels labels
        [signal, chanNames] = filter_ch_labels(signal, chanNames, labels);

        % --- Convert start time to datetime ---
        % if strcmp(start_h(1:2), '24')
        %     start_h = ['00' start_h(3:end)];  % replace 24 with 00
        %     tStart = datetime(start_h, 'InputFormat', 'HH:mm:ss') + days(1);
        % else
        %     tStart = datetime(start_h, 'InputFormat', 'HH:mm:ss');
        % end
                
        % --- Segmenting EEG into chunks of psd_resolution minutes ---
        samplesPerSeg = psd_resolution * 60 * Fs_acquisition;
        nSeg = floor(size(signal,1) / samplesPerSeg);

        % If max_min set, process only max_min [minutes] from the start of file
        if max_min
            max_nSeg = min(max_min, nSeg*psd_resolution); end
               
            for s = p_start:max_nSeg

              try 

    
                idxStart = (s-1)*samplesPerSeg + 1;
                idxEnd   = s*samplesPerSeg;
                
                % Extract segment
                segSignal = signal(idxStart:idxEnd, :)';
                
                % Time vector for this segment (seconds)
                % tVec = (0:(size(segSignal,2)-1))/Fs;
                % tVec_datetime = tStart + seconds(tVec);
                % hourVec = hours(tVec_datetime - tStart);
            
                % Preprocess
                [segSignal_clean, tVec_clean, Fs, n_bad_interp] = preprocess_eeg_segment(segSignal, chanNames, Fs_acquisition, ...
                    'Bandpass', [0.5 45], ...
                    'Downsample', F_interpolation, ...
                    'BadThresh', 5, ...
                    'useDipoleFit', heavy_artifact_rej, ...
                    'LineFreq', utilityFreq);
                
                fprintf('Segment %d processed. Bad channels interpolated: %d\n', s, n_bad_interp);
    
                if n_bad_interp > 5
                    % Skip further processing for segments with too many bad channels
                    fprintf('Skipping segment %d due to excessive bad channels.\n', s);
                    continue;
                end

                % --- Convert to FieldTrip format ---
                data_fieldtrip = [];
                data_fieldtrip.trial{1} = segSignal_clean;   % channels × samples
                data_fieldtrip.time{1}  = tVec_clean;        % seconds
                data_fieldtrip.label    = chanNames;
                data_fieldtrip.fsample  = Fs;
                
                % --- Optional: rename channels if needed ---
                % data_fieldtrip.label{1,8}  = 'T7'; % T3
                % data_fieldtrip.label{1,12} = 'T8'; % T4
                % data_fieldtrip.label{1,13} = 'P7'; % T5
                % data_fieldtrip.label{1,17} = 'P8'; % T6
                
                % --- Save segment plot ---
                cfg = [];
                cfg.viewmode = 'vertical';
                cfg.blocksize = tVec_clean(end) - tVec_clean(1);
                % Create invisible figure
                fig = figure('Visible','off');
                ft_databrowser(cfg, data_fieldtrip);
                
                image_name_full = fullfile(dir_eegplot, sprintf('%s_EEG_%sp%d', patient_ID, segments{i_file}, s));
                ui_controls = findall(gcf, 'Type', 'uicontrol');
                delete(ui_controls);
                saveas(gcf, image_name_full, 'png');
                close(figure(1)); 
    
                %% === Run Champagne ===
                Y = segSignal_clean; % channels x samples
                sigu_init = norm(Y*Y')*eye(size(Y',2))*1e-6;
    
                % [n_sensors, total_cols] = size(LFmatrix);
                % n_voxels = total_cols / 3;
                % 
                % % Preallocate interleaved leadfield
                % LF_interleaved = zeros(n_sensors, total_cols);
                % 
                % % Reorder from grouped -> interleaved
                % for v = 1:n_voxels
                %     LF_interleaved(:, (v-1)*3 + (1:3)) = LFmatrix(:, [v, v + n_voxels, v + 2*n_voxels]);
                % end
                % gammainit=ones(n_dir,n_dir,n_voxels);
                % [Gamma,s,w,cost,k,dGamma]=champagne_plain(Y,LFmatrix,sigu_init,champ_iter,gammainit,n_dir);
                
                disp("Running Champagne...")
                [Gamma_y,~,~,~,~,Sigma_y] = champ_noise_up(Y, LFmatrix, sigu_init, champ_iter, n_dir, 0, plot_flag, 0, 2, 1, 1e-16);
                if plot_flag, close(figure(1)); end
    
                %% Beamformer Source Reconstruction using Champagne Posterior
                n_voxels  = size(LFmatrix, 2) / n_dir;  % n_dir = number of orientations (usually 3)
                n_sensors = size(LFmatrix, 1);          % e.g., 19 sensors
                n_samples = size(Y, 2);                 % number of time samples
                
                disp(['Number of voxels: ', num2str(n_voxels)]);
                
                % Build full block-diagonal Gamma (source prior covariance)
                disp('Building block-diagonal Gamma...');
                Gamma_blocks = cell(1, n_voxels);
                for v = 1:n_voxels
                    Gamma_blocks{v} = Gamma_y(:,:,v);  % 3x3 covariance for voxel v
                end
                Gamma_full = blkdiag(Gamma_blocks{:});  % [3*n_voxels x 3*n_voxels]
                
                % Compute inverse noise covariance
                invSigmaY = pinv(Sigma_y);  % Regularized inverse may be better for noisy data
                
                % Compute posterior mean of sources
                % Formula: X_hat = Gamma * L' * inv(Sigma_y) * Y
                disp('Computing posterior mean...');
                X_hat = Gamma_full * LFmatrix' * invSigmaY * Y;  % [3*n_voxels x n_samples]
                
                % PCA reduction per voxel
                disp('Reducing 3 orientations → 1 time series per voxel using PCA...');
                voxel_ts = zeros(n_voxels, n_samples);  % final output: [n_voxels x n_samples]
                
                for v = 1:n_voxels
                    idx = (v-1)*n_dir + (1:n_dir);  % indices for the 3 orientations of voxel v (grouped, not interleaved)
                    S_v = X_hat(idx, :);            % [3 x n_samples]
                    
                    % Center the data across time
                    S_v = S_v - mean(S_v, 2);
                
                    % PCA using SVD
                    [U,~,~] = svd(S_v, 'econ');     % U: [3 x 3]
                    voxel_ts(v, :) = U(:,1)' * S_v; % Project onto first principal component
                end
                
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
                % atlas.tissue: voxel-to-ROI mapping
                % roi_list: list of ROI names (excluding 'Other')
                % psd_voxels: [n_voxels x n_freqs] for the current patient
                ROI_psd = struct();
    
                % Save needed info
                ind_freq = freqs<utilityFreq;
                freqs=freqs(ind_freq);
                ROI_psd.freq=freqs;
                ROI_psd.ROI_names=roi_list;
                
                for i = 1:length(roi_list)
                    mask = ROI_mask.(roi_list{i});
                    if any(mask)
                        ROI_psd.(roi_list{i}) = mean(psd_voxels(mask,ind_freq),1);
                    else
                        ROI_psd.(roi_list{i}) = nan(1,length(ind_freq));
                    end
                end
    
              
                % --- Plot 10 random voxel PSDs ---
                n_rand = 10;  % number of random PSDs to plot
                n_voxels = size(psd_voxels, 1);
                
                % Random selection of voxel indices
                %rng('shuffle');  % ensures different random picks each run
                rand_idx = randperm(n_voxels, min(n_rand, n_voxels));
                
                % Plot
                fig = figure('Visible','off');
                hold on;
                for i = 1:length(rand_idx)
                    plot(freqs, 10*log10(psd_voxels(rand_idx(i),ind_freq)), 'LineWidth', 1.2);
                end
                xlabel('Frequency (Hz)');
                ylabel('Power (dB)');
                title('10 Random Voxel PSDs');
                grid on;
                hold off;
                image_name =sprintf('%s_PSD_%sp%d', patient_ID, segments{i_file}, s);
                image_name_full = fullfile(dir_psd,image_name);
                saveas(gcf,image_name_full,'png');
                close(figure(1));
    
                %% Save average PSD per ROI
                disp("Saving average PSD per ROI")
    
                % Build a structure to save
                PSD_data = struct();
                PSD_data.patient_ID = patient_ID;
                PSD_data.psd_resolution = psd_resolution;
                PSD_data.CPC = CPC;
                PSD_data.freqs = freqs;
                PSD_data.ROI_psd = ROI_psd;
                
                % Save as .mat
                mat_filename = fullfile(dir_psd, sprintf('%s_Seg%s_Part%d_ROI_PSD', patient_ID, segments{i_file}, s));
                save(mat_filename, '-struct', 'PSD_data');
                disp(['Saved ROI PSD data to: ', mat_filename]);
                
                %% Compute average bandpower per ROI
                disp("Computing average features per ROI...")
    
                % Compute bandpowers for each voxel in decibel 
                bp_delta = 10*log10(bandpower(voxel_ts', Fs, [1 4])); % delta 
                bp_theta = 10*log10(bandpower(voxel_ts', Fs, [4 8])); % theta 
                bp_alpha = 10*log10(bandpower(voxel_ts', Fs, [8 13])); % alpha 
                bp_beta = 10*log10(bandpower(voxel_ts', Fs, [13 30])); % beta
                
                % Preallocate a table
                % Initialize storage for one row of feature summary
                % Columns: [Patient | Feature_Name | Resolution | CPC | all ROIs...]
                feature_list = {'Delta', 'Theta', 'Alpha', 'Beta'};
                n_features = numel(feature_list);
                n_rois = numel(roi_list);
                
                % Create an empty cell array to later convert to a table
                data_out = cell(n_features, 4 + n_rois);
                
                % Compute bandpower for each ROI
                for f_idx = 1:n_features
                    switch feature_list{f_idx}
                        case 'Delta'
                            bp_voxel = bp_delta;
                            freq_band = [1 4];
                        case 'Theta'
                            bp_voxel = bp_theta;
                            freq_band = [4 8];
                        case 'Alpha'
                            bp_voxel = bp_alpha;
                            freq_band = [8 13];
                        case 'Beta'
                            bp_voxel = bp_beta;
                            freq_band = [13 30];
                    end
                
                    % Average by ROI
                    for r = 1:n_rois
                        mask = ROI_mask.(roi_list{r});
                        if any(mask)
                            % Mean of bandpower over all voxels in ROI
                            roi_bp(r) = mean(bp_voxel(mask));
                        else
                            roi_bp(r) = NaN;
                        end
                    end
                
                    % Fill the data_out row
                    data_out{f_idx,1} = patient_ID;           % Patient
                    data_out{f_idx,2} = segments{i_file};     % Segment
                    data_out{f_idx,3} = s;                    % Part 
                    data_out{f_idx,4} = feature_list{f_idx};  % Feature_Name
                    data_out{f_idx,5} = psd_resolution;       % Resolution
                    data_out{f_idx,6} = CPC;                  % CPC
                    
                    % ROI values start at column 7
                    for r = 1:n_rois
                        data_out{f_idx,6+r} = roi_bp(r);      % ROI values
                    end
                end
                
                % Convert to table
                column_names = [{'Patient','Segment', 'Part', 'Feature_Name','Resolution','CPC'}, roi_list'];
                T = cell2table(data_out, 'VariableNames', column_names);
                
                % Save to Excel
                excel_filename = fullfile(dir_table, sprintf('%s_Seg%s_Part%d_ROI_Features', patient_ID, segments{i_file}, s));
                writetable(T, excel_filename, "FileType", "spreadsheet");
                
                disp(['Saved ROI features to: ', excel_filename]);


              catch
                fprintf("Problems with Segment %s, part %d. Skipping...\n", segments{i_file}, s);
              end
          
            end  
    end
end


%% --- Helper functions ---

% function tbl = load_burst_ranges(files, indices, t_rosc)
%     tbl = table();
%     for i = 1:length(indices)
%         T = readtable(fullfile(files(indices(i)).folder, files(indices(i)).name));
%         T{:,:} = T{:,:}/100 + t_rosc;
%         tbl = [tbl; T];
%     end
%     tbl.Properties.VariableNames = {'burst_start_index','burst_end_index'};
% end

% function save_hourly_ROI(patient_ID, feature_name, segment_hour, bursts_included, ROI_struct, dir_csv)
%     roi_names = fieldnames(ROI_struct);
%     roi_data = nan(1,numel(roi_names));
%     for k = 1:numel(roi_names)
%         vals = ROI_struct.(roi_names{k});
%         if ~isempty(vals), roi_data(1,k) = vals(end); end
%     end
%     row_table = table({feature_name}, segment_hour, bursts_included, ...
%                       'VariableNames', {'FeatureName','Hour','Bursts_included'});
%     roi_table = array2table(roi_data, 'VariableNames', roi_names);
%     row_table = [row_table roi_table];
%     filename_base = fullfile(dir_csv, [char(patient_ID) '_Signal_ROIs.xlsx']);
%     if isfile(filename_base)
%         writetable(row_table, filename_base, 'WriteMode','append','WriteVariableNames',false);
%     else
%         writetable(row_table, filename_base);
%     end
% end

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
