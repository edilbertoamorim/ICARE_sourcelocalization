function [results_exist] = do_similarity_all_bursts_results_exist_with_similarities(pt_id)
% DO_SIMILARITY_RESULTS_EXIST - returns if saved similarity results already exist
%
% Params:
%   file_path - name of edf for which to check if results exist
%
% Output:
%   results_exist - boolean, true if saved results from running similarity
%       for file_path already exist. 
    output_dir = fullfile(Config.get_configs('output_all_bursts_dir'), 'similarityAll');
    if exist(fullfile(output_dir,pt_id),'dir')
        if length(dir(fullfile(output_dir,pt_id,'*.mat')))>1
            results_exist = true;
        else
            results_exist = false;
        end
    else
        results_exist = false;
    end
%     [~, filename_no_ext, ~] = fileparts(pt_id);
%     patient_id = get_pt_from_fname(pt_id);
%     
%     % If we've run and saved results before, the 'done.txt' file exists 
%     done_filepath = fullfile(output_dir, patient_id, filename_no_ext, [filename_no_ext '_done.txt']);
%     if exist(done_filepath, 'file') == 2
%         results_exist = true;
%     else
%         results_exist = false;
%     end
end

