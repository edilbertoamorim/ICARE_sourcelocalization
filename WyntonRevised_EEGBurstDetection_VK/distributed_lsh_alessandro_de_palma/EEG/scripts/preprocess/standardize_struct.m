function [ output ] = standardize_struct( input )
%standardize_struct_to_EEGLab Unify (across hospitals) channel nomenclature, crop and convert to EEGLab with channel locations.

%   Unify channel nomenclature and ordering, then downsample to TARGET_FREQUENCYHz to facilitate merging. Input is a struct in the same format of edf_to_stuct.m.
%   epoch_length is the length of an epoch in seconds. Epochs will be later used for artifact detection.


    %% Constants.
    FREQUENCY = input.header.frequency(1); % assumes we have the same frequency for all the channels.
    N_CHANNELS = 19;  % Final number of channels.
    DATA_LENGTH = size(input.matrix, 2);
    TARGET_FREQUENCY = 200;
    
    %% Unify nomenclature and reorder channels (adapted from Ghassemi).

    %MAP FROM SLAVE TO MASTER.
    s_to_m = map_channels(input.header.label);
    %Get the total number of channels.
    num_chans = size(input.header.label, 2);

    output = input;
    output.header.ns = N_CHANNELS;
    output.header.label = {'Fp1', 'Fp2','F7', 'F8', 'T3', 'T4', 'T5', 'T6', 'O1', 'O2', 'F3', 'F4', 'C3', 'C4', 'P3', 'P4', 'Fz', 'Cz', 'Pz'};
    
    % Downsample to TARGET_FREQUENCY Hz, preliminaries.
    resampled_length = size(resample(output.matrix(1, :),TARGET_FREQUENCY,FREQUENCY),2);
    output.matrix = zeros(N_CHANNELS, resampled_length);
    
    %For each of the channels
    for k = 1:num_chans
        %If there is a corresponding value of the slave file in the master.
        if(~isnan(s_to_m(k)))
            output.matrix(s_to_m(k), :) = resample(input.matrix(k, :),TARGET_FREQUENCY,FREQUENCY);  % Downsample
            output.header.transducer{s_to_m(k)} = input.header.transducer{k};
            output.header.units{s_to_m(k)} = input.header.units{k};
            output.header.physicalMin(s_to_m(k)) = input.header.physicalMin(k);
            output.header.physicalMax(s_to_m(k)) = input.header.physicalMax(k);
            output.header.digitalMin(s_to_m(k)) = input.header.digitalMin(k);
            output.header.digitalMax(s_to_m(k)) = input.header.digitalMax(k);
            output.header.prefilter{s_to_m(k)} = input.header.prefilter{k};
        end
    end
    
    output.header.frequency = TARGET_FREQUENCY*ones(1, N_CHANNELS);

end

