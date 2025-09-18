classdef DetectBsParams
    %DETECTBS_PARAMS Parameters used to detect_bs
    
    properties (Constant)
        
        %% Params for labeling z's (burst vs suppression)
        % Local z's labelling
        forgetting_time =  0.1047; % controls how much of recurisve mean/variance is based on past
        burst_threshold = 1.75; % min variance for sample to be considered burst
        % Combining z's from local to global
        agree_percent = 0.6; % what fraction of channels need to agree on a 1. 
        min_suppression_time = 0.5; % minimum duration (secs) of a suppression considered

        %% Params for bsr 
        % min suppression fraction considered to be "burst suppression"
        bsr_low_cutoff = 0.5;
        % max suppression fraction considered to be "burst suppression"
        bsr_high_cutoff = 1.0;
        % window length in seconds for smoothing used to calculate bsr
        bsr_window = 60;

        %% Params for getting BS episodes from bsr
        % minimum duration (secs) of a burst suppression episode considered
        min_bs_time = 10*60;
        % max time (secs) between two consecutive bs episodes 
        % that are considered as one continuous bs episode
        bs_episode_smoothing_amount = 60;
        
    end
    
    methods(Static)
        function varargout = get_params(varargin)
            for i = 1:length(varargin)
                varargout{i} = getfield(DetectBsParams, varargin{i});
            end
        end
    end
end

