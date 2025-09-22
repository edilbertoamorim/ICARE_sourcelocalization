function [signal, fs, chanNames, utilityFreq, startTime, endTime] = load_ICARE_EEG(subject, segment)
%LOAD_ICARE_EEG Load I-CARE EEG data directly from PhysioNet.
%
% Usage:
%   [signal, fs, chanNames] = load_ICARE_EEG('0284', '001_004');
%
% Input:
%   subject - Subject ID as string, e.g., '0284'
%   segment - Segment ID as string, e.g., '001_004'
%
% Output:
%   signal    - [samples x channels] EEG data
%   fs        - Sampling frequency (Hz)
%   chanNames - Cell array with channel names

    % Build record name for WFDB (no extension)
    recName = sprintf('i-care/2.1/training/%s/%s_%s_EEG', subject, subject, segment);

    try
        % --- Try using WFDB toolbox first ---
        [signal, fs, ~, sigInfo] = rdsamp(recName);
        chanNames = {sigInfo.sig_name};
        fprintf('Loaded via rdsamp: %s\n', recName);

    catch ME
        warning('rdsamp failed (%s). Switching to manual download...', ME.message);

        % --- Manual fallback: directly fetch MAT and HEA files ---
        baseURL = 'https://physionet.org/files/i-care/2.1/training';
        matURL = sprintf('%s/%s/%s_%s_EEG.mat', baseURL, subject, subject, segment);
        heaURL = sprintf('%s/%s/%s_%s_EEG.hea', baseURL, subject, subject, segment);

        % Temporary local filename
        tempMat = [tempname '_EEG.mat'];

        % Download MAT file
        fprintf('Downloading: %s\n', matURL);
        websave(tempMat, matURL);

        % Load MAT file (I-CARE stores EEG in variable "val")
        S = load(tempMat);
        if isfield(S, 'val')
            signal = S.val';  % Transpose to [samples x channels]
        else
            error('MAT file does not contain "val". Check structure.');
        end

        % Read and parse header text
        heaText = webread(heaURL);
        [fs, chanNames, utilityFreq, startTime, endTime] = parseICAREHeader(heaText);

        % Clean up temp file
        delete(tempMat);
    end
end

function [fs, chanNames, utilityFreq, startTime, endTime] = parseICAREHeader(heaText)
%PARSEICAREHEADER Extract fs, channel names, utility frequency, start/end times from a WFDB header

    lines = strsplit(heaText, '\n'); 
    firstLine = strtrim(lines{1});

    % Tokens from first line
    tokens = strsplit(firstLine);
    fs = str2double(tokens{3});           % 3rd token = sampling frequency
    nChannels = str2double(tokens{2});    % 2nd token = number of channels

    % Extract channel names (from the next nChannels lines)
    chanNames = {};
    for i = 2:(nChannels+1)
        line = strtrim(lines{i});
        if isempty(line), continue; end
        parts = strsplit(line);
        chanNames{end+1} = parts{end};    % last token = channel label
    end

    % Extract utility frequency, start time, end time
    utilityFreq = [];
    startTime = '';
    endTime = '';
    for i = 1:numel(lines)
        line = strtrim(lines{i});
        if startsWith(line, '#Utility frequency:')
            utilityFreq = str2double(strtrim(extractAfter(line, ':')));
        elseif startsWith(line, '#Start time:')
            startTime = strtrim(extractAfter(line, ':'));
        elseif startsWith(line, '#End time:')
            endTime = strtrim(extractAfter(line, ':'));
        end
    end
end
