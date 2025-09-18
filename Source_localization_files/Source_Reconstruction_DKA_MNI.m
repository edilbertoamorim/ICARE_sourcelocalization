function Source_Reconstruction_DKA_MNI(patient_ID, dir_input, dir_output, dir_burst_ranges, max_hr, plot_flag)
% SIGNAL_SOURCE_RECONSTRUCTION
% Performs EEG source reconstruction on raw signals (hourly segmentation).
% Runs Champagne, use Beamforming, PCA for dimensionality reduction,
% compute and save PSDs (average per ROI and time_res), extract features,   
% save values into Excel, with an indicator if bursts are present in that hour.
%
% Parameters
% ----------
% patient_ID : char
%     Patient identifier (must match preprocessed EEG filename prefix).
% dir_input : char
%     Path to directory containing preprocessed EEG .mat files.
% dir_ouput : char
%     Path to directory for output files.
% dir_burst_ranges : char
%     Path to directory containing burst range .csv files.
% max_hr : numeric
%     Maximum number of hours post-ROSC to include in analysis.
% plot_flag : logical
%     If true, saves MRI source plots for each hour.
%
% Output
% ------
% Excel file per patient in output folder with hourly ROI values.

    %ft_defaults

    % --- Configurations ---
    % c.Reconstruction
    champ_iter = 25;    %[Champagne iterations]
    n_dir = 3;          %[Reconstruction directions (x,y,z)]

    % c.Spectral Analysis
    epoch_length = 10;      %[s]
    overlap = 0.5;          %[a.u.]
    psd_resolution = 5;    %[min] (Average psds over x minutes)

    % --- Load resources ---
    % leadfield_file = fullfile('Source_localization_files', 'leadfield_output', 'leadfield_19elec.mat');
    % load(leadfield_file, 'LFmatrix', 'leadfield', 'inside_idx'); leadfdc = leadfield; insideix = inside_idx;
    leadfield_file = fullfile('Source_localization_files', 'MNI_DKA_Standard_Files.mat');
    load(leadfield_file, 'LFmatrix', 'leadfdc', 'insideix', 'atlas');
    load('Source_localization_files/mri_data.mat', 'mri');
    rosc_times = readtable('Source_localization_files/Source_loc_time_ROSC_local.xlsx');

    % --- Prepare ROI structure ---
    atlas.tissuelabel{10} = 'Third_Ventricle';
    atlas.tissuelabel{11} = 'Fourth_Ventricle';
    roi_list = strrep(atlas.tissuelabel(2:end), '-', '_');
    ROI_struct = cell2struct(cell(length(roi_list),1), roi_list);

    % --- Create output directories ---
    dir_out = fullfile(dir_output, 'Source_Reconstruction');
    dir_eegplot = fullfile(dir_out, '01_EEGsegmentPlots');
    dir_psd  = fullfile(dir_out, '02_SourcePSDs');
    dir_table  = fullfile(dir_out, '03_FaturesTables');
    dir_figs  = fullfile(dir_out, '04_FeaturePlots');
    cellfun(@(d) ~exist(d,'dir') && mkdir(d), {dir_table, dir_figs, dir_eegplot, dir_psd});

    % Locate patient EEG file
    all_preproc_files = dir(fullfile(dir_input, '*.mat'));
    file_idx = find(contains({all_preproc_files.name}, patient_ID));
    if isempty(file_idx)
        error('No EEG file found for patient %s in %s', patient_ID, dir_input);
    end

    % --- Build dummy source model ---
    src_template.avg.pow = zeros(size(leadfdc.pos,1),1);  % N voxels
    src_template.inside = insideix;
    src_template.outside = find(~leadfdc.inside);
    src_template.pos = leadfdc.pos;
    src_template.method = 'average';

    cfg = [];
    cfg.parameter = 'tissue';
    cfg.interpmethod = 'nearest';
    atlas_on_source = ft_sourceinterpolate(cfg, atlas, src_template);

    ROI_mask = struct();
    for i = 2:length(roi_list)+1  % skip 'Other'
        full_mask = atlas_on_source.tissue == i; 
        ROI_mask.(roi_list{i-1}) = full_mask(insideix);  % select only the LF voxels
    end

    % --- Build dummy HD source model ---
    src_template = [];
    src_template.dim      = leadfdc.dim;
    src_template.pos      = leadfdc.pos;
    src_template.inside   = insideix;
    src_template.outside  = find(leadfdc.inside==0);
    src_template.method   = 'average';
    powvec = nan(size(leadfdc.pos,1),1);
    powvec(insideix)=0;
    src_template.avg.pow = powvec;

    cfg = [];
    cfg.downsample = 1;
    cfg.interpmethod = 'nearest';
    cfg.parameter    = 'pow';
    cfg.verbose  = 'no';   % disables most info prints
    atlas_on_source = ft_sourceinterpolate(cfg, src_template, mri);

    % Interpolate atlas labels onto source grid
    cfg = [];
    cfg.interpmethod = 'nearest';
    cfg.parameter    = 'tissue';
    cfg.verbose  = 'no';   % disables most info prints
    source_model = ft_sourceinterpolate(cfg, atlas, atlas_on_source);
    % 
    % 
    % % Plot voxel inside LF per ROI
    % for r = 1:length(roi_list)
    %     roi_name = roi_list{r};
    % 
    %     atlas_tmp = atlas_on_source;
    %     atlas_tmp.pow(source_model.tissue == (r+1)) = 1;  % assign 1 for voxels in this ROI from source model
    %     clim = [0 1];
    % 
    %     % plot
    %     cfg = [];
    %     cfg.method        = 'slice';
    %     cfg.funparameter  = 'pow';
    %     cfg.funcolormap   = 'plasma';
    %     cfg.funcolorlim   = clim;
    %     cfg.opacitylim    = [clim(1)*0.1, clim(2)];
    %     cfg.opacitymap    = 'rampup';
    %     cfg.maskparameter = 'pow'; % mask background
    %     cfg.locationcoordinates = 'voxel';
    %     cfg.crosshair     = 'yes';
    %     cfg.verbose  = 'no';   % disables most info prints
    %     figure; ft_sourceplot(cfg, atlas_tmp);
    %     title(roi_name);
    % end
        

    for i_file = file_idx
        preproc_file = all_preproc_files(i_file).name;
        rosc_idx = find(strcmp(rosc_times.preproc_file, preproc_file));

        % Build continuous time vector aligned to ROSC
        preproc_data = load(fullfile(dir_input, preproc_file));
        Fs = preproc_data.x.srate;

        t_rosc = rosc_times.time_from_rosc(rosc_idx);
        time_vec = t_rosc + (1:length(preproc_data.x.data))/Fs;
        preproc_data.x.time = time_vec;

        % Prpare fieltrip time series plot data
        [data_fieldtrip] = fun_mat_2_edf(dir_input,preproc_file);
        % Replace the names of the EEG files 
        data_fieldtrip.label{1, 8} ='T7'; % T3
        data_fieldtrip.label{1, 12}='T8'; % T4
        data_fieldtrip.label{1, 13}='P7'; % T5
        data_fieldtrip.label{1, 17}='P8'; % T6
    
        % Load burst ranges
        bursts_files = dir(fullfile(dir_burst_ranges, '**', '*.csv'));
        [~, fileName, ~] = fileparts(preproc_file);
        patient_indx = find(contains({bursts_files.name}, fileName));
        %bursts = load_burst_ranges(bursts_files, patient_indx, t_rosc);
    
        %% --- Hourly loop ---
        start_h = floor(min(time_vec)/3600);
        end_h   = ceil(max(time_vec)/3600);
        range   = min(max_hr, end_h - start_h);
    
        for h = 0:range-1
            segment_hour = start_h + h;
            t_start = segment_hour*3600;
            t_end   = t_start + 3600;
    
            % Indices for this 1-hour segment
            time_index = find(time_vec >= t_start & time_vec < t_end);
            if isempty(time_index), continue; end
    
            % Extract 1 h EEG segment
            %segment = preproc_data.x.data(:, time_index);
    
            fprintf('Running Champagne for Hour %d, patient %s \n', ...
                    segment_hour, patient_ID);

            % Divide into 10-minute chunks
            chunk_duration = psd_resolution * 60;    % 10 min = 600 seconds
            n_chunks = 3600 / chunk_duration;        % 6 chunks per hour
        
            for c = 0:n_chunks-1
                t_chunk_start = t_start + c * chunk_duration;
                t_chunk_end   = t_chunk_start + chunk_duration;
        
                % Indices for this 10-minute segment
                time_index_chunk = find(time_vec >= t_chunk_start & time_vec < t_chunk_end);
                if isempty(time_index_chunk), continue; end
        
                % Extract 10 min EEG segment
                segment_chunk = preproc_data.x.data(:, time_index_chunk);
        
                % Check bursts in this 10-min segment
                %bursts_included = any(bursts.burst_start_index >= t_chunk_start & bursts.burst_start_index < t_chunk_end);

                %% Save plot of EEG Segment
                data_fieldtrip.trial{1,1} = segment_chunk;
                time_segment = preproc_data.x.time(:,time_index_chunk);
                data_fieldtrip.time{1,1} = time_segment;
    
                %Save the EEG plot
                cfg            = [];
                cfg.viewmode   = 'vertical';
                cfg.blocksize  = time_segment(end)-time_segment(1);
                ft_databrowser(cfg, data_fieldtrip);
                image_name =strcat(patient_ID,'_Hour_',num2str(segment_hour),'_c', num2str(c));
                image_name_full = fullfile(dir_eegplot,image_name);
                ui_controls = findall(gcf, 'Type', 'uicontrol');
                delete(ui_controls);
                saveas(gcf,image_name_full,'png');
                close(figure(1));
        
                %% === Run Champagne ===
                Y = segment_chunk; % channels x samples
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
                % gammainit=ones(n_dir,n_dir,n_voxels)*0.1;
                % [Gamma,s,w,cost,k,dGamma]=champagne_plain(Y,LFmatrix,sigu_init,champ_iter,gammainit,n_dir);
                
                [Gamma_y,~,~,~,~,Sigma_y] = champ_noise_up(Y, LFmatrix, sigu_init, champ_iter, n_dir, 0, plot_flag, 0, 2, 1, 1e-16);
                if plot_flag, close(figure(1)); end

                %% Beamformer Source Reconstruction
                n_voxels = size(LFmatrix,2)/n_dir;  % n_dir = number of orientations (usually 3)
                n_sensors = size(LFmatrix,1);       % e.g., 19
                n_samples = size(Y,2);              % number of time samples
                
                % Preallocate final voxel time series (PCA-reduced)
                voxel_ts = zeros(n_voxels, n_samples);
                
                % Precompute inverse of noise covariance
                invSigmaY = pinv(Sigma_y);
                
                %% Loop through voxels
                disp("\tDimensionality Reductuction (PCA)")
                for v = 1:n_voxels
                    % - Extract the lead-field matrix for this voxel (grouped by orientation)
                    idx = [v, v + n_voxels, v + 2*n_voxels];   % indices for 3 orientations
                    Lv = LFmatrix(:, idx);                     % [n_sensors x n_dir]
                    
                    % - Compute beamformer weights for this voxel
                    denom = Lv' * invSigmaY * Lv;              % [n_dir x n_dir]
                    W_v = invSigmaY * Lv / denom;              % [n_sensors x n_dir]
                    
                    % - Reconstruct source time series for the 3 orientations
                    S_v = W_v' * Y;                            % [n_dir x n_samples]
                    
                    % - PCA to reduce 3 orientations → 1 component
                    % Center data across time
                    S_v = S_v - mean(S_v,2);
                    
                    % PCA using SVD
                    [U,~,~] = svd(S_v, 'econ');               % U: [n_dir x n_dir]
                    voxel_ts(v,:) = U(:,1)' * S_v;             % First PC: [1 x n_samples]
                end

                %% Spectral Analysis
                disp("\tSpectral Analysis")
                % Preallocate PSD storage
                % Using pwelch: output will be [n_freqs x n_voxels]
                % Compute PSD for the first voxel to get freq vector
                n_samples_epoch = epoch_length * Fs;
                n_overlap = floor(n_samples_epoch * overlap);
                [pxx,freqs] = pwelch(voxel_ts(1,:), n_samples_epoch, overlap, n_samples_epoch, Fs);
                n_freqs = length(freqs);
                psd_voxels = zeros(n_voxels, n_freqs);
                psd_voxels(1,:) = pxx';
                
                % Compute PSD for all voxels
                for v = 2:n_voxels
                    [pxx,~] = pwelch(voxel_ts(v,:), n_samples_epoch, overlap, n_samples_epoch, Fs);
                    psd_voxels(v,:) = pxx';
                end
                
                % Average PSD per ROI
                % atlas.tissue: voxel-to-ROI mapping
                % roi_list: list of ROI names (excluding 'Other')
                % psd_voxels: [n_voxels x n_freqs] for the current patient
                ROI_psd = struct();
                
                for i = 1:length(roi_list)
                    mask = ROI_mask.(roi_list{i});
                    if any(mask)
                        ROI_psd.(roi_list{i}) = mean(psd_voxels(mask,:),1);
                    else
                        ROI_psd.(roi_list{i}) = nan(1,size(psd_voxels,2));
                    end
                end

              
                % --- Plot 10 random voxel PSDs ---
                n_rand = 8;  % number of random PSDs to plot
                n_voxels = size(psd_voxels, 1);
                
                % Random selection of voxel indices
                %rng('shuffle');  % ensures different random picks each run
                rand_idx = randperm(n_voxels, min(n_rand, n_voxels));
                
                % Plot
                figure;
                hold on;
                for i = 1:length(rand_idx)
                    plot(freqs, 10*log10(psd_voxels(rand_idx(i),:)), 'LineWidth', 1.2);
                end
                xlabel('Frequency (Hz)');
                ylabel('Power (dB)');
                title('8 Random Voxel PSDs');
                grid on;
                hold off;
                image_name =strcat(patient_ID,'_Hour_',num2str(segment_hour),'_c', num2str(c), '_psd');
                image_name_full = fullfile(dir_figs,image_name);
                saveas(gcf,image_name_full,'png');
                close(figure(1));
               
                disp("\tCompute Features")
                % % % Compute bandpowers for each voxel in decibel
                %bp_delta = 10*log10(bandpower(voxel_ts', Fs, [1 4]));   % delta
                %bp_theta = 10*log10(bandpower(voxel_ts', Fs, [4 8]));   % theta
                bp_alpha = 10*log10(bandpower(voxel_ts', Fs, [8 13]));  % alpha
                %bp_beta  = 10*log10(bandpower(voxel_ts', Fs, [13 30])); % beta

            
                feat=bp_alpha;
                clim = [min(feat) max(feat)];
                atlas_tmp = atlas_on_source;
        
                % Plot voxel inside LF per ROI
                for r = 1:length(roi_list)
                    mask = ROI_mask.(roi_list{r});
                    atlas_tmp.pow(source_model.tissue == (r+1)) = mean(feat(mask));  % assign in this ROI from source model
                end
                % plot
                cfg = [];
                cfg.method        = 'slice';
                cfg.funparameter  = 'pow';
                cfg.funcolormap   = 'hot';
                cfg.funcolorlim   = clim;
                cfg.maskparameter = 'pow'; % mask background
                cfg.locationcoordinates = 'voxel';
                cfg.crosshair     = 'yes';
                cfg.verbose  = 'no';   % disables most info prints
                figure; ft_sourceplot(cfg, atlas_tmp);
                title('Mean Alpha Power');
                h = colorbar;
                h.Label.String = 'Source Power [10log_{10}(\muV^2)]';   % Using TeX for μ
                h.Label.Interpreter = 'tex'; 
                image_name =strcat(patient_ID,'_Hour_',num2str(segment_hour),'_c', num2str(c), '_pwr_alpha');
                image_name_full = fullfile(dir_figs,image_name);
                saveas(gcf,image_name_full,'png');
                close(figure(1));
                
                % 
                % 
                % 
                % %%%%%%% ROI averaging
                % pow = rInt.pow; pow(sm2.tissue==1)=0; % exclude 'Other'
                % for i = 2:length(roi_list)+1
                %     voxels = sm2.tissue==i;
                %     m = nanmean(pow(voxels));
                %     ROI_struct.(roi_list{i-1})(end+1,1) = m;
                % end
                % 
                % %% Save results to Excel
                % save_hourly_ROI(patient_ID, 'RawEEG', segment_hour, bursts_included, ROI_struct, dir_table);
                % 
                % %% Plot (optional)
                % if plot_flag
                %     cfg=[]; cfg.method='slice'; cfg.funparameter='pow';
                %     % cfg.funcolorlim=[prctile(rInt.pow,0,"all"), prctile(rInt.pow,100,"all")];
                %     cfg.funcolormap='plasma'; % cfg.opacitymap='rampup';
                %     cfg.locationcoordinates='voxel'; cfg.ori='x'; cfg.crosshair='yes';
                %     cfg.maskparameter = 'pow'; % mask background
                %     figure; ft_sourceplot(cfg, rInt);
                %     image_name = sprintf('%s_Hour_%d_signal_sourceplot.png', patient_ID, segment_hour);
                %     saveas(gcf, fullfile(dir_figs, image_name));
                %     close(gcf);
                % end
            end
        end
    end
end

%% --- Helper functions ---

function tbl = load_burst_ranges(files, indices, t_rosc)
    tbl = table();
    for i = 1:length(indices)
        T = readtable(fullfile(files(indices(i)).folder, files(indices(i)).name));
        T{:,:} = T{:,:}/100 + t_rosc;
        tbl = [tbl; T];
    end
    tbl.Properties.VariableNames = {'burst_start_index','burst_end_index'};
end

function save_hourly_ROI(patient_ID, feature_name, segment_hour, bursts_included, ROI_struct, dir_csv)
    roi_names = fieldnames(ROI_struct);
    roi_data = nan(1,numel(roi_names));
    for k = 1:numel(roi_names)
        vals = ROI_struct.(roi_names{k});
        if ~isempty(vals), roi_data(1,k) = vals(end); end
    end
    row_table = table({feature_name}, segment_hour, bursts_included, ...
                      'VariableNames', {'FeatureName','Hour','Bursts_included'});
    roi_table = array2table(roi_data, 'VariableNames', roi_names);
    row_table = [row_table roi_table];
    filename_base = fullfile(dir_csv, [char(patient_ID) '_Signal_ROIs.xlsx']);
    if isfile(filename_base)
        writetable(row_table, filename_base, 'WriteMode','append','WriteVariableNames',false);
    else
        writetable(row_table, filename_base);
    end
end
