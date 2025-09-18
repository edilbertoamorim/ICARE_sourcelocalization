function save_eeg_plot(eeg, save_dir_name, save_filename, varargin)
% SAVE_EEG_PLOT - Creates and saves a matlab figure with the eeg plot. 
%
% Input:
%     eeg - eeglab eeg object
%     save_dir_name - directory in which to save the plot
%     save_filename - name of the file in which to save the plot
%     varargin - optional parameters:
%           -- save_info - extra string tag to add to save_filename when saving the plot
%           -- all other parameters are passed to plot_eeg. See plot_eeg.m

    [save_info, varargin] = extract_varargin_arg('save_info', '', varargin{:});
    
    [start_index, ~] = plot_eeg_noninteractive(eeg, varargin{:});
    fig = gcf;

    set(fig,'PaperOrientation','landscape');
    set(fig, 'PaperUnits', 'inches');
    set(fig,'PaperPosition', [0 0 11 7]);
    if isempty(save_info)
        save_info_end = '';
    else
        save_info_end = strcat('_', save_info);
    end
    print(fullfile(save_dir_name, [save_filename, '_i', num2str(start_index), save_info_end, '.pdf']), '-dpdf');
    close all;
end