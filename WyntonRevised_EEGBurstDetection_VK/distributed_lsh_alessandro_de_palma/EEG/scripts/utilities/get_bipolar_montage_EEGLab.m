function [ output ] = get_bipolar_montage_EEGLab( input )
%GET_BIPOLAR_MONTAGE_EEGLAB Return bipolar montage of complete 19 channel
%EEGLab file.

    %input.data(:, :) = -input.data(:, :);  % Invert channels (they might
    %be inverted).
    
    output = input;
    output.data = input.data(1:18, :);
    output.chanlocs = input.chanlocs(1:18);

    % Create bipolar montage (adapted from mgh's
    % Reactivity_1_preprocessingICA.m.
    BPtargets=[1 3; 3 5; 5 7; 7 9; 2 4; 4 6; 6 8; 8 10; 1 11; 11 13; 13 15; 15 9; 2 12; 12 14; 14 16; 16 10; 17 18; 18 19;];
    for ch=1:length(BPtargets)
        output.data(ch,:) = input.data(BPtargets(ch,1),:) - input.data(BPtargets(ch,2),:);
        output.chanlocs(ch).labels = [input.chanlocs(BPtargets(ch,1)).labels,'-',input.chanlocs(BPtargets(ch,2)).labels];
    end

end

