function [] = write_similarity_all_bursts_output(pt_id, similarities_cell, similarities_matrix, similarity_fn,bursts_to_analyze,units,filtered_burst_ranges_cell,selected_sorted_all_episodes_data,distance_of_episode_from_target)

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
% 
%     if nargin < 9
%         write_burst_ranges = false;
%     else
        write_burst_ranges = true;
%     end
    
    if isequal(bursts_to_analyze,'all')
        bursts_to_analyze_window = 'all'
        disp('calculating similarities for all bursts')
    else
        first_burst = bursts_to_analyze(1)
        last_burst = bursts_to_analyze(2)
        bursts_to_analyze_window = strcat('burst_',string(first_burst),'_thru_',string(last_burst));
    end
    
    output_dir = fullfile(Config.get_configs('output_all_bursts_dir'), 'similarityAll');
    [status, ~, ~] = mkdir(Config.get_configs('output_all_bursts_dir'), 'similarityAll');

%     [~, filename_no_ext, ~] = fileparts(file_path);
    patient_id = pt_id
    
    % create results folder
    [status, ~, ~] = mkdir(output_dir, patient_id);
    [status, ~, ~] = mkdir(fullfile(output_dir, patient_id));

    is_oversized = is_output_oversized(similarities_cell);
    if is_oversized
        disp('Similarities cell with multiple episodes is oversized!');
    end
    
%     for j=1:size(bs_ranges, 1)
        
%         bs_start_ind = bs_ranges(j, 1);
%         bs_end_ind = bs_ranges(j, 2);
        
        % Create a mat file for the episode containing the vector of
        % similarities for that episode

%         if is_oversized
%             disp(['episode ' num2str(j) ' with vector size ' num2str(length(similarities_cell{j}))]);
%             disp('creating similarity_vector');
%         end
    if ~isempty(similarities_cell)
        similarity_vector = similarities_cell';
        similarity_matrix = similarities_matrix';
%         if is_oversized
%             disp('created similarity_vector, calling save function');
%         end
        similarities_filename = strcat(pt_id, '_', similarity_fn, '_', bursts_to_analyze_window,'.mat');
        similarities_matrix_filename = strcat(pt_id, '_similarities_matrix_', similarity_fn, '_', bursts_to_analyze_window,'.mat');
        similarities_episode_distance_from_target_filename = strcat(pt_id,'_distance_of_episode_from_target_',similarity_fn,'_',bursts_to_analyze_window, '.mat');
        sorted_all_episodes_data_filename = strcat(pt_id,'_sorted_all_episodes_data_filename_',similarity_fn,'_',bursts_to_analyze_window,'.mat');
        
        similarities_filepath = fullfile(output_dir, patient_id,similarities_filename);
        similarities_matrix_filepath = fullfile(output_dir, patient_id,similarities_matrix_filename);
        similarities_episode_distance_from_target_filepath = fullfile(output_dir, patient_id,similarities_episode_distance_from_target_filename);
        similarities_episodes_sorted_data_filepath = fullfile(output_dir,patient_id,sorted_all_episodes_data_filename);
        
        save(similarities_filepath, 'similarity_vector', '-v7.3');
        save(similarities_matrix_filepath, 'similarity_matrix', '-v7.3');
        save(similarities_episode_distance_from_target_filepath,'distance_of_episode_from_target','-v7.3');
        save(similarities_episodes_sorted_data_filepath,'selected_sorted_all_episodes_data','-v7.3');
        
        if is_oversized
            disp('success saving similarities');
        end
        
        if write_burst_ranges
        
            burst_ranges = filtered_burst_ranges_cell;
   
            burst_ranges_filename = strcat(pt_id, '_burst_ranges_', bursts_to_analyze_window);
            burst_ranges_filepath = fullfile(output_dir, patient_id, strcat(burst_ranges_filename, '.csv'));
            burst_ranges_filepath_mat = fullfile(output_dir, patient_id, strcat(burst_ranges_filename,'.mat'));
            
            write_matrix(burst_ranges_filepath, burst_ranges, '%.0f', '\t', {'burst_start_index', 'burst_end_index'});
            save(burst_ranges_filepath_mat,'burst_ranges')
        end
    end
    
    % Write a text file to indicate we are done.
    done_filepath = fullfile(output_dir, patient_id, [patient_id '_done.txt']);
    fid = fopen(done_filepath, 'w');  
    fclose(fid);
end

function is_oversized = is_output_oversized(similarities_cell)
    
    total_sizes = 0;
%     for i=1:length(similarities_cell)
        pt_similarity_size = length(similarities_cell);
        total_sizes = total_sizes + pt_similarity_size;
%     end
    % We've found that under 8000 bursts, or 8000^2 burst pairs, generally is 
    % small enough and okay.
    is_oversized = (total_sizes > 8000^2);
end

