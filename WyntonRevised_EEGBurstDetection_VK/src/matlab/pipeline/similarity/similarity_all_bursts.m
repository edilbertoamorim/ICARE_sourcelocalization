function [similarities_cell, similarities_matrix, filtered_burst_ranges_cell] = similarity_all_bursts(similarity_fn_name, srate, burst_ranges, burst_data_obj,bursts_to_analyze,units)

%SIMILARITY - Calculates similarities for all burst suppression episodes

% Input
%     similarity_fn_name - name of the similarity function to use. Either 'correlation'
%         (or 'xcorr') or 'dtw'
%     srate - sample rate of the eeg
%     burst_ranges_cell - cell where each element is matrix of burst ranges for the episode, 
%         as outputted by detect_bs
%     burst_data_obj - object containing the burst signals. Either:
%         1. whole eeg data matrix [nchans x nsamples]
%         2. cell of length num_bs_episodes, where each element is a cell of
%            length num_bursts containing vectors of the signal data for each
%            burst in the episode (as outputted by load_detect_bs.m)
%         Option 1 is used when calling after directly running detect_bs. 
%         Option 2 is used when calling after loading saved detect bs results.
%            
%    Output
%         similarities_cell - cell where i-th element is vector of
%             correlations between all pairs of bursts within the burst suppression
%             episodes
%         filtered_burst_ranges_cell - cell where i-th element is matrix of
%             burst_ranges for the i-th burst suppression episode which were
%             used to calculate similarities. 
%             Difference between this and input burst_ranges_cell is that 
%             filtered version has removed all burst ranges which are not between
%             min_burst_time and max_burst_time (defined in SimilarityParams)

    if strcmp(bursts_to_analyze,'a@l')
        bursts_to_analyze = 'all';
    end
    if strcmp(similarity_fn_name, 'correlation')
        similarity_fn = @correlation_all_bursts;
    elseif strcmp(similarity_fn_name, 'xcorr')
        % in case I accidentally call it xcorr
        similarity_fn = @correlation_all_bursts;
    elseif strcmp(similarity_fn_name, 'dtw')
        similarity_fn = @dtw_fn;
    else
        disp('Unknown similarity function name. Must be one of "correlation" or "dtw"');
    end
    
    if isempty(burst_data_obj)
        similarities_cell = [];
        similarities_matrix = [];
        filtered_burst_ranges_cell = [];
        return
    end
    
    
%     bursts_extracted: boolean. If true, indicates burst_data is cell of cell of burst vectors. 
%                            If false, indicates burst_data is whole eeg matrix.

    if iscell(burst_data_obj)
        % calculate using pre-gotten bursts
        bursts_extracted = true;
    else
        % calcualte using eeg data
        bursts_extracted = false;
    end
    
%     num_bs = length(burst_ranges_cell);
%     if num_bs==0
%         disp('Has no burst suppression episodes');
%         similarities_cell = {};
%         similarities_matrix = {};
%         filtered_burst_ranges_cell = burst_ranges_cell;
%         return
%     end
    
%     disp(['has bs episodes, calculating ' similarity_fn_name ' similarities...']);
%     
%     similarities_cell = cell(1, 1);
%     similarities_matrix = cell(1, 1);
%     filtered_burst_ranges_cell = cell(1, 1);

%     for k=1:num_bs
        num_bursts = size(burst_ranges, 1);

        if num_bursts < 2
            disp(['patient with 0 pairs of bursts! Skipping similarity analysis']);
            return;
        end
        disp(['num bursts ', num2str(num_bursts)]);
        
        %% Remove bursts which are shorter than min_burst_length or longer
        % than max_burst_length
        min_burst_slength = SimilarityParams.get_params('min_burst_time') * srate;
        max_burst_slength = SimilarityParams.get_params('max_burst_time') * srate;
        
        filtered_burst_ranges = burst_ranges(burst_ranges(:, 2) - burst_ranges(:, 1) + 1 >= min_burst_slength, :);
        filtered_burst_ranges = filtered_burst_ranges(filtered_burst_ranges(:, 2) - filtered_burst_ranges(:, 1) + 1 <= max_burst_slength, :);
        num_bursts_after_length_filter = size(filtered_burst_ranges, 1);
        
        if bursts_extracted
            % burst_data_obj is cell of burst vectors, remove bursts which are
            % too long or too short
            patient_burst_data_obj = burst_data_obj;
            filtered_burst_data_obj = patient_burst_data_obj(cellfun(@(burst_data)...
                length(burst_data) >= min_burst_slength && length(burst_data) <= max_burst_slength, ...
                patient_burst_data_obj));
            assert(length(filtered_burst_data_obj)==num_bursts_after_length_filter);
            patient_burst_data_obj = filtered_burst_data_obj;
        end
        
        if num_bursts_after_length_filter < 2
            disp(['patient with 0 pairs of bursts after length filter! Skipping similarity analysis']);
            similarities_cell = [];
            similarities_matrix = [];
            filtered_burst_ranges_cell = [];
            return;
        end
        disp(['num bursts after length filter', num2str(num_bursts_after_length_filter)]);
        
        if num_bursts_after_length_filter<bursts_to_analyze(2)
            bursts_to_analyze(2) = num_bursts_after_length_filter;
        end
        
        if num_bursts_after_length_filter < SimilarityParams.get_params('min_no_bursts')
            similarities_cell = [];
            similarities_matrix = [];
            filtered_burst_ranges_cell = [];
            return
        end
        %% select chunk of bursts
        if regexp(bursts_to_analyze,regexptranslate('wildcard','a*l'))
            disp('calculating similarities for all bursts')
        else
            if isequal(units,'bursts')
                burst_indices = linspace(bursts_to_analyze(1),bursts_to_analyze(2),bursts_to_analyze(2))
                filtered_burst_ranges = filtered_burst_ranges(burst_indices,:);
                patient_burst_data_obj = patient_burst_data_obj(:,burst_indices);
            end
        end
        
        %% Run similarities
        if bursts_extracted
            patient_similarities_matrix = get_similarities_for_all_bursts_patient(similarity_fn, patient_burst_data_obj);
        else
            patient_similarities_matrix = get_similarities_for_all_bursts_patient(similarity_fn, filtered_burst_ranges, patient_burst_data_obj);
        end
        
        %% Extract only the similarities of points i, j where i < j
        above_diagonal_mask = triu(true(size(patient_similarities_matrix)), 1);
        patient_similarities_vector = patient_similarities_matrix(above_diagonal_mask);
        similarities_cell = patient_similarities_vector;
        similarities_matrix = patient_similarities_matrix;
        filtered_burst_ranges_cell = filtered_burst_ranges;
%     end
end
