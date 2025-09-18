function [global_binary_signal, finalBS_nan_locations ] = combine_local_zs_labels(binary_signal, nan_locations)

% Find global binary signal based on common suppression only
% See paper - https://www.ncbi.nlm.nih.gov/pubmed/26738009
% Created by: Jingzhi An
% Date: 30 december 2014
% Updated: 26 december 2015

% Subfunction required
%    - BS4RSE_fcn_fillnan.m
    
    %display('## Generating Global Binary Signal based on common suppression only');
    
    agree_percent = DetectBsParams.get_params('agree_percent');
    
    [channel_no, sample_no] = size(binary_signal);
    
    binary_signal(nan_locations) = NaN;
    
    sum_binary_signal = nansum(binary_signal, 1);   % for each time point, what is the total binary signal
    sum_nan = sum(nan_locations,1);                 % for which time point there is no data at all;    
    
    valid_channel = channel_no - sum_nan;           % 19 - number of NaN in that position
    
    temp_binary_signal = zeros(1, sample_no);       % define final_binary_signal being 1 x sample_no variable 
    
    if channel_no > 3
        temp_binary_signal ((sum_binary_signal >= ceil(valid_channel*agree_percent)) & (valid_channel >= 3 )) = 1; % more than 80% of channels with valid data agree
        temp_binary_signal (sum_nan > (channel_no - 3)) = NaN;
    else
        temp_binary_signal ((sum_binary_signal >= ceil(valid_channel*agree_percent)) & (valid_channel == 2 )) = 1; 
        temp_binary_signal (sum_nan == channel_no) = NaN;
    end
    [global_binary_signal, finalBS_nan_locations] = BS4RSE_fcn_fillnan(temp_binary_signal);  


end

function [filled_signal, nan_positions] = BS4RSE_fcn_fillnan(signal)
% Replicate nearby data to fill in the NaN positions
% this will later enable the subsequent section where filter has to be used
% in preprocessing

%display('## Replacing NaN in EEG file with replication of nearby data');

% set up parameters
[channel_no, sample_no] = size(signal);
filled_signal = signal;
nan_positions = isnan(signal);

for i = 1 : channel_no
        
    %display(strcat('# Working on channel :', num2str(i), '/', num2str(channel_no)));
  
    total_nan = sum(nan_positions(i,:));

    if total_nan ~=0 && total_nan ~= sample_no                                                

        % Identify where all the NaNs are
        nan_startnstop = diff(nan_positions(i,:));
        nan_start_index = find(nan_startnstop == 1);
        nan_stop_index = find(nan_startnstop == -1);

        first_event_index = find(nan_startnstop ~=0, 1, 'first');
        first_event = nan_startnstop(first_event_index);
        last_event_index = find(nan_startnstop ~=0, 1, 'last');
        last_event = nan_startnstop(last_event_index);

         % Find special cases
        if first_event == -1
            nan_start_index = horzcat(0, nan_start_index);
        end

        if last_event == 1
            nan_stop_index = horzcat(nan_stop_index, sample_no);
        end

        % Find durations
        nan_durations = nan_stop_index - nan_start_index;
        data_durations = horzcat(nan_start_index(1)-0, nan_start_index(2:end) - nan_stop_index(1:end-1), sample_no - max(nan_stop_index));
        nan_prior_durations = data_durations(1:end-1);
        nan_posterior_durations = data_durations(2:end);
            
        % define type
        type_1 = find(nan_durations <= nan_prior_durations);
        type_2 = find(nan_durations <= (nan_prior_durations + nan_posterior_durations) & nan_durations > nan_prior_durations);
        type_3 = find(nan_durations > (nan_prior_durations + nan_posterior_durations));

        for w = type_1
            gap_index = (nan_start_index(w)+1) : nan_stop_index(w);
            filled_signal(i, gap_index) = signal(i, gap_index - length(gap_index));    
        end

        for x = type_2
            gap_index = (nan_start_index(x)+1): nan_stop_index(x);
            gap_posterior_duration_needed = nan_durations(x) - nan_prior_durations(x);
            filled_signal(i, gap_index) = signal(i, [(nan_start_index(x) - nan_prior_durations(x) +1):nan_start_index(x) (nan_stop_index(x) + (1:gap_posterior_duration_needed))]);
        end

        for z = type_3
            gap_index = (nan_start_index(z)+1) : nan_stop_index(z);
            datalength_beforenafter = nan_prior_durations(z) + nan_posterior_durations(z);
            times = floor(length(gap_index)/datalength_beforenafter);
            rmd = mod(length(gap_index), datalength_beforenafter);

            data_front = signal(i, (nan_start_index(z) - nan_prior_durations(z)+1):nan_start_index(z));
            data_back = signal(i, nan_stop_index(z)+(1:nan_posterior_durations(z)));
            data_frontnback = horzcat(data_front, data_back);

            data_for_gap_front = repmat(data_front ,1, times);
            data_for_gap_back = repmat(data_back, 1, times);
            data_for_gap_rmd = data_frontnback(1:rmd);

            filled_signal(i, gap_index) = horzcat(data_for_gap_front, data_for_gap_rmd, data_for_gap_back);

         end 

    end
 
end
end

