function signalstd = qEEGstd (eeg);
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

eeg_chan = struct('channel',[], 'feat', [],'org_set', []);

channels = size(eeg,1);

%loop through channels
for j=1:channels
    x = eeg(j,:);
    
    sstd = std(x);

    
    eeg_chan(j).feat = sstd;
    eeg_chan(j).channel = j;
    %eeg_chan(j).org_set = tmp_EEG.setname;

end

%
signalstd = mean([eeg_chan.feat]);
end
function signalstd = qEEGstd (eeg);
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

eeg_chan = struct('channel',[], 'feat', [],'org_set', []);

channels = size(eeg,1);

%loop through channels
for j=1:channels
    x = eeg(j,:);
    
    sstd = std(x);

    
    eeg_chan(j).feat = sstd;
    eeg_chan(j).channel = j;
    %eeg_chan(j).org_set = tmp_EEG.setname;

end

%
signalstd = mean([eeg_chan.feat]);
end