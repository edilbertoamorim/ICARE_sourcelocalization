function [bsr] = calculate_bsr(zs, srate, is_artifact)
% CALCULATE_BSR - Calculate burst suppression ratio (returned as percentage of suppression)

% Input
%     zs - binary vector of length num_samples, where global_zs(i)=0 if 
%         sample i is part of a suppression, and global_zs(i)=1 if sample i is 
%         part of a burst
%     srate - sample rate of the eeg signal
%     is_artifact - binary vector length num_samples where is_artifact(i)=1
%         when sample i is artifact, and 0 otherwise
% 
% Ouput
%     bsr - binary vector of length num_samples, where bsr(i) is a number between 0
%         and 1 and gives the ratio of suppressions to bursts at time sample i


    bsr_window = DetectBsParams.get_params('bsr_window');
    Nt = length(zs);
    min_srate = bsr_window * srate;  % num samples per minutes
    bsr = zeros(1,Nt);
    current_sum = 0;
    current_artifact_sum = 0;
    for i=1:(min(Nt, min_srate))
        current_sum = current_sum + zs(i);
        current_artifact_sum = current_artifact_sum + is_artifact(i);
        if current_artifact_sum==0
            % no artifact
            bsr(i) = current_sum / i;
        else
            bsr(i) = nan;
        end
    end
    for i=(min(Nt, min_srate)+1):Nt
        prev_start_index = i - min_srate;  % prev_start_index >= 1.
        % current_start_index = i - min_srate + 1;
        current_end_index = i;
        % sum from current_start_index to current_end_index, inclusive
        current_sum = current_sum + zs(current_end_index) - zs(prev_start_index);
        current_artifact_sum = current_artifact_sum + is_artifact(current_end_index) - is_artifact(prev_start_index);
        if current_artifact_sum==0
        % bsr is avg of numbers contributing to sum. 
            bsr(i) = current_sum / min_srate;
        else
            bsr(i) = nan;
        end
    end
    
    % what we've calculated so far is ratio of bursts to suppressions.
    % flip the ratio for returning.
    bsr = 1 - bsr;
end

