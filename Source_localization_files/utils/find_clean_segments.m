function [idx_per_hour, rows_per_hour] = find_clean_segments(tbl, labels_resolution, signal_length, Fs, log_filename, artifact_threshold)
% FIND_CLEAN_SEGMENTS
%
% Purpose:
%   Given a table describing signal segments (each row = labels_resolution seconds)
%   and a has_artifact column (0 = clean, 1 = artifact),
%   this function finds, for every hour in the recording, the first
%   clean segment of length (signal_length minutes). The output includes:
%       - sample indices in the original signal
%       - table row indices used for each hour
%
% Inputs:
%   tbl : table with at least the variable has_artifact
%   labels_resolution : duration of each segment in seconds
%   signal_length    : required clean duration in minutes
%   Fs               : sampling frequency of the original signal
%
% Outputs:
%   idx_per_hour  : cell array {h} → [start_sample end_sample]
%   rows_per_hour : cell array {h} → vector of row indices from tbl
%
% Assumptions:
%   - Recording is continuous.
%   - tbl rows are consecutive and equal in duration.
%

% Artifact threshold [%]
% percentage threshold of allowed artifacts (e.g. 0.10 = 10%)
if nargin < 6
    artifact_threshold = 0.01;  
end

%% ---- basic checks
if ~istable(tbl)
    error('Labels table must be a MATLAB table.');
end
if ~ismember('has_artifact', tbl.Properties.VariableNames)
    error('Labels Table must contain column has_artifact.');
end

artifact = tbl.has_artifact(:);
nSeg = numel(artifact);
segDur = labels_resolution;
totalDur = nSeg * segDur;

% number of hours in the recording
nHours = ceil(totalDur / 3600);

% segments needed for required clean duration
reqDuration = signal_length * 60;
reqSeg = reqDuration / segDur;

if abs(reqSeg - round(reqSeg)) > 1e-9
    error('Requested duration is not an integer multiple of segment length.');
end
reqSeg = round(reqSeg);

% outputs
idx_per_hour  = cell(nHours, 1);
rows_per_hour = cell(nHours, 1);

%% ---- main loop per hour
for h = 1:nHours

    % hour boundaries in seconds
    hour_start_sec = (h - 1) * 3600;
    hour_end_sec   = h * 3600;

    % convert to segment indices
    seg_start = floor(hour_start_sec / segDur) + 1;
    seg_end   = min(nSeg, floor(hour_end_sec / segDur));

    if seg_start > nSeg
        warning('Hour %d exceeds recording length — no data available.', h);
        idx_per_hour{h}  = [];
        rows_per_hour{h} = [];
        continue;
    end

    art_vec = artifact(seg_start:seg_end);

    % look for first clean window
    win_found = false;

    for i = 1:(numel(art_vec) - reqSeg + 1)

        % extract window
        win = art_vec(i:i+reqSeg-1);
    
        % compute artifact percentage
        artifact_fraction = mean(win == 1);
    
        % accept window if below threshold
        if artifact_fraction <= artifact_threshold

            % global segment indices
            global_seg_start = seg_start + i - 1;
            global_seg_end   = global_seg_start + reqSeg - 1;

            % sample indices
            samples_per_seg = segDur * Fs;
            start_sample = (global_seg_start - 1) * samples_per_seg+1;
            end_sample   =  start_sample + reqDuration * Fs;

            % output
            idx_per_hour{h}  = start_sample:end_sample;
            rows_per_hour{h} = global_seg_start:global_seg_end;

            win_found = true;
            break;
        end
    end

    % no clean window
    if ~win_found
        text = "No clean data for hour " + num2str(h);
        write_log(log_filename, text, 0); 
        idx_per_hour{h}  = [];
        rows_per_hour{h} = [];
    end
end

end


