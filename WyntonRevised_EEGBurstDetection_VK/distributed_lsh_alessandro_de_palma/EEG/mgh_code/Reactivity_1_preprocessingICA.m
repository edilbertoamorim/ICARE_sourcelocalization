%%  Reactivity: preprocessing & ICA
% Reads EEG, makes it into a bipolar longitudinal montage and performs
% Independent component analysis (ICA) and high/low pass filters to
% reduce the effects of artifacts (i.e. ECG, drift)

% EEG that is generated includes a two minute epoch, starting one minute
% before onset of reactivity testing

% Mathilde Hermans, 2015

%% Set directories
clear all; close all; clc
% datadir='C:\Users\Mathilde\Desktop\Reactivity\Data';
% filedir = [datadir,'\Test cases\'];
%scriptdir='C:\Users\Mathilde\Desktop\Reactivity\Scripts';
%functiondir='C:\Users\Mathilde\Desktop\Reactivity\Functions';
%savedir='C:\Users\Mathilde\Desktop\Reactivity\Results';

datadir='C:\Users\mw110\Dropbox (SAH MONITORING)\Papers_InProgress\Reactivity_Nick_Michel_Brandon\Reactivity\Data';
filedir = 'C:\Users\mw110\Dropbox (SAH MONITORING)\Papers_InProgress\Reactivity_Nick_Michel_Brandon\Reactivity\Data\Test cases';
scriptdir = 'C:\Users\mw110\Dropbox (SAH MONITORING)\Papers_InProgress\Reactivity_Nick_Michel_Brandon\Reactivity\Scripts';
functiondir = 'C:\Users\mw110\Dropbox (SAH MONITORING)\Papers_InProgress\Reactivity_Nick_Michel_Brandon\Reactivity\Functions';
savedir = 'C:\Users\mw110\Dropbox (SAH MONITORING)\Papers_InProgress\Reactivity_Nick_Michel_Brandon\Reactivity\ResultsEdMbw';
cd(scriptdir)
addpath (genpath(functiondir),genpath(datadir),scriptdir, savedir)

% load data
Stimtimefile=xlsread('Stimtimes'); % read time of stimulation
FileList = dir(filedir);
FileList (1:2)=[];

%% Run all parameters
close all

L=length(FileList); 

% Create empty matrixes to allow saving epochs with different fs
EEG_BP_ecgfilt=zeros(L,18,120*512);    % L files, 18 channels, 120 seconds * maximal sample frequency) 
EEG_BP_raw=zeros(L,18,120*512);
EEG_BP_raw=zeros(L,18,120*512);
EEG_BP_butterfilt=zeros(L,18,120*512);
EEG_BP_butterfilt=zeros(L,18,120*512);
EEG_BP_fullfilt=zeros(L,18,120*512);
ECG=zeros(L,120*512);
ICAecg_comp=zeros(L,2);
ICAcomponents=zeros(L,19,124*512);
ICAmatrix=zeros(L,19,18);
ICAkurtosis_comp=zeros(L,18);
nrcomp=ones(L,1);

for file=1:L;
    
    clear eegraw eeg Spect AVmontage BPmontage ecg
    name = FileList(file).name;
    filename = strcat(filedir,'\',name);
    [Header] =  ReadEDF001(filename);
 
    %%%%%%%%%% Find channel targets %%%%%%%%
    Channels1 = {'Fp1','F7','T7','P7','O1','F3','C3','P3','Fz','Cz','Pz','Fp2','F8','T8','P8','O2','F4','C4','P4'};
    for ch = 1:length(Channels1); for lbl = 1:length(Header.label); q1(ch,lbl)=isempty(regexp(Channels1{ch},Header.label{lbl}));  end; end;
    
    Channels2 = {'Fp1','F7','T3','T5','O1','F3','C3','P3','Fz','Cz','Pz','Fp2','F8','T4','T6','O2','F4','C4','P4'};
    for ch = 1:length(Channels2); for lbl = 1:length(Header.label);  q2(ch,lbl)=isempty(regexp(Channels2{ch},Header.label{lbl})); end ;  end;
    
    Channels3 = {'EEG Fp1-Ref1','EEG F7-Ref1','EEG T3-Ref1','EEG T5-Ref1','EEG O1-Ref1','EEG F3-Ref1','EEG C3-Ref1','EEG P3-Ref1','EEG Fz-Ref1','EEG Cz-Ref1','EEG Pz-Ref1','EEG Fp2-Ref1','EEG F8-Ref1','EEG T4-Ref1','EEG T6-Ref1','EEG O2-Ref1','EEG F4-Ref1','EEG C4-Ref1','EEG P4-Ref1'};
    for ch = 1:length(Channels3);  for lbl = 1:length(Header.label);  q3(ch,lbl)=isempty(regexp(Channels3{ch},Header.label{lbl}));  end;   end;
    
    if max(mean(q1(:,:),2))<1;
        Channels=Channels1;
    elseif max(mean(q2(:,:),2))<1;
        Channels=Channels2;
    elseif max(mean(q3(:,:),2))<1;
        Channels=Channels3;
    else
        disp('ERROR: no channels')
    end
    
    % Read channel position
    for ch = 1:length(Channels)
        for lbl = 1:length(Header.label)
            match = regexp(Channels{ch},Header.label{lbl});
            if isempty (match) == 0;
                loc (lbl) = 1;
            else
                loc (lbl) = 0;
            end
        end
        if sum (loc) >0;
            Target(ch) = find(loc==1);
        else
            for lbl = 1:length(Header.label)
                match = regexp(Channels_Biologic{ch},Header.label{lbl});
                if isempty (match) == 0;
                    loc (lbl) = 1;
                else
                    loc (lbl) = 0;
                end
            end
            Target(ch) = find(loc==1);
        end
    end
    
    % Find ECG target
    ECGchannels= {'ECGL' ,'EKG1', 'ECG1' ,'EEG A1-Ref1 ' ,'In1-Ref2','EEG A1-Ref1','ECG'};
    for j=1:7;
        for lbl = 1:length(Header.label);
            ECGch(lbl,j)=isempty(regexp(ECGchannels{j},Header.label{lbl}));
            if ECGch(lbl,j)==0;
                if length(Header.label{lbl})==length(ECGchannels{j});
                else
                    ECGch(lbl,j)=1;
                end
            end
        end
    end
    ECGtarget=find(min(ECGch(:,1:7)')==0);
    clear ECGchannels ECGch
    
    
%     %% %%%%%%%% Define epochs %%%%%%%%%%%
%     Fs(file)=Header.Fs;     fs = Fs(file);
%     duration = Header.nSamples*Header.nTrials;
%     Stimtime(file) = Stimtimefile(file,6); stimtime=Stimtime(file);
%   
%     % Epoch selection
%     lsignal=120;   % length signal (s)
%     lepoch=60;   %  length epochs (s)
%     
%     onset = stimtime-lepoch*fs+1;
%     offset = stimtime+lepoch*fs;
%     
%     % First select a bit longer frame to prevent filter artifacts due to
%     % cutting frame edges 
%     extra=0%;   % set to 0
%     onsetlong=onset-extra;
%     offsetlong=offset+extra;
%     
%     if onsetlong>0 && offsetlong<duration
%         Shortrecording(file)=0;   % Recording is long enough
        %% %%%%%%%%  Read EEG   %%%%%%%%
        [eegraw] = ReadEDF001(filename,Header,onsetlong,offsetlong,Target);
        [ecg] = ReadEDF001(filename,Header,onsetlong,offsetlong,ECGtarget);
        
        % Create average montage
        AVmontage=eegraw - repmat(mean(eegraw,1),size(eegraw,1),1);
        AVchnames=Channels1;
        
        % Create bipolar montage
        BPtargets=[1 2; 2 3 ; 3 4 ; 4 5; 1 6 ; 6 7 ; 7 8 ; 8 5; 9 10; 10 11; 12 17; 17 18; 18 19; 19 16; 12 13 ; 13 14; 14 15; 15 16];
        for ch=1:length(BPtargets)
            BPmontage(ch,:)=eegraw(BPtargets(ch,1),:)-eegraw(BPtargets(ch,2),:);
            BPchnames{ch}=[Channels1{BPtargets(ch,1)},'-',Channels{BPtargets(ch,2)}];
        end
        
        eegmontage=BPmontage;
        clear Channels1 Channels2 Channels3 ch lbl match loc
        
        %% %%%%% Remove ECG artifact %%%%%%%
        clear icamatrix icasig A k filtEEGpart  sidematrix EEGartfilt j K comporder artreject EEG eegfilt eegfilt2 eeg_ecgfilt; clc
        
        % Find components
        [icasig, icamatrix, ~] = fastica([eegmontage; ecg]);
        ICAn(file)=length(icasig(:,1));
        
        ICAcomponents(file,1:ICAn(file),1:Fs(file)*120)=icasig;
        ICAmatrix(file,1:19,1:ICAn(file))=icamatrix;
        
        if length(icasig(:,1))>1
            % Remove ECG component
            ICAecg_comp(file,1)=find(abs(icamatrix(19,:))==max(abs(icamatrix(19,:))));
            sidematrix=icamatrix;
            sidematrix(1:19,ICAecg_comp(file,1))=zeros(19,1);
           
            kurtosisremoval=0;
            for j = 1:length(icasig(:,1));
                % Remove components with Kurtosis > 15
                k = kurtosis(icasig(j,:),[],2);
             
                if k > 15
                    icasig(j,:) = 0;
                    kurtosisremoval=kurtosisremoval+1;
                    ICAkurtosis_comp(file,j)=k;
                  
                else
                    ICAkurtosis_comp(file,j)=0;
                end
            end

            % Plot ICA output
            for n=1:17
                if      length(find(n== ICAecg_comp(file,:)))>0 ;
                    Color(n)='b'  % Component with strongest relation with ECG
                elseif  ICAkurtosis_comp(file,n)>1 ;
                    Color(n)='r'  % Component with high kurtosis
                else
                    Color(n)='g' ;% Accepted components
                end
            end
            clear time J
            time=1/Fs(file):1/Fs(file):120;
            
            A=figure()
            for n=1:9
                subplot(9,1,n)
                J(1:120*Fs(file))=ICAcomponents(file,n,1:120*Fs(file));
                plot(time,J,Color(n))
                ylabel(num2str(n),'fontsize',16);
                if n==1;   title(['ICA components case: ',num2str(file),' (part I)'],'fontsize',16); end
                if n<9;         set(gca,'xticklabel',{[]});        end
            end

            B=figure()
            for n=10:ICAn(file)
                subplot(9,1,n-9)
                J(1:120*Fs(file))=ICAcomponents(file,n,1:120*Fs(file));
                plot(time,J,Color(n))
                ylabel(num2str(n),'fontsize',16);
                if n<ICAn(file);    set(gca,'xticklabel',{[]});        end
                if n==10; title(['ICA components case: ',num2str(file),' (part II)'],'fontsize',16); end
            end
            
            % Manual check is components are selected in the correct way
            prompt = 'Is ECG component selected correctly (1/0)?';
            result1 = input(prompt)
            if result1==1
               icamatrix=sidematrix;
            else
                prompt = 'What is/are correct component(s)?';
                result2 = input(prompt);
                ICAecg_comp(file,:)=NaN;
                for k=1:length(result2)
                    icamatrix(1:19,result2(k))=zeros(19,1)
                    ICAecg_comp(file,k)=result2(k);
                end
            end
            icamatrix=sidematrix;
            
            % Reconstruct signal
            filtEEGpart = icamatrix*icasig;
            eeg_ecgfilt(:,:)= filtEEGpart(1:18,:);
        else   % If no ECG is found
            eeg_ecgfilt(:,:)=eegmontage;
        end
        
        clear filtEEGpart ecg_comp freq1 freq50 Tpost Tpre T
        
        ECG(file,1:120*fs)=ecg(1:120*fs);
        EEG_BP_ecgfilt(file,1:18,1:120*fs)=eeg_ecgfilt(1:18,1:120*fs);
        EEG_BP_raw(file,1:18,1:120*fs)=eegmontage(1:18,1:120*fs);
        EEG_raw(file,1:19,1:120*fs)=eegraw(1:19,1:120*fs);
        
        
        %% %%%%% Some filtering %%%%%%%
        clear eegfilt eegfilt_or eegfilt2 eegfilt2_or
        
        for ch=1:18
            % Remove high frequency noise
            fcut=18;  nfc=2/fs*fcut;
            [B1,A1]=butter(16,nfc,'low');
            eegfilt(ch,:)=filtfilt(B1,A1,eeg_ecgfilt(ch,:));
            eegfilt_or(ch,:)=filtfilt(B1,A1,eegmontage(ch,:));
            
            % Remove drift
            fcut=0.5;  nfc=2/fs*fcut;
            [B2,A2]=butter(4,nfc,'high'); 
            eegfilt2(ch,:)=filtfilt(B2,A2,eegfilt(ch,:));
            eegfilt2_or(ch,:)=filtfilt(B2,A2,eegfilt_or(ch,:));
            
            % Build EEG
            EEG_BP_fullfilt(file,ch,1:120*fs)= eegfilt2(ch,1:length(eegfilt2));   % EEG filtered with ICA + highpass + lowpass filter
            EEG_BP_butterfilt(file,ch,1:120*fs)=eegfilt2_or(ch,1:length(eegfilt2)); % EEG filtered with highpass + lowpass filter
        end

    else
        Shortrecording(file)=1; % If epoch < 2 minutes
    end
   
end

% Struct data
FILEdata=struct('BPchnames',BPchnames,'Fs',Fs,'Shortrecording',Shortrecording,'Stimtime',Stimtime)
EEGdata1=struct('EEG_BP_fullfilt',EEG_BP_fullfilt,'EEG_raw',EEG_raw)
EEGdata2=struct('EEG_BP_ecgfilt',EEG_BP_ecgfilt,'EEG_BP_raw',EEG_BP_raw,'EEG_BP_butterfilt',EEG_BP_butterfilt,'ECG',ECG);
ICAdata=struct('ICAcomponents',ICAcomponents,'ICAn',ICAn,'ICAmatrix',ICAmatrix,'ICAkurtosis_comp',ICAkurtosis_comp,'ICAecg_comp',ICAecg_comp);

% Clear remaining data
clearvars -except FILEdata EEGdata1 EEGdata2 ICAdata savedir 

%% Save data
save([savedir,'\EEGdata1'],'EEGdata1','-v7.3');
save([savedir,'\EEGdata2'],'EEGdata2','-v7.3');
save([savedir,'\FILEdata'],'FILEdata','-v7.3');
save([savedir,'\ICAdata'],'ICAdata','-v7.3');
