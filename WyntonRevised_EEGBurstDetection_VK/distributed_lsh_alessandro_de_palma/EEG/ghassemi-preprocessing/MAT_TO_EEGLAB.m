% COPYRIGHT: MOHAMMAD M. GHASSEMI
% MARCH 23RD, 2015
function []=MAT_TO_EEGLAB(start,stop)
    %% SUMMARY:
    %  THIS FUNCTION TAKES A .MAT FILE AND CONVERTS IT TO EEGLAB FORMAT:
    %  1. IT EXTRACTS THE FRIST 72 HOURS of DATA
    %  3. IT RE-REFERENCES THE DATA.
    diary on
    diary([num2str(start) '.txt'])
    
    addpath(genpath('/nobackup1b/users/ghassemi/Analysis'));
    addpath(genpath('/nobackup1b/users/ghassemi/EEGs'));
    rmpath('/nobackup1b/users/ghassemi/Analysis/sccn_eeglab-eeglab-b5c3b5316735/functions/octavefunc/signal');
    rmpath('/nobackup1b/users/ghassemi/Analysis/eeglab/functions/octavefunc/signal');
    %% PARAMETERS
    %These parameters dictate the format of the EEGLAB OUTPUT.
    Fs = 100;
    segment_length = (Fs)*5;  % THE EPOCH LENGTH IN SECS.

    % THE TOTAL NUMBER OF HOURS FROM ADMISSION YOU CARE ABOUT.
    %hours_cap = 24*3;
    %hours_cap = (60*Fs*60)*hours_cap;
    % TAKE ONE EVERY 'K' EPOCHS, So, if epoch length is 5 mins, and sample
    % every is 12, you are taking 1 five min sample, once an hour.
    sample_every = 1%12;

    % WHICH CHANNELS
    which_channels = 1:19

    
    load bwh_sids; load mgh_sids; load uTwente_sids; load yale_sids; load bidmc_sids
    sids = [bwh_sids;mgh_sids;uTwente_sids; yale_sids; bidmc_sids];
    %sids = bidmc_sids;
    
    search_me = '/nobackup1b/users/ghassemi/EEGs/CA_Merged'
    file_list = getAllFiles([search_me]);
    file_list = getSubsetWithKeywords(file_list,{'.mat','d_','all'},{''});
    
 
    %% FOR EACH SUBJECT ...
    for i = start:stop%1:length(th)
        %% EXTRACT THE SUBJECT DATA
        
        search_me = '/nobackup1b/users/ghassemi/EEGs'
        this_file = getAllFiles([search_me]);
        this_file = getSubsetWithKeywords(this_file,{'.mat','d_',sids{i},'all'},{});
    
        % Change to the right directory...
        slash_index = max(find(this_file{:} == '/'));        
        cd(this_file{:}(1:slash_index-1));
        
        % Grab the Right Fata File.
        PointToMat=matfile(this_file{:});
        details = whos(PointToMat);
        name = PointToMat.SID;
        
        %try to see if we can load this file and get the data from it.
        try
        load(['dEEG_5sec_' name '.mat']);
        EEG.data(1,1:100);
        
        %only if this fails, do you want to recompute everything.
        catch
        
        %% GET THE LENGTH OF THE DATA_FILE (in samples)
        data_length = [details.size] 
        data_length = max(data_length)
        
        %% ESTIMATE TOTAL NUMBER OF EPOCHS IN THIS FILE
        % num_epochs = floor(data_length/(segment_length));
        % num_epochs = length(1:segment_length*sample_every:data_length-segment_length)
        
        %% TAKE EITHER 72 HOURS, OR THE LENGTH OF THE DATA, IF IT'S LESS...
        % stop_here = min(hours_cap,data_length)
        stop_here = data_length;
        
        % And make sure we have a clean 5 min cut.
        stop_here=segment_length*floor(stop_here/segment_length);
        data = PointToMat.data(which_channels,1:stop_here);
        data(isnan(data)) = 0;
        
        % Import the EEGs 
        EEG = pop_importdata('data',data,...
                'dataformat','array',...
                'nbchan',length(which_channels),...
                'srate',Fs);   
       
        EEG.SID = name; 
         
        %% HIGHPASS FILTER THE EEG - 0.5 Hz
        EEG = pop_eegfilt(EEG, 0.5, 0, [], 0);

        %% REMOVE ANY LINE NOISE FROM THE EEG
        %THIS IS NOT REQUIRED IF YOU BP FILTER 0-50Hz.
%          EEG = pop_cleanline(EEG, 'Bandwidth',2,'ChanCompIndices',[1:EEG.nbchan],                 ...
%                                  'SignalType','Channels','ComputeSpectralPower',true,             ...
%                                  'LineFrequencies',[60 120] ,'NormalizeSpectrum',false,           ...
%                                  'LineAlpha',0.01,'PaddingFactor',2,'PlotFigures',false,          ...
%                                  'ScanForLines',true,'SmoothingFactor',100,'VerboseOutput',1,    ...
%                                  'SlidingWinLength',EEG.pnts/EEG.srate,'SlidingWinStep',EEG.pnts/EEG.srate);                 
  

        %% READ MGH LOCATIONS FILE.    
        EEG.chanlocs = readlocs('MGH.locs');

        %% REMOVE ANY BAD CHANNELS
        EEG = clean_channels(EEG,0.85,4);
        
        %% SET THE REFERENCE TO THE AVERAGE MONTAGE.
        %before you do this, you should add in a channel of zeros
        EEG.data = [EEG.data; zeros(1,size(EEG.data,2))];
        EEG = pop_reref(EEG, [],'refstate',0);        
               
        %% Epoch the Data.  
        EEG = pop_editset(EEG,'pnts',segment_length);
        
        %% Remove Offset/Baseline From the data.
        EEG = pop_rmbase(EEG, [], []);
        
        %% RUN THE PREP PIPELINE 5 MINS AT A TIME.
        %for j = 1:segment_length:stop_here 
            %this_data = PointToMat.data(which_channels,j:(j+segment_length-1));
            %this_data(isnan(this_data)) = 0;
            
            %% prepPipeline
            % THIS IS WHERE THE PRE-PROCESSING PIPELINE STARTS.
            % http://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline#High-pass_filter_the_data_at_1-Hz_.28for_ICA.2C_ASR.2C_and_CleanLine.29
            %this_EEG = prepPipeline(this_EEG)
            
            %EEG = this_EEG.data 
        %end 

       
        save(['dEEG_5sec_' name '.mat'], 'EEG','-v7.3');  
        end
    end
end



