function [results_exist] = do_similarity_results_exist(file_path)
% DO_SIMILARITY_RESULTS_EXIST - returns if saved similarity results already exist
%
% Params:
%   file_path - name of edf for which to check if results exist
%
% Output:
%   results_exist - boolean, true if saved results from running similarity
%       for file_path already exist. 
    output_dir = fullfile(Config.get_configs('output_dir'), 'similarity');

    [~, filename_no_ext, ~] = fileparts(file_path);
    patient_id = get_pt_from_fname(file_path);
    
    % If we've run and saved results before, the 'done.txt' file exists 
    done_filepath = fullfile(output_dir, patient_id, filename_no_ext, [filename_no_ext '_done.txt']);
    if exist(done_filepath, 'file') == 2
        results_exist = true;
    else
        results_exist = false;
    end
end

