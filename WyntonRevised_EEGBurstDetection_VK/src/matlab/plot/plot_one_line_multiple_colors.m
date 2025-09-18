function plot_one_line_multiple_colors(x, y, color_indices, colors)
% PLOT_ONE_LINE_MULTIPLE_COLORS - plot a multi-colored line. Called only by
%                                 plot_eeg.

% Input
%     x - x values
%     y - y values (must be same length as x)
%     color_indices - vector of indices into colors. color_indices{i} = j indicates
%         that point (x_i, y_i) should have color colors{j}. must be same length
%         as x.
%     colors - cell array of matlab color strings

    assert(min(color_indices) > 0, 'indices must all be greather than 0');
    assert(max(color_indices) <= length(colors), 'indices must be < length(colors');
    is_hold = ishold;
    hold on;
    for i=1:length(colors)
        color = colors{i};
        % get index ranges of color_indices which indicate this color
        color_ranges = convert_indices_to_index_ranges(find(color_indices==i));
        for j=1:size(color_ranges, 1)
            range_start = color_ranges(j, 1);
            range_end = color_ranges(j, 2);
            extended_range_end = min(range_end+1, length(x)); % Extend by 1 for continuous plot
            plot(x(range_start:extended_range_end), y(range_start:extended_range_end), color);
        end
    end
    if ~is_hold
        hold off;
    end
end

