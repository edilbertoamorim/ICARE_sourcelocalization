function [start_index, end_index] = plot_eeg(eeg, varargin)
% PLOT_EEG - plots an eeg. called by all top-level plotting functions

% Input
%     eeg - eeglab eeg object
%     vargargin - optional parameters, available options are:
%         start_index - index at which to start plotting
%         end_index - index at which to stop plotting
%         winlength - number of secs to plot. Alternative to end_index. 
%         is_shaded - binary vector of length equal to eeg. Sample i is
%               shaded iff is_shaded(i) = 1.
%         color_indices - vector of indices into colors. color_indices{i} = j indicates
%               that point (x_i, y_i) should have color colors{j}. 
%         colors - cell array of matlab color strings
%         global_zs - vector of global_zs to additionally plot. If
%               specified, bsr must also be specified. 
%         bsr - vector of bsr to additionally plot. If specified, global_zs
%               must also be specified.
%         
%         Note: If specified, global_zs, bsr, is_shaded, and color_indices 
%             must match the size of eeg.data

% Output:
%     start_index, end_index - the start and end indicies of the plotted window
    

%% Take care of all options
    
    options = struct();
    options.start_index = 1;
    options.winlength = 15;
    options.is_shaded = zeros(1, size(eeg.data, 2), 'int8');
    options.global_zs = [];
    options.bsr = [];
    for i = 1:2:numel(varargin)
       % Overwrite default parameters.
       options.(varargin{i}) = varargin{i+1};
    end
    num_nonempty_bsr_zs = 2 - isempty(options.bsr) - isempty(options.global_zs);

    if ~isfield(options, 'end_index')
        options.end_index = options.start_index + options.winlength * eeg.srate;
    end
    if ~isfield(options, 'color_indices')
        options.color_indices = ones(size(eeg.data, 1) + num_nonempty_bsr_zs, size(eeg.data, 2), 'int8');
    end
    if ~isfield(options, 'colors')
        all_colors = {'b', 'm', 'k', 'g', 'r', 'c', 'y'};
        options.colors = all_colors(1:max(options.color_indices(:)));
    end
    
    start_index = options.start_index;
    end_index = options.end_index;
    is_shaded = options.is_shaded;
    color_indices = options.color_indices;
    colors = options.colors;
    global_zs = options.global_zs;
    bsr = options.bsr;
    
    %% Do the plotting
    offset_size = 40;
    channel_labels = get_channel_labels_cell(eeg);
    hold on;
    x_axis = start_index:end_index;
    shaded_indices = find(is_shaded==1);
    shaded_indices = shaded_indices(shaded_indices >= start_index & shaded_indices <= end_index);
    shade_ranges = convert_indices_to_index_ranges(shaded_indices);
    
    offsets = [];
    for k=1:size(eeg.data, 1)+num_nonempty_bsr_zs
        offset = -1 * (k-1)*offset_size;
        offsets(k) = offset;
        if k <= size(eeg.data, 1)
            mean_data = mean(eeg.data(k, start_index:end_index));
            y = eeg.data(k, start_index:end_index)+offset-mean_data;
        else
            if k == size(eeg.data, 1) + 1 
                if ~isempty(global_zs)
                    to_plot = global_zs;
                else
                    to_plot = bsr;
                end
            elseif k == size(eeg.data, 1) + 2
                to_plot = bsr;
            end
            to_plot_amped = to_plot * offset_size;
            mean_data = mean(to_plot_amped(start_index:end_index));
            y = to_plot_amped(start_index:end_index)+offset-mean_data;
        end
            
        %plot(x_axis, y, 'k');
        plot_one_line_multiple_colors(x_axis, y, color_indices(k, start_index:end_index), colors);
    end
    yl = ylim;
    for shaded_region_no=1:size(shade_ranges, 1)
        x = shade_ranges(shaded_region_no, 1);
        y = yl(1);
        width = shade_ranges(shaded_region_no, 2) - shade_ranges(shaded_region_no, 1);
        height = yl(2) - yl(1);
        rectangle('Position', [x y width height], 'FaceColor', [0 0 1 0.2]);
        %ha = area(shade_ranges(shaded_region_no, :), [yl(2) yl(2)]);
    end
    % Label y axis with channels
    set(gca,'YTick', fliplr(offsets)); 
    yticklabels = channel_labels;
    if ~isempty(global_zs)
        yticklabels{end+1} = 'global\_zs';
    end
    if ~isempty(bsr)
        mean_bsr = mean(bsr(start_index:end_index));
        yticklabels{end+1} = ['avg bsr = ' num2str(mean_bsr)];
    end 
    set(gca,'YTickLabel',flip(yticklabels));
    % Set axis limits
    %set(gca, 'YLim', [offsets(1) - offset_size, offsets(end)+offset_size]);
    set(gca, 'YLim', [offsets(end) - offset_size, offsets(1)+offset_size]);
    set(gca, 'XLim', [start_index, end_index]);
    xlabel('samples');
    % Set x axis to not be in exponential notation
    curtick = get(gca, 'XTick');
    set(gca, 'XTickLabel', cellstr(num2str(curtick(:))));
    % Create second x axis with scale in seconds
    ax1 = gca; 
    ax1_pos = ax1.Position;
    ax2 = axes('Position',ax1_pos, 'XAxisLocation','top', ...
    'Color','none', 'YColor','none',...
    'XLim', [start_index/eeg.srate end_index/eeg.srate]);
    xlabel('secs');
end







