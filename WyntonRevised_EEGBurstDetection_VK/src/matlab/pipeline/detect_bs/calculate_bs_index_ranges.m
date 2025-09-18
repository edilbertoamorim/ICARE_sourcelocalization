function [bs_ranges] = calculate_bs_index_ranges(bsr, srate)
% CALCULATE_BS_INDEX_RANGES - Returns start and end indices of burst
%   burst suppression episodes

% Input
%     bsr - binary vector of length num_samples, where bsr(i) is a number between 0
%         and 1 and gives the ratio of suppressions to bursts at time sample i
%     srate - sample rate of the signal

% Output
%     bs_ranges -  matrix of shape [num_bs_episodes x 2], where bs_ranges(i, 1) and 
%         bs_ranges(i, 2) are the start and end indices, respectively, of the i-th 
%         burst suppression episode detected

    [bsr_low_cutoff, bsr_high_cutoff, bsr_window] = DetectBsParams.get_params('bsr_low_cutoff', 'bsr_high_cutoff', 'bsr_window');
    bs_timepoints = find(bsr > bsr_low_cutoff & bsr < bsr_high_cutoff);
    smoothing_amt = DetectBsParams.get_params('bs_episode_smoothing_amount') * srate;
    bs_ranges = convert_indices_to_index_ranges(bs_timepoints, smoothing_amt);
    bs_ranges(:, 1) = bs_ranges(:, 1) - bsr_window;
end

