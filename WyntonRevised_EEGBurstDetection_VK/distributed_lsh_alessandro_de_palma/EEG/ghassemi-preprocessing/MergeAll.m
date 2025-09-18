%%MERGE ALL DATA.
function []=MergeAll(start,stop)

addpath(genpath('/nobackup1b/users/ghassemi/Analysis'))
addpath(genpath('/nobackup1b/users/ghassemi/EEGs'))
rmpath(genpath('/nobackup1b/users/ghassemi/Analysis/sccn_eeglab-eeglab-b5c3b5316735/'))
rmpath(genpath('/nobackup1b/users/ghassemi/Analysis/eeglab/'))
%rmpath('/home/mohammad/Documents/MGH PROJECT/Analysis/eeglab/functions/octavefunc/signal');
%rmpath('/home/mohammad/Documents/MGH PROJECT/Analysis/sccn_eeglab-eeglab-b5c3b5316735/functions/octavefunc/signal');

%Get all the subject IDS
load bwh_sids; load mgh_sids; load uTwente_sids; load yale_sids; load mgh_sids2; load bidmc_sids;
sids = [bwh_sids;mgh_sids;uTwente_sids;yale_sids; mgh_sids2; bidmc_sids];
sids = bidmc_sids;
%these are the only channels we are going to keep - all others will be tossed.
master_channels = {'Fp1','Fp2','F7','F8','T3','T4','T5','T6','O1','O2','F3','F4','C3','C4','P3','P4','Fz','Cz','Pz'};

%FINAL FREQUENCY
Fs = 100;
cut_off = Fs*60*60*72;

%THIS IS FOR ERROR DEBUGGING...
%  id_with_error = 'EEGIC133';
%  these=find(~cellfun(@isempty,strfind(sids,id_with_error)))
%  start = these(1)
%  stop = these(1)

%% MERGE... ONE SUBJECT AT A TIME.
for i = start:stop%1:length(sids)
    %CREATE A TEXT FILE WITH THE OUTPUT... IN CASE OF FAILURES...
    diary on
    diary([sids{i} '.txt'])
    
    %Look through all EEGs for the subset of files describing this subject
    search_me = '/nobackup1b/users/ghassemi/EEGs'
    these_files = getAllFiles([search_me]);
    these_files = getSubsetWithKeywords(these_files,{'.mat','h_',sids{i}},{'all'});
    
    %get the merged file
    search_me = '/nobackup1b/users/ghassemi/Analysis'
    master_file = getAllFiles([search_me]);
    master_file = getSubsetWithKeywords(master_file,{'all','d_',sids{i}},{});
    
    %This makes sure we only work on the files that were not already
    %processed.
    try
        m_ptm = matfile(master_file{1})
        m_ptm.SID
    catch
        %get the start and end times from each file header.
        name = sids{i};
        clear headers starts ends start_times Fss
        for j = 1:length(these_files)
            ptm=matfile(these_files{j},'Writable',true);
            headers{j} = ptm.header;
            starts(j) = headers{j}.start_serial;
            ends(j) =  headers{j}.end_serial;
            Fss(j) = headers{j}.sampling_rate;
            start_times{j} = headers{j}.start;
        end
        
        %NORMALIZE
        reduce= min(starts);
        starts = starts - reduce + 1.1574e-05;
        ends = ends - reduce + 1.1574e-05;
        
        %GET STARTING AND ENDING SAMPLES
        start_samp = Fs*etime(datevec(starts),repmat([0 0 0 0 0 1],length(ends),1)) + 1;
        end_samp = Fs*etime(datevec(ends),repmat([0 0 0 0 0 1],length(ends),1)) + 1;
        
        %REMOVE STUFF AFTER 72 HOURS
        remove_these = start_samp > cut_off;
        
        start_samp(remove_these) = [];
        end_samp(remove_these) = [];
        headers(remove_these) = [];
        starts(remove_these) = [];
        ends(remove_these) = [];
        Fss(remove_these) = [];
        start_times(remove_these) = [];
        these_files(remove_these) = [];
        
        reassign_me = end_samp > cut_off;
        end_samp(reassign_me) = cut_off;
        
        %CREATE A POINTER TO THE LOCATION ON THE DISK
        empty = []; save(['d_' name '_all.mat'],'empty','-v7.3');
        PointToMat=matfile(['d_' name '_all.mat'],'Writable',true);
        
        %INITIALIZE THE DATA TO ALL NANs
        total_data_size = max(end_samp);
        PointToMat.data = nan(length(master_channels),total_data_size);
        
        %NOW TAKE THE CORRESPONDING DATA FILES, AND MERGE THEM.
        these_files = strrep(these_files,'/h_','/d_');
        for j = 1:length(these_files)
            ptm=matfile(these_files{j},'Writable',true);
            
            %RESAMPLE THE DATA TO 100/SEC
            data = resample(double(ptm.data'),Fs,Fss(j));
            data = data';
            
            %MAP FROM SLAVE TO MASTER.
            s_to_m = map_channels(headers{j}.label);
            %Get the total number of channels.
            num_chans = size(headers{j}.label,2);
            
            %For each of the channels
            for k = 1:num_chans
                %If there is a corresponding value of the slave file in the master.
                if(~isnan(s_to_m(k)))
                    if( size(data,2) < end_samp(j)-start_samp(j))
                        PointToMat.data(s_to_m(k),start_samp(j):(start_samp(j) + size(data,2)-1)) = data(k,:);
                    else
                        PointToMat.data(s_to_m(k),start_samp(j):end_samp(j)-1) = data(k,1:(end_samp(j)-start_samp(j)));
                    end
                end
            end
        end
        
        %NEXT, LOAD THE POPULATION DATA
        PointToMat.SID = name;
        PointToMat.channels = master_channels;
        PointToMat.Fs = Fs;
        PointToMat.starttime = start_times{starts == min(starts)};
    end
end


end

