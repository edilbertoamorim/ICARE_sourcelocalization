function [is_artifact] = detect_artifacts(eeg)
% DETECT_ARTIFACTS - detects artifacts 

% Input
%     eeg - eeglab eeg object
% 
% Output
%     is_artifact - binary vector of length num_samples, where is_artifact(i)=1
%         if sample i has artifact, and 0 otherwise


%% Adapated from fcnDetectArtifacts from Westover
%% check for artifacts in 5 second blocks-- each block is counted all-or-none as artifact

% checks: 
% 1. amplitude in any channel > 500uv 
% 2. loose channel (gotman criteria)

data = eeg.data;
srate = eeg.srate;

chunk_size = PrepArtifactParams.get_params('chunk_size');
[saturation_threshold, std_threshold] = PrepArtifactParams.get_params(...
    'saturation_threshold', 'std_threshold');

chunk_end_ind=1;
chunk_num=0; 
done=0; 
Nt=size(data,2); 
is_artifact=zeros(1,Nt); 
Nc = size(data, 1);
is_artifact_m = zeros(size(data));

while ~done  
    %% get next data chunk
    chunk_start_ind=chunk_end_ind; 
    if chunk_end_ind==Nt; done=1; end
    
    chunk_end_ind=chunk_start_ind+round(srate*chunk_size);
    chunk_end_ind=min(chunk_end_ind,Nt);
    chunk_ind_range=chunk_start_ind:chunk_end_ind;
    chunk_num=chunk_num+1; % get next data chunk
    is_chunk_artifact=0; % set to 1 if artifact is detected
    is_chunk_artifact_v = zeros(Nc, 1);
    chunk_data=data(:, chunk_ind_range); % 5 second data chunk
    
    %% check for saturation
    channel_maxes = max(abs(chunk_data'));
    is_chunk_artifact_v(find(channel_maxes > saturation_threshold)) = 1;
    if any(channel_maxes > saturation_threshold)  % max across any channel > 500
        is_chunk_artifact=1; % max amplitude >500uv
    end 
    
    %% check for implausibly low variance
    v=std(chunk_data');
    is_chunk_artifact_v(find(v < std_threshold)) = 1;
    if any(v < std_threshold) % any channel has very low variance
        is_chunk_artifact=1; 
    end 
    
    is_artifact(chunk_ind_range)=is_chunk_artifact; 
    is_artifact_m(:, chunk_ind_range) = repmat(is_chunk_artifact_v, 1, length(chunk_ind_range));
end
artifact_timepoints = find(is_artifact==1);
artifact_ranges = convert_indices_to_index_ranges(artifact_timepoints);
