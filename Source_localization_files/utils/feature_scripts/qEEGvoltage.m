function voltage = qEEGvoltage(eeg, less_than_voltage)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

eeg_chan = struct('channel',[], 'feat', [],'org_set', []);
channels = size(eeg,1);
%loop through channels
for j=1:channels
    x = eeg(j,:);
    
    v = mean(abs(x) < less_than_voltage);
   
    
    eeg_chan(j).feat = v;
    eeg_chan(j).channel = j;
    %eeg_chan(j).org_set = tmp_EEG.setname;
    
end    
voltage = mean([eeg_chan.feat]);



    
function voltage = qEEGvoltage(eeg, less_than_voltage)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

eeg_chan = struct('channel',[], 'feat', [],'org_set', []);
channels = size(eeg,1);
%loop through channels
for j=1:channels
    x = eeg(j,:);
    
    v = mean(abs(x) < less_than_voltage);
   
    
    eeg_chan(j).feat = v;
    eeg_chan(j).channel = j;
    %eeg_chan(j).org_set = tmp_EEG.setname;
    
end    
voltage = mean([eeg_chan.feat]);



    