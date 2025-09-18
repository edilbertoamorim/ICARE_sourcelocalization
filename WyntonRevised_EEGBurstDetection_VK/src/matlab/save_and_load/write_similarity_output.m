function [] = write_similarity_output(file_path, similarities_cell, bs_ranges, similarity_fn, filtered_burst_ranges_cell)
% WRITE_SIMILARITY_OUTPUT - writes the output of running similarity
%   to files
%   
% file_path -       name of the edf for which this is the output for  
% similarities_cell - cell of similarities as outputted by similarity.m
% bs_ranges - matrix of burst suppression episodes as outputted by
%               detect_bs.m
% similarity_fn - either "dtw" or "xcorr" - the similarity function used
%                 to caluclate these similarity outputs
% filtered_burst_ranges_cell - optional. If given, it will be written to
%                               output files too.

    if nargin < 5
        write_burst_ranges = false;
    else
        write_burst_ranges = true;
    end
    
    output_dir = fullfile(Config.get_configs('output_dir'), 'similarity');
    [status, ~, ~] = mkdir(Config.get_configs('output_dir'), 'similarity');

    [~, filename_no_ext, ~] = fileparts(file_path);
    patient_id = get_pt_from_fname(file_path);
    
    % create results folder
    [status, ~, ~] = mkdir(output_dir, patient_id);
    [status, ~, ~] = mkdir(fullfile(output_dir, patient_id), filename_no_ext);

    is_oversized = is_output_oversized(similarities_cell);
    if is_oversized
        disp('Similarities cell with multiple episodes is oversized!');
    end
    
    for j=1:size(bs_ranges, 1)
        
        bs_start_ind = bs_ranges(j, 1);
        bs_end_ind = bs_ranges(j, 2);
        
        % Create a mat file for the episode containing the vector of
        % similarities for that episode

        if is_oversized
            disp(['episode ' num2str(j) ' with vector size ' num2str(length(similarities_cell{j}))]);
            disp('creating similarity_vector');
        end
        similarity_vector = similarities_cell{j}';
        if is_oversized
            disp('created similarity_vector, calling save function');
        end
        similarities_filename = [filename_no_ext '_' similarity_fn '_part' num2str(j) '_episode_idx_' num2str(bs_start_ind) '_' num2str(bs_end_ind)];
        similarities_filepath = fullfile(output_dir, patient_id, filename_no_ext, [similarities_filename '.mat']);
        save(similarities_filepath, 'similarity_vector', '-v7.3');
        if is_oversized
            disp(['success saving episode ' num2str(j)]);
        end
        
        if write_burst_ranges
        
            burst_ranges = filtered_burst_ranges_cell{j};
   
            burst_ranges_filename = [filename_no_ext '_burst_ranges_part' num2str(j) '_episode_idx_' num2str(bs_start_ind) '_' num2str(bs_end_ind)];
            burst_ranges_filepath = fullfile(output_dir, patient_id, filename_no_ext, [burst_ranges_filename '.csv']);
            write_matrix(burst_ranges_filepath, burst_ranges, '%.0f', '\t', {'burst_start_index', 'burst_end_index'});
        end
    end
    % Write a text file to indicate we are done.
    done_filepath = fullfile(output_dir, patient_id, filename_no_ext, [filename_no_ext '_done.txt']);
    fid = fopen(done_filepath, 'w');  
    fclose(fid);
end

function is_oversized = is_output_oversized(similarities_cell)
    total_sizes = 0;
    for i=1:length(similarities_cell)
        episode_similarity_size = length(similarities_cell{i});
        total_sizes = total_sizes + episode_similarity_size;
    end
    % We've found that under 8000 bursts, or 8000^2 burst pairs, generally is 
    % small enough and okay.
    is_oversized = (total_sizes > 8000^2);
end

