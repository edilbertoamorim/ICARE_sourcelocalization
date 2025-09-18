function [eeg_eeglab_processed,is_artifact] = prep_and_artifact(filepath, use_saved, save_result)
% PREP_AND_ARTIFACT - Loads edf as eeglab eeg object, runs preprocessing and artifact detection
% 
% Input
%     filepath - path to edf file containing eeg data
%     use_saved - boolean. optional. default is true. 
%         if true and saved eeglab eeg object exists, loads that
%         eeglab eeg object instead of re-creating it. 
%     save_result - boolean. optional. default is true. 
%         if true, saves any newly created eeglab eeg object to a matfile.
%             
% Output
%     eeg_eeglab_processed - eeglab eeg object containing the eeg data after
%         all preprocessing. The 'data' field of this object contains the
%         [num_channels x num_samples] matrix of eeg data
%     is_artifact - binary vector of length num_samples, where is_artifact(i)=1
%         if sample i has artifact, and 0 otherwise

    if nargin < 3
        use_saved = 1;
    end
    if nargin < 4
        save_result = 1;
    end
    [x] = load_eeglab_eeg(filepath, use_saved, save_result);
    if contains(filepath, 'ynh') || contains(filepath, 'bwh')
        % These need to be inverted.
        x.data = x.data * -1;
    end
    x.data = double(x.data);
    eeg_eeglab_processed = preprocess(x);
    is_artifact = detect_artifacts(eeg_eeglab_processed);
end

