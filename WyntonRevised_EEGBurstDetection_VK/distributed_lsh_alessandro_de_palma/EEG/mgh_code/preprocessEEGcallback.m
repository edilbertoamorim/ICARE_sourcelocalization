function [data_raw, data_clean, channels_left] =  preprocessEEGcallback(data,channels,Fs)
Fs = round(Fs);

%%%% Step 1: Channel selection %%%%
ChannelList = lower({'Fp1';'F3';'C3';'P3';'F7';'T1';'T3';'T5';'O1';...  9
                     'Fz';'Cz';'Pz';'Fpz';...                           4
                     'Fp2';'F4';'C4';'P4';'F8';'T2';'T4';'T6';'O2';...  9
                     'EKG';'ECG';...                                    3
                     'C.ii'});    

channels3 = channels(:,1:3); 

iCh = [];
for i = 1:length(ChannelList)
    if i == 1      % F1 or Fp1
        ii = [find(ismember(lower(channels),'f1', 'rows')==1);...
              find(ismember(lower(channels),'fp1','rows')==1)];        

    elseif i == 14 % F2 or Fp2
        ii = [find(ismember(lower(channels),'f2', 'rows')==1);...
              find(ismember(lower(channels),'fp2','rows')==1)];
          
    elseif i == 23 || i == 24 % EKG or ECG
        ii = find(ismember(lower(channels3),ChannelList{i},'rows')==1);
 
    elseif i == 25 % Cii
        ii = [find(ismember(lower(channels),'c.ii','rows')==1);...
              find(ismember(lower(channels),'cii' ,'rows')==1);...
              find(ismember(lower(channels),'c2'  ,'rows')==1)];
    else
        
        ii = find(ismember(lower(channels),ChannelList{i},'rows')==1);
    end
    
    iCh = [iCh;ii];
end

data_raw = data(iCh,:);
channels_left = channels(iCh,:);

%%%% Step 2. Filters + downsample %%%% 
wn = 60/(0.5*Fs); wh = 1/(0.5*Fs);
[Bn,An] = iirnotch(wn,wn/35); [Bh,Ah] = butter(3, wh, 'high');

fs = 128;

data_clean = [];
for i = 1:size(data_raw,1)
    
    x = data_raw(i,:);
    x = filter(Bn, An, x);           % 60Hz notch
    x = filter(Bh, Ah, x);           % HPF
    x = resample(x,fs,Fs);           % downsample to "128Hz"

    data_clean = [data_clean; x];   
end

