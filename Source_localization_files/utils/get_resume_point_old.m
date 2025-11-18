function [start_file_idx, p_start, last_seg, last_part] = get_resume_point_old(dir_out, patient_ID, segments)
%GET_RESUME_POINT  Determine where to resume processing segments and parts
%
%   [start_file_idx, p_start, last_seg, last_part] = get_resume_point(dir_out, patient_ID, segments)
%
%   INPUTS:
%       dir_out    - Base output directory containing "03_FeaturesTables"
%       patient_ID - String with patient identifier (e.g., '0284')
%       segments   - Cell array with segment names (e.g., {'001_004','002_005'})
%
%   OUTPUTS:
%       start_file_idx - Index of the segment to start processing in 'segments'
%       p_start        - Part number to start from (1–xx)
%       last_seg       - Last processed segment name (empty if none found)
%       last_part      - Last processed part number (0 if none found)
%
%   The function assumes files are saved as:
%       <patient_ID>_Seg<segment>_Part<part>_ROI_Features.xls
%
%   Example:
%       [idx, part] = get_resume_point('/data/output', '0284', {'001_004','002_005'});

    % Directory where the feature files are stored
    dir_table = dir_out;

    % Search for all processed files for this patient
    search_pattern = sprintf('%s_*_*_ROI_Features.xls', patient_ID);
    existing_files = dir(fullfile(dir_table, search_pattern));

    % If nothing is found, start from scratch
    if isempty(existing_files)
        fprintf('No preprocessed files found for patient %s. Starting fresh.\n', patient_ID);
        last_seg = '';
        last_part = 0;
        start_file_idx = 1;
        p_start = 1;
        return;
    end

    % Find the most recently modified file
    [~, newest_idx] = max([existing_files.datenum]);
    last_file = existing_files(newest_idx).name;

    % Extract the segment (e.g., '001_004') and part number (e.g., 1)
    tokens = regexp(last_file, ...
        sprintf('%s_(\\d+_\\d+)_ROI_Features', patient_ID), ...
        'tokens', 'once');
    % sprintf('%s_Seg(\\d+_\\d+)_Part(\\d+)_ROI_Features', patient_ID),

    if isempty(tokens)
        error('File naming format is incorrect: %s', last_file);
    end

    last_seg = tokens{1};        % e.g., '001_004'
    last_part = 1;
    % last_part = str2double(tokens{2});  % e.g., 1

    fprintf('Last processed file: %s\n', last_file);
    % fprintf('Segment: %s | Part: %d\n\n', last_seg, last_part);

    % Find index of last processed segment in provided list
    last_seg_idx = find(strcmp(segments, last_seg), 1, 'last');

    if isempty(last_seg_idx)
        error('Segment "%s" from the last file not found in provided segment list.', last_seg);
    end

    % Decide where to resume
    start_file_idx = last_seg_idx + 1;
    p_start = 1;
    % if last_part >= 10
    %     % If last part was 10, move to next segment
    %     start_file_idx = last_seg_idx + 1;
    %     p_start = 1;
    % else
    %     % Continue with the same segment
    %     start_file_idx = last_seg_idx;
    %     p_start = last_part + 1;
    % end

    % Safety check: if beyond last segment
    if start_file_idx > length(segments)
        fprintf('All segments already processed for patient %s.\n', patient_ID);
        start_file_idx = length(segments) + 1;  % indicates processing is done
        p_start = 1;
    end
end

