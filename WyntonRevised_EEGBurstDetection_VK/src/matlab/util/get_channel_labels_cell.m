function channel_labels_cell = get_channel_labels_cell(eeg)
%   eeg - eeglab eeg object
%   channel_labels_cell - cell of strings of the labels of the eeg channels
    channel_labels_cell = {};
    for i=1:length(eeg.chanlocs)
        channel_labels_cell{i} = eeg.chanlocs(i).labels;
    end
end

