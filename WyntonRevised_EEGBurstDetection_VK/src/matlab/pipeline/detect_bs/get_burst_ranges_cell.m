function [burst_ranges_cell] = get_burst_ranges_cell(global_zs,bs_ranges)
% GET_BURST_RANGES_CELL - Creates burst_ranges_cell 

% Input
%     bs_ranges -  matrix of shape [num_bs_episodes x 2], where bs_ranges(i, 1) and 
%         bs_ranges(i, 2) are the start and end indices, respectively, of the i-th 
%         burst suppression episode detected
%     global_zs - binary vector of length num_samples, where global_zs(i)=0 if 
%         sample i is part of a suppression, and global_zs(i)=1 if sample i is 
%         part of a burst

% Output
%     burst_ranges_cell - cell where i-th element is a matrix of burst ranges M_i for
%         burst suppression episode i. Specifically, M_i is a matrix of shape 
%         [num_bursts x 2], where M_i(j, 1) and M_i(j, 2) are the start and end indices, 
%         respectively, of the j-th burst of the i-th burst suppression episode.


all_burst_indices = find(global_zs==1);
num_bs = size(bs_ranges, 1);
burst_ranges_cell = cell(1, num_bs);
for k=1:num_bs
    start_ind = bs_ranges(k, 1);
    end_ind = bs_ranges(k, 2);
    burst_indices = all_burst_indices(all_burst_indices >= start_ind & ...
        all_burst_indices <= end_ind);
    burst_ranges = convert_indices_to_index_ranges(burst_indices, 2);
    burst_ranges_cell{k} = burst_ranges;
end

