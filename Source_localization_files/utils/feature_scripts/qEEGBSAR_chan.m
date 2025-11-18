function [BSAR]=qEEGBSAR(eeg, fs) %(samples x ch)
    %EEG = tmp_EEG.data';
    EEG = eeg';
    
    % I. Settings
    cutoff_value=10;        % Maximum amplitude of "suppression" (microvolts)
    min_supp_duration=0.5;  % Minimum duration of "suppression" (seconds)
    mininterval=0.2;        % Minimum duration of "bursts" (seconds)
    bsar_lim=[0.01 0.99];   % Upper and lower bounds of BCI for which BSAR is calculated 
    minchan = 19;
    
    if minchan == 19
       
        % 3. Detect suppressions 
        EEG_supp=zeros(size(EEG));   
        
        % a. make binary matrix
        EEG_bin=abs(EEG)<(cutoff_value/2);
        
        for channel=1:size(EEG,2)

            % b. only keep "suppressions" with minimum duration 
            signal=[0 EEG_bin(:,channel)' 0];
            ii1=strfind(signal,[0 1]);
            ii2=strfind(signal,[1 0])-1;
            ii=(ii2-ii1+1)>=round(min_supp_duration*fs);
            ii1=ii1(ii);
            ii2=ii2(ii);
            for idx=1:length(ii1)
                EEG_supp(ii1(idx):ii2(idx),channel)=1;
            end

            % c. remove "bursts" shorter than minimum duration
            signal=[1 EEG_supp(:,channel)' 1];
            ii1=strfind(signal,[1 0]);
            ii2=strfind(signal,[0 1])-1;
            ii=(ii2-ii1+1)<round(mininterval*fs);
            ii1=ii1(ii);
            ii2=ii2(ii);
            for idx=1:length(ii1)
                EEG_supp(ii1(idx):ii2(idx),channel)=1;
            end        

        end

        % 4. remove edges of EEG (filtering/windowing effects)
        EEG=EEG(fs+1:end-fs,:); 
        EEG_supp=EEG_supp(fs+1:end-fs,:); 

        % 5. calculate qEEG parameters (per channel)
        BCI_chan=nan(1,size(EEG,2));
        BSAR_chan=nan(1,size(EEG,2));
        
        for channel=1:size(EEG,2)
            
            % a. calculate BCI
            BCI_chan(channel)=1-mean(EEG_supp(:,channel)); 

            % b. calculate BSAR
            if BCI_chan(channel)>=bsar_lim(1) && BCI_chan(channel)<=bsar_lim(2)
                powburst=std(EEG(~logical(EEG_supp(:,channel)),channel));
                powsupp=std(EEG(logical(EEG_supp(:,channel)),channel));
                BSAR_chan(channel)=powburst/powsupp;   
            else
                BSAR_chan(channel)=1;
            end       
        end  

        % 6. calculate and save final results
        %BCI=mean(BCI_chan);
        BSAR=BSAR_chan; %removed mean

    else
        %BCI=nan;   
        BSAR(1,1:minchan)=deal(nan);
    end
    
end