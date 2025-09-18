function [S] = get_similarities_for_episode(similarity_fn, episode_burst_info, data)
%GET_SIMILARITIES_FOR_EPISODE 
%   Calculates similarities for all burst pairs within a burst suppression
%   episode. 

% Input
%     similarity_fn - name of the similarity function to use. Either 'correlation'
%          (or 'xcorr') or 'dtw'
%     There are two ways to call this function:
%         1. with 3 arguments:
%             get_similarities_for_episode(similarity_fn, episode_burst_info, data)
%                 episode_burst_info - matrix of burst ranges for the episode 
%                     (one element of the burst_ranges_cell, as passed into similarity.m)
%                 data - whole eeg data matrix [nchans x nsamples]
%         2. with 2 arguments:
%             get_similarities_for_episode(similarity_fn, episode_burst_info, data)
%                 episode_burst_info - cell of length num_bursts containing 
%                     vectors of the signal data for each burst in the episode
% Output
%     S - symmetric matrix of size num_bursts x num_bursts, where
%         S(i,j) = similarity(burst_i, burst_j) when i~=j, and S(i,i) = 1

    if nargin < 3
        bursts_extracted = true;
        burst_data_cell = episode_burst_info;
    elseif nargin == 3
        bursts_extracted = false;
        burst_ranges = episode_burst_info;
    end
    
    channel=1; % todo: do more than one channel?

    if bursts_extracted
        num_bursts = length(burst_data_cell);
    else
        num_bursts = size(burst_ranges, 1);
    end
    
    % Normalize all the bursts before doing similarity
    normalize_bursts = SimilarityParams.get_params('normalize_bursts');
    if normalize_bursts
        for i=1:num_bursts
            if bursts_extracted
                burst = burst_data_cell{i};
                burst_data_cell{i} = normalize(burst);
            else
                burst_start = burst_ranges(i, 1);
                burst_end = burst_ranges(i, 2);
                burst = data(channel, burst_start:burst_end);
                data(channel, burst_start:burst_end) = normalize(burst);
            end
        end
    end
    
    % Get the param for how much to splice each burst
    burst_splice_time = SimilarityParams.get_params('burst_splice_time');
    % convert seconds to samples
    burst_splice_n_samples = burst_splice_time * PrepArtifactParams.get_params('target_frequency');
    
    % Initialize S, the matrix containing similarities. 
    S = zeros(num_bursts, num_bursts);
    num_pairs = num_bursts * (num_bursts - 1) / 2;
    pair_num = 0;
    % iterate through all pairs of bursts i and j, where i < j
    for i=1:num_bursts   % technically, stops at num_bursts-1 
        for j=(i+1):num_bursts
            pair_num = pair_num + 1;
            if rem(pair_num, 100000) == 0
                disp(['pair number ' num2str(pair_num) ' out of ' num2str(num_pairs)]);
            end
            if bursts_extracted
                burst_i = burst_data_cell{i};
                burst_j = burst_data_cell{j};
            else
                burst_i_start = burst_ranges(i, 1);
                burst_i_end = burst_ranges(i, 2);
                burst_j_start = burst_ranges(j, 1);
                burst_j_end = burst_ranges(j, 2);
                burst_i = data(channel, burst_i_start:burst_i_end);
                burst_j = data(channel, burst_j_start:burst_j_end);
            end
            if length(burst_i) > burst_splice_n_samples
                burst_i = burst_i(1:burst_splice_n_samples);
            end
            if length(burst_j) > burst_splice_n_samples
                burst_j = burst_j(1:burst_splice_n_samples);
            end
            pair_similarity = similarity_fn(burst_i, burst_j);
            S(i,j) = pair_similarity;
        end
    end
    % fill in the rest of matrix below the diagonal since it is symmetric
    S  = S + S';
    % fill in the diagonal with all ones, since similarity(x,x) should = 1.
    S = S + diag(ones(num_bursts, 1));
end

function [normalized] = normalize(data)
    mu = mean(data);
    sigma = std(data);
    normalized = (data - mu) / sigma;
end
