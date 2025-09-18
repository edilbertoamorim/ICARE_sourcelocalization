function [bs_ranges, global_zs, bsr, burst_ranges_cell] = detect_bs(eeg, is_artifact)
% DETECT_BS - Detects burst suppression episodes in a signal

% Input
%     eeg - eeglab eeg object whose 'data' field is a matrix of size [num_channels x num_samples]
%     is_artifact - binary vector length num_samples where is_artifact(i)=1
%         when sample i is artifact, and 0 otherwise
% 
% Ouput
%     bs_ranges -  matrix of shape [num_bs_episodes x 2], where bs_ranges(i, 1) and 
%         bs_ranges(i, 2) are the start and end indices, respectively, of the i-th 
%         burst suppression episode detected
%     global_zs - binary vector of length num_samples, where global_zs(i)=0 if 
%         sample i is part of a suppression, and global_zs(i)=1 if sample i is 
%         part of a burst
%     bsr - binary vector of length num_samples, where bsr(i) is a number between 0
%         and 1 and gives the ratio of suppressions to bursts at time sample i
%     burst_ranges_cell - cell where i-th element is a matrix of burst ranges M_i for
%         burst suppression episode i. Specifically, M_i is a matrix of shape 
%         [num_bursts x 2], where M_i(j, 1) and M_i(j, 2) are the start and end indices, 
%         respectively, of the j-th burst of the i-th burst suppression episode.

data = eeg.data;
global_zs = label_global_zs(data,eeg.srate);
[bsr] = calculate_bsr(global_zs, eeg.srate, is_artifact);
bs_ranges = calculate_bs_index_ranges(bsr, eeg.srate);
% Filter out burst suppression episodes which are too short
min_bs_time = DetectBsParams.get_params('min_bs_time');
min_bs_slength = min_bs_time*eeg.srate;
bs_ranges = bs_ranges(bs_ranges(:, 2) - bs_ranges(:, 1) >= min_bs_slength, :);
burst_ranges_cell = get_burst_ranges_cell(global_zs, bs_ranges);
end

