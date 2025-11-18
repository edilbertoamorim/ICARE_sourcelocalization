function featTable = extract_eeg_features(signal, infoStruct, chanNames, ROI_mask)
% extract_eeg_features - Compute features per channel/ROI for a given EEG segment
%
% Inputs:
%   signal      - [nChannels x nSamples] EEG/ROI data (already preprocessed)
%   infoStruct  - struct containing info on the signal, patient and processing
%   chanNames   - cell array of channel or ROI names 
%   ROI_mask    - optional, struct containing bool arrays like ROI_mask.left_h = [1, 0, 1, 1, 0]...
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
    partID     = infoStruct.partID;
    CPC        = infoStruct.CPC;
    resolution = infoStruct.resolution;
    t_start    = infoStruct.t_start;
    
    featData = {}; % Initialize featData to store feature information
    % =====================================================================
    % Define features here
    % =====================================================================

    %% --- Band powers (absolute + relative)
    [bpVals, bpNames, bpUnits, colNames] = compute_bandpowers(signal, Fs, ROI_mask, chanNames, epochLen, overlap);

    % Store each band as row in featData
    for f = 1:numel(bpNames)
        featData = [featData; {patientID, segmentID, partID, CPC, t_start, resolution, Fs, bpNames{f}, bpUnits{f}, bpVals(f,:)}];
    end

    %% - Other features..

    %% =====================================================================
    % Convert featData into table
    % =====================================================================
    nFeatures = size(featData,1);
    featMat = cell2mat(cellfun(@(x) reshape(x,1,[]), featData(:,10), 'UniformOutput', false));
    
    featTable = table( ...
        repmat({patientID}, nFeatures,1), ...
        repmat(segmentID, nFeatures,1), ...
        repmat(partID, nFeatures,1), ...
        repmat({CPC}, nFeatures,1), ...
        repmat({t_start}, nFeatures,1), ...
        repmat(resolution, nFeatures,1), ...
        repmat(Fs, nFeatures,1), ...
        featData(:,8), ...
        featData(:,9), ...
        'VariableNames', {'Patient','Segment','Part','CPC','Start_Time','Sec_Resolution','Fs','Feature_Name','Unit'});
    
    featTable = [featTable array2table(featMat, 'VariableNames', matlab.lang.makeValidName(colNames))];
end


%% =====================================================================
% Subfunction: compute band powers
% =====================================================================
function [vals, featNames, units, colNames] = compute_bandpowers(signal, Fs, ROI_mask, chanNames, epochLen, overlap)
    % signal = [nChan x nSamples]
    % Fs     = sampling rate
    % epochLen = length of each Welch window in seconds
    % overlap  = fraction overlap (0–1)

    % Define frequency bands
    bands = { 'Delta', [1.5 6];
              'Theta', [6 8.5];
              'Alpha', [8.5 12.5];
              'Beta',  [12.5 30];
              'Gamma', [30 40] 
              };
    totalBand = [1.5 18];
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
        [Pxx,f] = pwelch(x, winSize, noverlap, [], Fs); % Pxx: power/Hz

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
        colNames = roiNames;
    else
        colNames = chanNames;
    end

    % Convert absolute powers to dB
    absP = 10*log10(absP);

    % --- Build outputs: first all absolute bands, then all relative bands ---
    vals = [absP; relP];            % [2*nBands x nCols] : first nBands = abs, next nBands = rel
    featNames = cell(2*nBands,1);
    units     = cell(2*nBands,1);

    % first list all absolute-power feature names
    for b = 1:nBands
        featNames{b} = [bands{b,1} '_AbsPower'];
        units{b} = 'dB';
    end
    % then list all relative-power feature names (matching the order in vals)
    for b = 1:nBands
        featNames{nBands + b} = [bands{b,1} '_RelPower'];
        units{nBands + b} = '%';
    end
end


% function [vals, featNames, units, colNames] = compute_bandpowers(signal, Fs, ROI_mask, chanNames, epochLen, overlap)
%     % signal = [nChan x nSamples]
%     % Fs     = sampling rate
%     % epochLen = length of each epoch in seconds
%     % overlap  = fraction overlap (0–1)
% 
%     % Define frequency bands
%     bands = { 'Delta', [1.5 6];
%               'Theta', [6 8.5];
%               'Alpha', [8.5 12.5];
%               'Beta',  [12.5 30];
%               'Gamma', [30 40] };
%     totalBand = [1.5 40];
%     nBands = size(bands,1);
% 
%     nChan = size(signal,1);
%     absP  = zeros(nBands,nChan);
%     totP  = zeros(1,nChan);
% 
%     % Define window and overlap in samples
%     winSize  = round(epochLen * Fs);
%     noverlap = round(overlap * winSize);
% 
%     if winSize > size(signal,2)
%         error('Window Size for PSD bigger than signal');
%     end
% 
%     % Loop channels, compute absolute and relative bandpowers
%     for ch = 1:nChan
%         x = signal(ch,:);
% 
%         % total power across full band
%         totP(ch) = bandpower(x, Fs, totalBand);
% 
%         % band powers
%         for b = 1:nBands
%             absP(b,ch) = bandpower(x, Fs, bands{b,2});
%         end
%     end
% 
%     relP = absP ./ totP * 100;
% 
%     % --- ROI averaging if mask provided ---
%     if exist('ROI_mask','var') && ~isempty(ROI_mask)
%         roiNames = fieldnames(ROI_mask);
%         nR = numel(roiNames);
%         absR = zeros(nBands,nR);
%         relR = zeros(nBands,nR);
%         for r = 1:nR
%             mask = ROI_mask.(roiNames{r})(:);
%             absR(:,r) = mean(absP(:,mask),2,'omitnan');
%             relR(:,r) = mean(relP(:,mask),2,'omitnan');
%         end
%         absP = absR;
%         relP = relR;
%         colNames = roiNames;
%     else
%         colNames = chanNames;
%     end
% 
%     % Convert absolute powers to dB
%     absP = 10*log10(absP);
% 
%     % --- Build outputs ---
%     vals = [absP; relP];
%     featNames = cell(nBands*2,1);
%     units     = cell(nBands*2,1);
%     row = 1;
%     for b = 1:nBands
%         featNames{row} = [bands{b,1} '_AbsPower']; units{row} = 'dB'; row=row+1;
%         featNames{row} = [bands{b,1} '_RelPower']; units{row} = '%';  row=row+1;
%     end
% end

