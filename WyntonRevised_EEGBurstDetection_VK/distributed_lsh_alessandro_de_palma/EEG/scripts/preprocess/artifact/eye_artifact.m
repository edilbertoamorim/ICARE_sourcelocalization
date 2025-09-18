function [ rejeye ] = eye_artifact( stats_cell, eye_upper, eye_lower, numchannels, i )
%eye_artifact Returns the epochs of patient i (ordering of global_PREPed_list.txt) which contain eye artifacts.
% Adapted from Ghassemi.

    %TODO: in case interpolated data must not be used, this might have to be modified.

    %find the artifact locations
    [chans,epoch_num] = (find(stats_cell.power_0_2_band{i} > eye_upper | stats_cell.power_0_2_band{i} < eye_lower));
    % Finds the indices at which the above is true.

    %TODO: does this make any sense or can we just do as in kurt_artifact? Why was Mohammad doing this?
    %for each of the channels.
    artifacts = logical(zeros(size(stats_cell.power_0_2_band{i},1),size(stats_cell.power_0_2_band{i},2)));
    for j = 1:numchannels
       ind = logical(chans == j); % Find the indices in chans which are the current channel.
       artifacts(j,epoch_num(ind)) = true ;
    end
    rejeye = artifacts;

end
