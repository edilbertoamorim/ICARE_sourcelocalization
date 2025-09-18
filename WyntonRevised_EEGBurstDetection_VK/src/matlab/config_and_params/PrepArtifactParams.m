classdef PrepArtifactParams
    %PreprocessParams Parameters used for preprocessing and artifact
    %detection
    
    properties (Constant)
        
        %% Params for standardization
        % Convert all eegs to this target frequency.
        % Code in 'standardize_struct' must be consistent with this!
        % ('In Alessandro's repo: EEG/scripts/standardize_struct.m');
        target_frequency = 200;
        
        %% Params for preprocessing 
        % High pass filter params
        hp_filter_order = 4;
        low_freq_threshold = 0.5;
        % Low pass filter params
        lp_filter_order = 4;
        high_freq_threshold = 50;
        % Notch filter params
        notch_filter_order = 6;
        notch_low_threshold = 55;
        notch_high_threshold = 65;
        
        %% Params for artifact detection 
        % chunk size (secs) 
        chunk_size = 5;
        % max amplitude (uV) above which we have saturation artifact
        saturation_threshold = 500;
        % min standard deviation below which we have "no signal" artifact
        std_threshold = 0.0001;
    end
    
    methods(Static)
        function varargout = get_params(varargin)
            for i = 1:length(varargin)
                varargout{i} = getfield(PrepArtifactParams, varargin{i});
            end
        end
    end
end



