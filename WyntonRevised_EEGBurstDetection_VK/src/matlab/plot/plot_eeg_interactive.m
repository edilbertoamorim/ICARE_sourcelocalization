function plot_eeg_interactive(eeg, varargin)
    [start_index, end_index] = plot_eeg(eeg, varargin{:});
    while true
        window_size = end_index - start_index;

        w = waitforbuttonpress;
        if w == 1 % (keyboard press) 
            key = get(gcf,'CurrentKey'); 
            switch key
                case 'f'
                    new_start_index = end_index;
                case 'b'
                    new_start_index = start_index - window_size;
                case 'e'
                    close;
                    return;
            end
        else
            % mouse press. Default, go forward
            new_start_index = end_index;
        end
        hold on;
        clf;

        [~, varargin] = extract_varargin_arg('start_index', '', varargin{:});
        [~, varargin] = extract_varargin_arg('end_index', '', varargin{:});
        [start_index, end_index] = plot_eeg(eeg, 'start_index', new_start_index, ...
            'end_index', new_start_index+window_size, ...
            varargin{:});
    end
end

