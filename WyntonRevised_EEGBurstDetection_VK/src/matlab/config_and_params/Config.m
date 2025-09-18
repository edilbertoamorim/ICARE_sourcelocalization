classdef Config
    % Class which stores basic config for scripts, such as repo path
    
    properties (Constant)


        % where to save script output
        output_dir = './Data/OUTPUT/bs_pipeline_eeglab_preprocessed';
        %output_all_bursts_dir = './bspipeline_eeglab_burst';

    end
    
    methods(Static)
        function varargout = get_configs(varargin)
            for i = 1:length(varargin)
                varargout{i} = getfield(Config, varargin{i});
            end
        end
    end
end

