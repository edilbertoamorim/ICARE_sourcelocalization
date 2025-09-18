function [start_index, end_index] = plot_eeg_noninteractive(eeg, varargin)
% PLOT_EEG_NONINTERACTIVE - Creates a matlab figure with the eeg plot
%
% Input:
%     eeg - eeglab eeg object
%     varargin - optional parameters passed to plot_eeg (see plot_eeg)
%     
% Output:
%     start_index, end_index - the start and end indicies of the plotted window
    
    figure;
    [start_index, end_index] = plot_eeg(eeg, varargin{:});
end

