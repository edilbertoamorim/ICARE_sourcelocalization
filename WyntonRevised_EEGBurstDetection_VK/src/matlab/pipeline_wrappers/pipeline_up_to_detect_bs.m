function [eeg, bs_ranges, global_zs, bsr, burst_ranges_cell, local_zs] = pipeline_up_to_detect_bs(file_path)
% PIPELINE_UP_TO_DETECT_BS - Runs entire pipeline up to and including
%   detect bs
% 
% Input:
%     file_path - path to edf to run pipeline on
%     
% Output
%     eeg - eeglab eeg object as outputted by prep_and_artifact
%     bs_ranges, global_zs, bsr, burst_ranges_cell, local_zs - output of detect_bs.m

    [~, filename_no_ext, ~] = fileparts(file_path);
    patient_id = get_pt_from_fname(file_path);
    
    disp(['Loading eeglab_eeg for file '  filename_no_ext]);
    % load eeg
    [eeg, is_artifact] = prep_and_artifact(file_path, 1, 0);
    data = eeg.data;
    
    disp('Running bs detection...');
    tic;
    % run bs_detection and get desired outputs
    local_zs = label_local_zs(data, eeg.srate);
    [bs_ranges, global_zs, bsr, burst_ranges_cell] = detect_bs(eeg, is_artifact);
    toc;
end

