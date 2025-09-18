function [] = artifact_Extract_Spectra(start,stop)

Fs = 100;
addpath(genpath('/nobackup1b/users/ghassemi/Analysis'));
addpath(genpath('/nobackup1b/users/ghassemi/EEGs'));
rmpath('/nobackup1b/users/ghassemi/Analysis/sccn_eeglab-eeglab-b5c3b5316735/functions/octavefunc/signal');
rmpath('/nobackup1b/users/ghassemi/Analysis/eeglab/functions/octavefunc/signal');
%/nobackup1b/users/ghassemi/Analysis/Supporting M Files/Artifact Detect/artifact_Extract_Spectra.m
%% GO TO THE MAIN DIRECTORY
cd('/nobackup1b/users/ghassemi/EEGs/CA_Merged')
search_me = '/nobackup1b/users/ghassemi/EEGs/CA_Merged'

%%  Extract all .mat files under this directory
file_list = getAllFiles([search_me]);
file_list = getSubsetWithKeywords(file_list,{'dEEG_5sec'},[]);


%% EXTRACT SPECTRAL BAND PROPERTIES FOR THE POPULATION.
for i = start:stop %length(file_list)
    
    
    %LOAD IN THE EEG FILE
    load(file_list{i});
    EEG.data = EEG.data;
    
    
    %% GET THE STATISTICAL MOMENTS
    ar.vars = squeeze(var(EEG.data,[],2));
    ar.skews = squeeze(skewness(EEG.data,[],2));
    ar.kurts = squeeze(kurtosis(EEG.data,[],2));   
    
    
    %% EXRACT THE 0-2 Hz BandPower for all subjects
    clear band_0_2;
    for j = 1:size(EEG.data,1)
        for k = 1:size(EEG.data,3)
            ar.band_0_2(j,k) = bandpower(EEG.data(j,:,k),Fs,[0.5,2]);       
        end
    end
    %fband_0_2{i} = band_0_2;
    
    
    %% Extract the 20-40 Hz BandPower for all subjects
    clear band_20_40
    for j = 1:size(EEG.data,1)
        for k = 1:size(EEG.data,3)
            ar.band_20_40(j,k) = bandpower(EEG.data(j,:,k),Fs,[20,40]);
        end
    end
    %fband_20_40{i} = band_20_40;
   
    
    %'Done with subject'
    %i
    
end
save(['ar_' num2str(i) '.mat'], 'ar','-v7.3')

%save(['dEEG_5sec_' name '.mat'], 'EEG')
%save fband_20_40 fband_20_40
%save fband_0_2 fband_0_2


end

