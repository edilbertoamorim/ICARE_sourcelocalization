function [signal_out, chanNames_out] = filter_ch_labels(signal, chanNames, label)
%FILTER_CH_LABELS Keep and reorder only desired EEG channels
%
%   [signal_out, chanNames_out] = filter_ch_labels(signal, chanNames, label)
%
%   INPUTS:
%       signal    - EEG matrix [n_samples x n_channels] or [n_channels x n_samples]
%       chanNames - Cell array of current channel names in 'signal'
%       label     - Cell array of desired channel names (target order)
%
%   OUTPUTS:
%       signal_out    - EEG matrix [n_samples x length(label)] containing only the desired channels
%       chanNames_out - Cell array of desired channel names in correct order
%
%   BEHAVIOR:
%       * If all channels in 'label' are present, they are kept and reordered.
%       * If any channel in 'label' is missing, an error is raised.

    %% --- Validate input sizes ---
    n_channels_signal = size(signal, 2);
    if n_channels_signal ~= numel(chanNames)
        % If the channel count matches the first dimension, transpose
        if size(signal,1) == numel(chanNames)
            signal = signal';  % now [n_samples x n_channels]
            n_channels_signal = size(signal, 2);
        else
            error('Mismatch: Signal dimensions do not match number of channel names.');
        end
    end

    %% --- Find and reorder desired channels ---
    [found, idx_chan] = ismember(label, chanNames);

    if ~all(found)
        % Identify missing channels
        missing = label(~found);
        error('Missing required channels: %s', strjoin(missing, ', '));
    end

    % Reorder columns of signal to match 'label'
    signal_out = signal(:, idx_chan);
    chanNames_out = label(:)';  % ensure row cell array

    %% --- Print summary ---
    fprintf('Channels filtered and reordered successfully. Final EEG has %d channels.\n', length(chanNames_out));
end

