function [] = reEpoch(start,stop)
%{
    Alessandro: 
        re-epoch merged files to 5min epochs with an "artifact index" which computes the amount of artifacts in the epochs.
%}

%COMPUTE_ARTIFACT_INDICIES;
addpath(genpath('/nobackup1b/users/ghassemi/Analysis'));
addpath(genpath('/nobackup1b/users/ghassemi/EEGs'));
rmpath('/nobackup1b/users/ghassemi/Analysis/sccn_eeglab-eeglab-b5c3b5316735/functions/octavefunc/signal');
rmpath('/nobackup1b/users/ghassemi/Analysis/eeglab/functions/octavefunc/signal');

%load vars skews kurts fband_0_2 fband_20_40; 

cd('/nobackup1b/users/ghassemi/EEGs/CA_Merged')
search_me = '/nobackup1b/users/ghassemi/EEGs/CA_Merged'

file_list = getAllFiles([search_me]);
file_list = getSubsetWithKeywords(file_list,{'dEEG_'},[]);

Fs = 100;
%% RE_EPOCH
new_epoch_size_sample = Fs*60*5;  % Re-epoch to 5min.
for i=start:stop %1:length(file_list)
    clear clean dirty new_dirt new_data
    %load the file
    load(file_list{i})
    numchannels = size(EEG.data,1);
    
    %Find clean signal.
    try
        dirty =  (rejeye | rejmusc | rejzeros | rejkurt | rejvariance | rejskew);
        clean = ~(dirty);
    catch
        dirty =  (rejeye | rejmusc | rejzeros | rejvariance | rejskew);
        clean = ~(dirty);    
    end
    clear rej*
    
    %get the old epoch_size, and the new/old ratio
    old_epoch_size = size(EEG.data,2);
    new_old_ratio = new_epoch_size_sample/old_epoch_size;
    
    %initialize the new data matrix.
    new_data = zeros(numchannels,new_epoch_size_sample,floor(size(EEG.data,3)/new_old_ratio));
    ind = 1;
    for k = 1:new_old_ratio:size(clean,2)-new_old_ratio
        new_dirt(:,ind) = sum(dirty(:,k:k+new_old_ratio-1)')/new_old_ratio;
        new_data(:,:,ind) = reshape(EEG.data(:,:,k:k+new_old_ratio-1),numchannels,new_epoch_size_sample);
        ind = ind+1;
    end
    
    EEG.data = new_data;
    EEG.trials = size(new_data,3);
    EEG.pnts = size(new_data,2);
    EEG.times = 0:10:(10*EEG.pnts-10);
    EEG.dirty = new_dirt;
    
    
%     slash_index = max(find(file_list{i} == '/'));            %find the index of the last slash
%     last_numeric_index = max(find(file_list{i} == '-'...
%         | file_list{i} == '_'));
%     name = file_list{i}(slash_index+2:last_numeric_index);   %grab the name of the file.
%     s_number = [' ' name(3:end-1) ' '];
%     
%     %Change to The right directory...
%     cd(file_list{i}(1:slash_index-1));
    cd('/nobackup1b/users/ghassemi/EEGs/CA_Merged/epoched_5mins')
    save(['EEG_5MIN_' EEG.SID '.mat'], 'EEG','-v7.3')
end



end

