function [ output ] = PREP_EEGLab( input )
%PREP_EEGLab Apply the PREP pipeline to an input in EEGLab format.
%   Perform preprocessing on a single EEGLab lab format input.
%   remove_bad_channels is true if interpolated bad channels shall be
%   removed.
%   The PREP pipeline is applied separately on 5min epochs of the file.
%
%   Output format:
%       eeglab structure with additional fields
%       interpolatedChannels (cell of lists of interpolated channel indices per EPOCH)
%       n_epochs (number of epochs)

    %% Preliminaries.
    % Save number of channels.
    N_CHANNELS = input.nbchan;
    FREQUENCY = input.srate;
    EPOCH = FREQUENCY*60*5;  % 5min epoch.
    LENGTH = size(input.data,2);

    n_epochs = ceil(LENGTH/EPOCH);
    output = input;
    output.interpolatedChannels = {};
    output.n_epochs = n_epochs;

    % Start measuring time.
    tic

    counter = 1
    for index = 1:EPOCH:(LENGTH-EPOCH+1)
        %% Create temporary structure to apply PREP on.
        temp_eeg = pop_importdata('data', input.data(:, index:index+EPOCH-1), 'dataformat', 'array', ...
                'nbchan', N_CHANNELS, 'srate', FREQUENCY, 'chanlocs', input.chanlocs);

        %% PREP pipeline.
        % Parameters.
        params = struct();
        params.lineFrequencies = [60, 120, 180, 240];
        params.referenceChannels = 1:N_CHANNELS;
        params.evaluationChannels = 1:N_CHANNELS;
        params.rereferencedChannels = 1:N_CHANNELS;
        params.detrendChannels = 1:N_CHANNELS;
        params.lineNoiseChannels = 1:N_CHANNELS;
        params.detrendType = 'high pass';  % Temporary high pass to remove the trends (line noise removal does not work, otherwise)
        params.detrendCutoff = 0.5;  % 0.5 Hz high-pass frequency (the standard is 1Hz, this is to be consistent with MGH code).
        params.referenceType = 'robust';  % Use PREP's "robust" referencing algorithm (featuring bad channels and interpolation).
        params.meanEstimateType = 'median';  % Default.
        params.interpolationOrder = 'post-reference'; % Default.

        % Post-processing parameters.
        params.keepFiltered = true;  % Keep the signal high-passed.
        params.removeInterpolatedChannels = false;  % Keep interpolated bad channels but keep track of them.

        % Run the pipeline. If something goes wrong, set the entire epoch to 0.
        try
            [temp_eeg, computationTimes] = no_catch_prepPipeline(temp_eeg, params);
        catch error
            disp(['An epoch was skipped while PREPing ' char(input.SID)])
            disp(error.message)
            temp_eeg.data = zeros(N_CHANNELS, EPOCH);
            temp_eeg.etc.noiseDetection.interpolatedChannelNumbers = 1:N_CHANNELS;
        end

        %% Update interpolated channels and copy PREPed data.
        output.data(:, index:index+EPOCH-1) = temp_eeg.data(:, :);
        output.interpolatedChannels{counter} = temp_eeg.etc.noiseDetection.interpolatedChannelNumbers;

        counter = counter + 1;
    end

    % Stop measuring time.
    toc

end
