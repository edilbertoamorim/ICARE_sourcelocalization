function [eeg_preprocessed] = preprocess(eeg)
% PREPROCESS - Applies filters for preprocessing and changes eeg to 
%     bipolar montage referencing
% 
% Input
%     eeg - eeglab eeg object
% 
% Output
%     eeg_preprocessed - eeglab eeg object, with preprocessing applied
% 
% Notes
%     Before running this we should have done standardize_struct (which
%     downsamples)


%% filter the data 
% filters: bandpass filter and notch filter
srate = eeg.srate;
% Get filter parameters
[hp_filter_order, ...
    low_freq_threshold, ...
    lp_filter_order, ...
    high_freq_threshold, ...
    notch_filter_order, ...
    notch_low_threshold, ...
    notch_high_threshold] = ...
    PrepArtifactParams.get_params('hp_filter_order', ...
        'low_freq_threshold', ...
        'lp_filter_order', ...
        'high_freq_threshold', ...
        'notch_filter_order', ...
        'notch_low_threshold', ...
        'notch_high_threshold');

[bh,ah] = butter(hp_filter_order, low_freq_threshold/(srate/2),'high'); %
[bl,al] = butter(lp_filter_order, high_freq_threshold/(srate/2),'low'); %
[bn,an] = butter(notch_filter_order, ...
    [notch_low_threshold notch_high_threshold]./(srate/2), 'stop'); % notch filter

eeg_preprocessed = eeg;
data = eeg_preprocessed.data';
% filtfilt call causes 'octave functions should not run on Matlab' warning
data = filtfilt(bh,ah, data);
data = filtfilt(bn,an, data); % notch filter
data = filtfilt(bl,al, data);

eeg_preprocessed.data = data';
eeg_preprocessed = get_bipolar_montage_EEGLab(eeg_preprocessed);
    
end

