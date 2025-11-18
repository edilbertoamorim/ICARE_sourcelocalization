function siq_out = qEEGSIQ(eeg, bin_min, bin_max, binWidth, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here 

eeg_chan = struct('channel',[], 'feat', [],'org_set', []);
channels = size(eeg,1);
% %return only only band
% band='SIQ';
% if nargin > 4
%     band = varargin{1};
% end
    
%loop through channels
for j=1:channels
    x = eeg(j,:);
    
    waveletFunction = 'db8';
    [C,L] = wavedec(x,5,waveletFunction);

    % Calculation The Coificients Vectors
    cGamma = detcoef(C,L,1); %GAMMA 50
    cBeta = detcoef(C,L,2);  %BETA 25
    cAlpha = detcoef(C,L,3); %ALPHA 12.5
    cTheta = detcoef(C,L,4); %THETA 6.25
    cDelta = detcoef(C,L,5); %DELTA  3.125

    %Step 3:Compute the entropy of each of the sub-bands.
    [sbe(1)] = qEEGShannonEntropy(cGamma, bin_min, bin_max, binWidth);
    [sbe(2)] = qEEGShannonEntropy(cBeta, bin_min, bin_max, binWidth);
    [sbe(3)] = qEEGShannonEntropy(cAlpha, bin_min, bin_max, binWidth);
    [sbe(4)] = qEEGShannonEntropy(cTheta, bin_min, bin_max, binWidth);
    [sbe(5)] = qEEGShannonEntropy(cDelta, bin_min, bin_max, binWidth);

    eeg_chan(j).gamma = sbe(1);
    eeg_chan(j).beta = sbe(2);
    eeg_chan(j).alpha = sbe(3);
    eeg_chan(j).theta = sbe(4);
    eeg_chan(j).delta = sbe(5);
    
    % eeg_chan(j).channel = j;
    %eeg_chan(j).org_set = tmp_EEG.setname;

end
    % gamma = mean([eeg_chan.gamma]);
    % beta = mean([eeg_chan.beta]);
    % alpha = mean([eeg_chan.alpha]);
    % theta = mean([eeg_chan.theta]);
    % delta = mean([eeg_chan.delta]);
    % 
    % SIQ = mean([gamma beta alpha theta delta]);
    % 
    % siq_out = eval(band);

    % updated to return all bands
    siq_out = eeg_chan;
end
