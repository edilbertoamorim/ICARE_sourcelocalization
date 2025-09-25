function [segSignal_clean, tVec_new, Fs_new, n_bad_interp] = preprocess_eeg_segment(segSignal, chanNames, Fs, varargin)
%PREPROCESS_EEG_SEGMENT Preprocess an EEG segment: filter, line noise removal, ICA, dipfit-based IC rejection, interpolate bad channels, downsample, rereference
%
%   INPUTS:
%       segSignal  - [n_channels x n_samples] EEG segment
%       chanNames  - Cell array of channel labels
%       Fs         - Sampling frequency of the input data
%
%   OPTIONAL PARAMETERS (varargin as name-value pairs):
%       'Bandpass'   - [low high] in Hz (default [0.5 45])
%       'Downsample' - Target Fs for downsampling (default 250 Hz)
%       'BadThresh'  - Z-score threshold for bad channel detection (default 5)
%       'PlotFlag'   - true/false to plot intermediate steps (default false)
%       'LineFreq'   - Line noise frequency (default 60 Hz)

    %% --- Parse optional inputs ---
    p = inputParser;
    addParameter(p, 'Bandpass', [0.5 45], @(x) isnumeric(x) && numel(x)==2);
    addParameter(p, 'Downsample', 250, @isscalar);
    addParameter(p, 'BadThresh', 5, @isscalar);
    addParameter(p, 'useDipoleFit', true, @islogical);
    addParameter(p, 'LineFreq', 60, @isscalar);
    parse(p, varargin{:});
    bp_range   = p.Results.Bandpass;
    Fs_new     = p.Results.Downsample;
    bad_thresh = p.Results.BadThresh;
    useDipoleFit  = p.Results.useDipoleFit;
    lineFreq   = p.Results.LineFreq;

    %% --- 0) Fix channel naming ---
    chanNames = cellfun(@char, chanNames, 'UniformOutput', false);
    for i = 1:numel(chanNames)
        chanNames{i} = strrep(chanNames{i}, 'T3', 'T7');
        chanNames{i} = strrep(chanNames{i}, 'T4', 'T8');
        chanNames{i} = strrep(chanNames{i}, 'T5', 'P7');
        chanNames{i} = strrep(chanNames{i}, 'T6', 'P8');
    end

    %% --- 1) Create EEGLAB EEG structure ---
    EEG = eeg_emptyset();
    EEG.data    = segSignal;
    EEG.srate   = Fs;
    EEG.nbchan  = size(segSignal,1);
    EEG.pnts    = size(segSignal,2);
    EEG.chanlocs = struct('labels', chanNames(:));
    EEG.xmin    = 0;
    EEG.xmax    = (size(segSignal,2)-1)/Fs;

    %% --- 2) Load standard 10-20 montage and avgMRI/BESA ---
    eeglab_path = fileparts(which('eeglab'));
    loc_file = fullfile(eeglab_path, 'plugins', 'dipfit', 'standard_BESA', 'standard-10-5-cap385.elp');
    if ~exist(loc_file, 'file'), error('Standard 10-20 location file not found: %s', loc_file); end
    EEG = pop_chanedit(EEG, 'lookup', loc_file);

    avgMRI_file = fullfile(eeglab_path, 'plugins', 'dipfit', 'standard_BESA', 'avg152t1.mat');
    if ~exist(avgMRI_file, 'file'), warning('Standard T1 MRI data location file not found: %s', avgMRI_file); end

    besaModel_file = fullfile(eeglab_path, 'plugins', 'dipfit', 'standard_BESA', 'standard_BESA.mat');
    if ~exist(besaModel_file, 'file'), warning('Standard BESA head model file not found: %s', besaModel_file); end

    %% --- 3) Band-pass filter ---
    % High-pass filter (1st order)
    EEG = pop_eegfiltnew(EEG, bp_range(1), [], [], false, [], 0);
    
    % Low-pass filter (3rd order)
    EEG = pop_eegfiltnew(EEG, [], bp_range(2), [], false, [], 0); 

    %% --- 5) Rereference to average ---
    EEG = pop_reref(EEG, []);

    %% --- 6) Detect bad channels ---
    chan_std = std(EEG.data, 0, 2);
    z_scores = (chan_std - mean(chan_std)) / std(chan_std);
    bad_ch_idx = find(abs(z_scores) > bad_thresh);
    n_bad_interp = length(bad_ch_idx);

    %% --- 7) ICA decomposition ---
    EEG = pop_runica(EEG, 'extended',1,'interrupt','off');

    %% --- 8) Dipole fitting and automatic IC rejection ---
    % Example input: useDipoleFit = true or false
    if exist('iclabel','file') && exist(avgMRI_file,'file') && exist(besaModel_file,'file')
    
        EEG = iclabel(EEG, 'default');
    
        if useDipoleFit
            % ---- Run dipole fitting ----
            EEG = pop_dipfit_settings(EEG, 'hdmfile', besaModel_file, 'coordformat','Spherical', ...
                'mrifile', avgMRI_file, 'chanfile', loc_file, 'chansel', 1:EEG.nbchan);
    
            EEG = pop_multifit(EEG, 1:EEG.nbchan, 'threshold', 40);
    
            % Good residual variance (< 15%)
            rvList    = [EEG.dipfit.model.rv];
            goodRvIdx = find(rvList < 0.15);
        else
            % ---- Skip dipole fitting, allow all ICs for RV filter ----
            fprintf('Skipping dipole fitting, using only ICLabel for rejection.\n');
            rvList = ones(1, size(EEG.icawinv,2));  % set all RV to 1
            goodRvIdx = 1:size(EEG.icawinv,2);      % treat all as valid for RV step
        end
    
        % ---- IC rejection logic ----
        % Brain ICs based on ICLabel
        brainIdx  = find(EEG.etc.ic_classification.ICLabel.classifications(:,1) >= 0.7);
    
        % ICs that are both brain and (optionally) low RV
        goodIcIdx = intersect(brainIdx, goodRvIdx);
    
        % Remove all other ICs
        nICs = size(EEG.icawinv, 2); 
        badIcIdx = setdiff(1:nICs, goodIcIdx);
        EEG = pop_subcomp(EEG, badIcIdx, 0);
    
    else
        warning('AvgMRI or BESA head model missing, or ICLabel not found. Skipping dipole-based IC rejection.');
    end

    %% --- 9) Interpolate bad channels ---
    if n_bad_interp > 0
        EEG = pop_interp(EEG, bad_ch_idx, 'spherical');
    end

     %% --- 4) Line noise removal ---
    % Notch filter around utilityFreq ±1 Hz
    EEG = pop_eegfiltnew(EEG, [lineFreq-1, lineFreq+1]);
    fprintf('Notch filtered at %.1f Hz using pop_eegfiltnew.\n', lineFreq);

    %% --- 10) Downsample ---
    if Fs_new < Fs
        EEG = pop_resample(EEG, Fs_new);
    end

    %% --- 11) Extract cleaned data ---
    segSignal_clean = EEG.data;
    tVec_new = (0:(size(segSignal_clean,2)-1))/EEG.srate;
end

