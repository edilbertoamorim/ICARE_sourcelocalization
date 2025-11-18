function entropy = qEEGShannonEntropy(eeg, bin_min, bin_max, binWidth)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

eeg_chan = struct('channel',[], 'feat', [],'org_set', []);

channels = size(eeg,1);

    
%loop through channels
for j=1:channels
    
    x = eeg(j,:);
    
    [counts,binCenters] = hist(x,[bin_min:binWidth:bin_max]);
    binWidth = diff(binCenters);
    binWidth = [binWidth(end),binWidth]; % Replicate last bin width for first, which is indeterminate.
    nz = counts>0; % Index to non-zero bins
    prob = counts(nz)/sum(counts(nz));
    H = -sum(prob.*log2(prob./binWidth(nz)));
    
    eeg_chan(j).feat = H;
    eeg_chan(j).channel = j;
    %eeg_chan(j).org_set = tmp_EEG.setname;

end

%
entropy = mean([eeg_chan.feat]);
end
