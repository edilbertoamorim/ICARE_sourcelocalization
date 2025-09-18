function [] = Mark_Artifacts( start, stop )

Fs = 100;
addpath(genpath('/nobackup1b/users/ghassemi/Analysis'));
addpath(genpath('/nobackup1b/users/ghassemi/EEGs'));
rmpath('/nobackup1b/users/ghassemi/Analysis/sccn_eeglab-eeglab-b5c3b5316735/functions/octavefunc/signal');
rmpath('/nobackup1b/users/ghassemi/Analysis/eeglab/functions/octavefunc/signal');

cd('/nobackup1b/users/ghassemi/EEGs/CA_Merged')
search_me = '/nobackup1b/users/ghassemi/EEGs/CA_Merged'

%%  Extract all .mat files under this directory
file_list = getAllFiles([search_me]);
file_list = getSubsetWithKeywords(file_list,{'dEEG_'},[]);

for i = start:stop
    %COMPUTE_ARTIFACT_INDICIES;
    
    
    ptm=matfile(file_list{i},'Writable',true);
    
    try
        ptm.rejzeros;     
    catch
    EEG = ptm.EEG;
    numchannels = size(EEG.data,1);

    
    
    %% GET THE LENGTH OF THE DATA_FILE (in samples)
    
    %% GENERATE STATIC THRESHOLDS
    threshold = 1000;
    artifact_Zeros_Thresh( file_list{i}, threshold )
    
    %% MARK EPOCHS WITH EYE ARTIFACTS.
    load fband_0_2; 
    artifact_Find_Eye( file_list{i}, fband_0_2 , numchannels, i)
    
    %% MARK EPOCHS WITH MUSCLE ARTIFACTS.
    load fband_20_40;
    artifact_Find_Muscle( file_list{i}, fband_20_40, numchannels, i )
    
    %% EXTRACT MOMENT DISTRIBUTION MEAN AND STDEVs
    numstds = 3;
    variance_lower_threshold = 0.001;
    
    %% Mark strange variance
    load vars;
    artifact_Find_Vari(file_list{i},numstds,variance_lower_threshold,vars, i);
    
    %% Mark strange skew
    load skews;
    artifact_Find_Skew(file_list{i},numstds,skews, i);
    
    %% Mark strange kurtosis
    load kurts;
    artifact_Find_Kurt(file_list{i},numstds,kurts, i);
    
    end   
end

end

