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
%   ['Patient','CPC','Segment','Part','Resolution','Feature_Name','Unit', <chanNames>]

    % Unpack info
    Fs         = infoStruct.Fs;
    patientID  = infoStruct.patientID;
    CPC        = infoStruct.CPC;
    segmentID  = infoStruct.segmentID;
    partID     = infoStruct.partID;
    resolution = infoStruct.resolution;
    epochLen   = infoStruct.epoch_length;
    overlap    = infoStruct.overlap;

    featData = {}; % Initialize featData to store feature information
    % =====================================================================
    % Define features here
    % =====================================================================

    %% --- Band powers (absolute + relative)
    [bpVals, bpNames, bpUnits, colNames] = compute_bandpowers(signal, Fs, ROI_mask, chanNames, epochLen, overlap);

    % Store each band as row in featData
    for f = 1:numel(bpNames)
        featData = [featData; {patientID, CPC, segmentID, partID, resolution, bpNames{f}, bpUnits{f}, bpVals(f,:)}];
    end

    %% - Other features..

    %% =====================================================================
    % Convert featData into table
    % =====================================================================
    nFeatures = size(featData,1);
    featMat = cell2mat(cellfun(@(x) reshape(x,1,[]), featData(:,8), 'UniformOutput', false));
    
    featTable = table( ...
        repmat({patientID}, nFeatures,1), ...
        repmat({CPC}, nFeatures,1), ...
        repmat(segmentID, nFeatures,1), ...
        repmat(partID, nFeatures,1), ...
        repmat(resolution, nFeatures,1), ...
        featData(:,6), ...
        featData(:,7), ...
        'VariableNames', {'Patient','CPC','Segment','Part','Resolution','Feature_Name','Unit'});
    
    featTable = [featTable array2table(featMat, 'VariableNames', matlab.lang.makeValidName(colNames))];
end


%% =====================================================================
% Subfunction: compute band powers
% =====================================================================
function [vals, featNames, units, colNames] = compute_bandpowers(signal, Fs, ROI_mask, chanNames, epochLen, overlap)
    % signal = [nChan x nSamples]
    % Fs     = sampling rate

    % Define frequency bands
    bands = { 'Delta', [1.5 6];
              'Theta', [6 8.5];
              'Alpha', [8.5 12.5];
              'Beta',  [12.5 30];
              'Gamma', [30 40] };
    totalBand = [1.5 40];
    nBands = size(bands,1);

    nChan = size(signal,1);
    absP  = zeros(nBands,nChan);
    totP  = zeros(1,nChan);

    % --- Use EEGLAB spectopo ---
    % [spectra, freqs] = spectopo(signal, frames, srate, 'plot', 'off')
    % spectra: [nChan x nFreqs] in dB (10*log10(uV^2/Hz))
    nSamples = size(signal,2);
    winSize  = round(epochLen * Fs);         % number of samples
    overlap  = round(overlap  * winSize);    % overlap

    if winSize > nSamples
        error('Window Size for PSD bigger than signal'); end
    
    [spectra, freqs] = spectopo(signal, 0, Fs, ...
                                'winsize', winSize, ...
                                'overlap', overlap, ...
                                'plot', 'off');

    % Convert to linear power spectral density
    psd = 10.^(spectra/10);  % [uV^2/Hz]

    % Total bandpower
    for ch = 1:nChan
        totP(ch) = bandpower(psd(ch,:), freqs, totalBand, 'psd');
        for b = 1:nBands
            absP(b,ch) = bandpower(psd(ch,:), freqs, bands{b,2}, 'psd');
        end
    end

    relP = absP ./ totP *100;

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

    absP = 10*log10(absP); % Convert back in [dB]

    % --- Build outputs ---
    vals = [absP; relP];
    featNames = cell(nBands*2,1);
    units     = cell(nBands*2,1);
    row = 1;
    for b = 1:nBands
        featNames{row} = [bands{b,1} '_AbsPower']; units{row} = 'dB'; row=row+1;
        featNames{row} = [bands{b,1} '_RelPower']; units{row} = '%';    row=row+1;
    end
end
