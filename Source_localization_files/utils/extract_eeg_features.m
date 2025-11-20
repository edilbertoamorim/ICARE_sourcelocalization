function featTable = extract_eeg_features(signal, infoStruct, chanNames, ROI_mask, config)
% extract_eeg_features - Compute features per channel/ROI for a given EEG segment
%
% Inputs:
%   signal      - [nChannels x nSamples] EEG/ROI data (already preprocessed)
%   infoStruct  - struct containing info on the signal, patient and processing
%   chanNames   - cell array of channel or ROI names 
%   ROI_mask    - optional, struct containing bool arrays like ROI_mask.left_h = [1, 0, 1, 1, 0]...
%   config      - configurations struct
%
% Output:
%   featTable   - MATLAB table containing features per channel/ROI
%
% The table columns are:
%   ['Patient','Segment','Part','CPC','Resolution','Start_Time','Fs','Feature_Name','Unit', <chanNames>]

    % Unpack info
    Fs         = infoStruct.Fs;
    epochLen   = infoStruct.epoch_length;
    overlap    = infoStruct.overlap;

    patientID  = infoStruct.patientID;
    segmentID  = infoStruct.segmentID;
    t_fromROSC = infoStruct.time_from_ROSC;
    partID     = infoStruct.partID;
    CPC        = infoStruct.CPC;
    resolution = infoStruct.resolution;
    t_start    = infoStruct.t_start;

    bands = config.bands;
    total_range = config.total_range;

    feat_bool = config.additional_features; % SIQ, BCI, Amplitude

    
    featData = {}; % Initialize featData to store feature information
    % =====================================================================
    % Define features here
    % =====================================================================

    %% --- Band powers (absolute + relative)
    % Define frequency bands
    

    [bpVals, bpNames, bpUnits] = compute_bandpowers(signal, Fs, ROI_mask, epochLen, overlap, bands, total_range);

    % Store each band as row in featData
    for f = 1:numel(bpNames)
        featData = [featData; {patientID, segmentID, partID, t_fromROSC, CPC, t_start, resolution, Fs, ...
            bpNames{f}, bpUnits{f}, bpVals(f,:)}];
    end

    %% - Other features..
    
    [ftVals, ftNames, ftUnits] = compute_other(signal, Fs, ROI_mask, feat_bool);

    for f = 1:numel(ftNames)
        featData = [featData; {patientID, segmentID, partID, t_fromROSC, CPC, t_start, resolution, Fs, ...
            ftNames{f}, ftUnits{f}, ftVals(f,:)}];
    end

    %% =====================================================================
    % Convert featData into table
    % =====================================================================
    nFeatures = size(featData,1);
    var_names = {'Patient','Segment','Part','Time_from_ROSC','CPC','Start_Time','Sec_Resolution','Fs','Feature_Name','Unit'};

    featMat = cell2mat(cellfun(@(x) reshape(x,1,[]), featData(:,length(var_names)+1), 'UniformOutput', false));
    
    featTable = table( ...
        repmat({patientID}, nFeatures,1), ...
        repmat(segmentID, nFeatures,1), ...
        repmat(partID, nFeatures,1), ...
        repmat(t_fromROSC, nFeatures,1), ...
        repmat({CPC}, nFeatures,1), ...
        repmat({t_start}, nFeatures,1), ...
        repmat(resolution, nFeatures,1), ...
        repmat(Fs, nFeatures,1), ...
        featData(:,9), ...
        featData(:,10), ...
        'VariableNames', var_names);
    
    featTable = [featTable array2table(featMat, 'VariableNames', matlab.lang.makeValidName(chanNames))];
end


%% =====================================================================
% Subfunction: compute band powers
% =====================================================================
function [vals, featNames, units] = compute_bandpowers(signal, Fs, ROI_mask, epochLen, overlap, bands, totalBand)
    % signal = [nChan x nSamples]
    % Fs     = sampling rate
    % epochLen = length of each Welch window in seconds
    % overlap  = fraction overlap (0–1)

    nBands = size(bands,1);

    nChan = size(signal,1);
    absP  = zeros(nBands,nChan);
    totP  = zeros(1,nChan);

    % Define window and overlap in samples
    winSize  = round(epochLen * Fs);
    noverlap = round(overlap * winSize);

    if winSize > size(signal,2)
        error('Window Size for PSD bigger than signal');
    end

    % Loop channels, compute absolute and relative bandpowers
    for ch = 1:nChan
        x = signal(ch,:);

        % Compute PSD with Welch
        [Pxx,f] = pwelch(x, winSize, noverlap, winSize/2, Fs); % Pxx: power/Hz

        % total power across full band
        totP(ch) = bandpower(Pxx, f, totalBand, 'psd');

        % band powers
        for b = 1:nBands
            absP(b,ch) = bandpower(Pxx, f, bands{b,2}, 'psd');
        end
    end

    relP = absP ./ totP * 100;

    % --- ROI averaging if mask provided ---
    if exist('ROI_mask','var') && ~isempty(ROI_mask)
        roiNames = fieldnames(ROI_mask);
        nR = numel(roiNames);
        absR = zeros(nBands,nR);
        relR = zeros(nBands,nR);
        for r = 1:nR
            mask = ROI_mask.(roiNames{r})(:);
            absR(:,r) = mean(absP(:,mask),2,'omitnan');
            relR(:,r) = mean(relP(:,mask),2,'omitnan');
        end
        absP = absR;
        relP = relR;
    end

    % Convert absolute powers to dB
    absP = 10*log10(absP);

    % --- Build outputs: first all absolute bands, then all relative bands ---
    vals = [absP; relP];            % [2*nBands x nCols] : first nBands = abs, next nBands = rel
    featNames = cell(2*nBands,1);
    units     = cell(2*nBands,1);

    % first list all absolute-power feature names
    for b = 1:nBands
        featNames{b} = ['AbsPower_' bands{b,1} ];
        units{b} = 'dB';
    end
    % then list all relative-power feature names (matching the order in vals)
    for b = 1:nBands
        featNames{nBands + b} = ['AbsPower_' bands{b,1}  x];
        units{nBands + b} = '%';
    end
end

function [ftVals, ftNames, ftUnits] = compute_other(signal, Fs, ROI_mask, feat_bool)
  
% Purpose:
%   Compute selected EEG features (SIQ, BCI, etc.) for multichannel data,
%   optionally average them per ROI, and return results in a standardized format.
%
% Inputs:
%   signal      - [samples x channels] EEG data
%   Fs          - sampling rate in Hz
%   ROI_mask    - struct with ROI names as fields, each containing a logical mask
%                 vector (length = number of channels). If empty, no averaging.
%   chanNames   - cell array of channel names
%   feat_bool   - logical or numeric vector indicating which features to compute
%                 Example: [1 1] → compute SIQ and BCI
%
% Outputs:
%   ftVals      - matrix [nChannels or nROIs x nFeatures]
%   ftNames     - cell array of feature names
%   ftUnits     - cell array of feature units
%   colNames    - channel names or ROI names depending on ROI_mask
%
% Notes:
%   - Assumes helper functions qEEGSIQ_chan and qEEGBCI_chan exist.
%   - You can add more feature blocks following the same template.
%

%% ----- Safety checks -----
    
    nChan = size(signal,1);
    
    if ~isvector(feat_bool)
        error('feat_bool must be a vector.');
    end
    
    %% ----- Prepare outputs -----
    ftVals  = [];
    ftNames = {};
    ftUnits = {};
    
    %% ====== FEATURE 1: SIQ ======
    % SIQ returns multiple sub-band SIQ measures, so we group them together.
    if feat_bool(1) == 1
        bin_min  = -200;
        bin_max  = 200;
        binWidth = 2;
    
        % qEEGSIQ_chan returns an array of structs, one per channel
        siq_all = qEEGSIQ_chan(signal, bin_min, bin_max, binWidth);
    
        SIQ_delta = [siq_all.delta]';   % column vector (nChan x 1)
        SIQ_theta = [siq_all.theta]';
        SIQ_alpha = [siq_all.alpha]';
        SIQ_beta  = [siq_all.beta]';
    
        siq_mat = [SIQ_delta, SIQ_theta, SIQ_alpha, SIQ_beta];
    
        ftVals  = [ftVals, siq_mat];
        ftNames = [ftNames, {'SIQ_delta','SIQ_theta','SIQ_alpha','SIQ_beta'}];
        ftUnits = [ftUnits, {'a.u.','a.u.','a.u.','a.u.'}];
    end
    
    %% ====== FEATURE 2: BCI ======
    if length(feat_bool) >= 2 && feat_bool(2) == 1
    
        BCI = qEEGBCI_chan(signal, Fs)';   % returns [channels x 1]
    
        ftVals  = [ftVals, BCI];
        ftNames = [ftNames, {'BCI'}];
        ftUnits = [ftUnits, {'a.u.'}];
    end

    %% ====== FEATURE 3: Amplitude ======
    if length(feat_bool) >= 3 && feat_bool(3) == 1
    
        d0MaxAmp = max(abs(signal'))';
        d0MeanAmp = mean(abs(signal'))';
        d0VarAmp = var(abs(signal'))';
    
        ftVals  = [ftVals, d0MaxAmp, d0MeanAmp, d0VarAmp];
        ftNames = [ftNames, {'Max_amp'}, {'Mean_amp'}, {'Var_amp'}];
        ftUnits = [ftUnits, {'µV'}, {'µV'}, {'µV'}];
    end
    
    %% ====== Add more features here ======
    % Template:
    % if length(feat_bool) >= K && feat_bool(K) == 1
    %     feature_value = compute_feature(signal, Fs);
    %     ftVals = [ftVals, feature_value];
    %     ftNames = [ftNames, {'feature_name'}];
    %     ftUnits = [ftUnits, {'unit'}];
    % end
    
    
    %% ====== ROI Averaging ======
    if exist('ROI_mask','var') && ~isempty(ROI_mask)
    
        roiNames = fieldnames(ROI_mask);
        nR = numel(roiNames);
        nF = size(ftVals, 2);
    
        roiVals = nan(nR, nF);
    
        for r = 1:nR
            mask = ROI_mask.(roiNames{r})(:);
    
            if length(mask) ~= nChan
                error('ROI mask "%s" does not match number of channels.', roiNames{r});
            end
    
            % Average over channels belonging to this ROI
            roiVals(r, :) = mean(ftVals(mask, :), 1, 'omitnan');
        end
    
        ftVals   = roiVals;
    end

    ftVals  = ftVals';
    ftNames = ftNames';
    ftUnits = ftUnits';

end

