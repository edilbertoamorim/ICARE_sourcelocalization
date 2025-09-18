function [similarities_cell, filtered_burst_ranges_cell, bs_ranges, srate, burst_ranges_cell, burst_data_obj] = pipeline_up_to_similarity(file_path, similarity_fn, use_saved_detect_bs_output, save_detect_bs_output)
% PIPELINE_UP_TO_SIMILARITY - Runs entire pipeline up to and including similarity
% 
% Input:
%     file_path - path to edf to run pipeline on
%     similarity_fn - "dtw" or "xcorr" - name of similarity function to use when 
%         computing similarity
%     use_saved_detect_bs_output - boolean. if true and saved results exist
%           for the detect_bs portion of the pipeline, loads and uses the saved results
%           rather than recomputing them.
%     save_detect_bs_output - boolean. if true, saves any newly computed
%           detect_bs results to the 'describe_bs' subdirectory of the 'output_dir' 
%           defined in Config.m
%     
% Output
%     similarities_cell, filtered_burst_ranges_cell - output of simlarity.m
%           Note: if no burst suppression episodes, similarities_cell is
%           empty
%     bs_ranges, burst_ranges_cell - output of detect_bs.m
%     srate - sample rate used during calculations
%     burst_data_obj - if pipeline was actually run, the matrix of eeg data
%         if results were loaded, the episode_bursts_cell as returned by load_detect_bs.m

    if nargin < 3
        use_saved_detect_bs_output = 1;
    end
    if nargin < 4
        save_detect_bs_output = 1;
    end
    
    [~, filename_no_ext, ~] = fileparts(file_path);

    describe_bs_results_exist = do_describe_bs_results_exist(file_path);
    if use_saved_detect_bs_output && describe_bs_results_exist
        disp('loading saved detect_bs results...');
        tic
        [episode_bursts_cell, bs_ranges, burst_ranges_cell, srate] = load_detect_bs(filename_no_ext);
        toc
        burst_data_obj = episode_bursts_cell;
        [similarities_cell, filtered_burst_ranges_cell] = similarity(similarity_fn, srate, burst_ranges_cell, burst_data_obj);
    else
        % Run burst suppression detection stuff
        disp('running pipeline_up_to_detect_bs...');
        t = tic;
        [eeg, bs_ranges, global_zs, bsr, burst_ranges_cell, local_zs] = pipeline_up_to_detect_bs(file_path);
        disp('done pipeline up to detect bs, time taken: ');
        toc(t);
        srate = eeg.srate;
        burst_data_obj = eeg.data;
        % Write the results of burst suppression detection
        if save_detect_bs_output
            disp('saving detect_bs results');
            write_detect_bs_output(file_path, eeg, bs_ranges, global_zs, bsr, burst_ranges_cell);
        end
        
        [similarities_cell, filtered_burst_ranges_cell] = similarity(similarity_fn, srate, burst_ranges_cell, burst_data_obj);
    end
end

