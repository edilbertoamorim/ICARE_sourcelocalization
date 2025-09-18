function [global_zs] = label_global_zs(data,srate)
% LABEL_GLOBAL_ZS - Label which samples are part of a burst, and which are
%   part of a supression

% Input
%     data - matrix of size [num_channels x num_samples] of eeg data
%     srate - sample rate of the eeg data signal

% Ouput
%     global_zs - binary vector of length num_samples, where global_zs(i)=0 if 
%         sample i is part of a suppression, and global_zs(i)=1 if sample i is 
%         part of a burst

min_suppression_time = DetectBsParams.get_params('min_suppression_time');
zs = label_local_zs(data, srate);
nan_locations = logical(zeros(size(zs)));
[global_zs, ~] = combine_local_zs_labels(zs, nan_locations);
min_suppression_slength = srate * min_suppression_time;
suppression_indices = find(global_zs==0);
suppression_ranges = convert_indices_to_index_ranges(suppression_indices);
for i=1:size(suppression_ranges, 1)
    start_ind = suppression_ranges(i, 1);
    end_ind = suppression_ranges(i, 2);
    if (end_ind - start_ind + 1) < min_suppression_slength
        global_zs(start_ind:end_ind) = 1;
    end
end

