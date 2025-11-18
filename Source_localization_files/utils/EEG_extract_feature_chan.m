function feature_eeg = EEG_extract_feature_chan(tmp_EEG, feature_resolution)
eeg_features = struct('org_set', []);

Fs = tmp_EEG.srate;
nbchan = tmp_EEG.nbchan;
eeg_features.org_set = tmp_EEG.setname; % create struct for features

n = 1;
start_idx =1;
end_idx = start_idx + feature_resolution*Fs - 1;  % using defined time resolution

fprintf('in features script\r\n')
while true 
    if end_idx > tmp_EEG.pnts
        break
    end
    eeg = tmp_EEG.data(:,start_idx:end_idx);
    
    %% FEATURE ADDED BY MAHSA
    % standard deviation of signal
    eeg_features.SignalSD(1:nbchan,n) = std(eeg')';
    fprintf('SEGMENT#%03d: generated first feature',n)
    
    % low voltage 5, 10, 20
    eeg_features.lv_l5(1:nbchan,n) = mean(abs(eeg) < 5,2);
    eeg_features.lv_l10(1:nbchan,n) = mean(abs(eeg) < 10,2);
    eeg_features.lv_l20(1:nbchan,n) = mean(abs(eeg) < 20,2);
    
    % SIQ
    bin_min = -200; bin_max = 200; binWidth = 2;
    %% needs work
    % existing script means all arrays to get one value, need to define new
    % way to do SIQ overall
    % eeg_features.SIQ(n) = qEEGSIQ(eeg, bin_min, bin_max, binWidth);
    %%
    siq_all = qEEGSIQ_chan(eeg, bin_min, bin_max, binWidth);
    eeg_features.SIQ_delta(1:nbchan,n) = [siq_all.delta]';
    eeg_features.SIQ_theta(1:nbchan,n) = [siq_all.theta]';
    eeg_features.SIQ_alpha(1:nbchan,n) = [siq_all.alpha]';
    eeg_features.SIQ_beta(1:nbchan,n) = [siq_all.beta]';
    % eeg_features.SIQ_delta(n) = qEEGSIQ(eeg, bin_min, bin_max, binWidth, 'delta');
    % eeg_features.SIQ_theta(n) = qEEGSIQ(eeg, bin_min, bin_max, binWidth, 'theta');
    % eeg_features.SIQ_alpha(n) = qEEGSIQ(eeg, bin_min, bin_max, binWidth, 'alpha');
    % eeg_features.SIQ_beta(n) = qEEGSIQ(eeg, bin_min, bin_max, binWidth, 'beta');
    
    % BCI
    eeg_features.BCI(1:nbchan,n) = qEEGBCI_chan(eeg, Fs)';

    % Burst Suppression Amplitude ratio
    eeg_features.BSAR(1:nbchan,n) = qEEGBSAR_chan(eeg, Fs)';
    fprintf('...all MAHSA features')
    
    %% FEATURE ADDED BY VISHNU / EDDY
    % Algo 3 0st derivative global features (Kaggle)
    %Max of channel max amplitudes (abs val amp)
    eeg_features.d0MaxAmp(1:nbchan,n) = max(abs(eeg'))';
    

    %% modified
    %cannot get following per channel
    
    %Mean of channel max amplitudes (abs val amp)
    % eeg_features.d0MeanMaxAmp(n) = mean(max(abs(eeg')));
    % replaced with
    eeg_features.d0MeanAmp(1:nbchan,n) = mean(abs(eeg'))';
    
    %Var of channel max ampltidues (abs val amp)
    % eeg_features.d0VarMaxAmp(n) = var(max(abs(eeg')));
    % replaced with
    eeg_features.d0VarAmp(1:nbchan,n) = var(abs(eeg'))';

    %Var of mean channel amplitude (abs val amp)
    % eeg_features.d0VarMeanAmp(n) = var(mean(abs(eeg')));
    eeg_features.d0VarAmp;
    eeg_features.d0MeanAmp;

    %Var of individual channel var in amplitude 
    % eeg_features.d0VarVarAmp(n) = var(var(abs(eeg')));
    % replaced with 
    eeg_features.d0VarAmp;

    %Mean of individual channel var in ampltiude
    % eeg_features.d0MeanVarAmp(n) = mean(var(abs(eeg')));
    % replaced with
    eeg_features.d0MeanAmp;
    eeg_features.d0VarAmp;

    %Max of maxes of channel fourier ampltiudes
    % eeg_features.d0MaxMaxFourAmp(n) = max(max(abs(fft(eeg'))));
    % replaced with
    eeg_features.d0MaxFourAmp(1:nbchan,n) = max(abs(fft(eeg')))';

    %Mean of maxes of channel fourier ampltiudes
    % eeg_features.d0MeanMaxFourAmp(n) = mean(max(abs(fft(eeg'))));
    % replaced with
    eeg_features.d0MeanFourAmp(1:nbchan,n) = mean(abs(fft(eeg')),1)';

    %Var of maxes of channel fourier ampltiudes
    % eeg_features.d0VarMaxFourAmp(n) = var(max(abs(fft(eeg'))));
    % replaced with 
    eeg_features.d0VarFourAmp(1:nbchan,n) = var(abs(fft(eeg')))';
    %
    

    % Algo 3 1st derivative global features (Kaggle)
    deriv1 = diff(eeg');
    %Max of channel max amplitudes 
    eeg_features.d1MaxAmp(1:nbchan,n) = max(abs(deriv1))';


    %% modified
    % cannot get following per channel
    
    %Mean of channel max amplitudes
    % eeg_features.d1MeanMaxAmp(n) = mean(max(abs(deriv1)));
    % replaced with
    eeg_features.d1MeanAmp(1:nbchan,n) = mean(abs(deriv1))';
    
    %Var of channel max ampltidues 
    % eeg_features.d1VarMaxAmp(n) = var(max(abs(deriv1)));
    % replaced with
    eeg_features.d1VarAmp(1:nbchan,n) = var(abs(deriv1))';
    
    %Var of mean channel amplitude 
    % eeg_features.d1VarMeanAmp(n) = var(mean(abs(deriv1)));
    % replaced with
    eeg_features.d1VarAmp;
    eeg_features.d1MeanAmp;
    
    %Var of individual channel var in amplitude 
    % eeg_features.d1VarVarAmp(n) = var(var(abs(deriv1)));
    % replaced with
    eeg_features.d1VarAmp;
    
    %Mean of individual channel var in ampltiude 
    % eeg_features.d1MeanVarAmp(n) = mean(var(abs(deriv1)));
    % replaced with
    eeg_features.d1MeanAmp;
    eeg_features.d1VarAmp;
    %


    fft1d = fft(deriv1);


    %% modified
    % cannot get following per channel
    
    %Max of maxes of channel fourier ampltiudes
    % eeg_features.d1MaxMaxFourAmp(n) = max(max(abs(fft1d)));
    % replaced with
    eeg_features.d1MaxFourAmp(1:nbchan,n) = max(abs(fft1d))';
    
    %Mean of maxes of channel fourier ampltiudes 
    % eeg_features.d1MeanMaxFourAmp(n) = mean(max(abs(fft1d)));
    %replaced with
    eeg_features.d1MeanFourAmp(1:nbchan,n) = mean(abs(fft1d))';

    %Var of maxes of channel fourier ampltiudes 
    % eeg_features.d1VarMaxFourAmp(n) = var(max(abs(fft1d))); 
    % replaced with
    eeg_features.d1VarFourAmp(1:nbchan,n) = var(abs(fft1d))'; 
    %


    % Algo 3 2nd derivative global features (Kaggle)
    deriv2 = diff(diff(eeg'));

    %Max of channel max amplitudes 
    eeg_features.d2MaxAmp(1:nbchan,n) = max(abs(deriv2))';


    %% modified
    % cannot get following per channel
    
    %Mean of channel max amplitudes 
    % eeg_features.d2MeanMaxAmp(n) = mean(max(abs(deriv2)));
    % replaced with 
    eeg_features.d2MeanAmp(1:nbchan,n) = mean(abs(deriv2))';
    
    %Var of channel max ampltidues 
    % eeg_features.d2VarMaxAmp(n) = var(max(abs(deriv2)));
    % replaced with
    eeg_features.d2VarAmp(1:nbchan,n) = var(abs(deriv2))';
    
    %Var of mean channel amplitude 
    % eeg_features.d2VarMeanAmp(n) = var(mean(abs(deriv2)));
    % replaced with
    eeg_features.d2VarAmp;
    eeg_features.d2MeanAmp;
    
    %Var of individual channel var in amplitude 
    % eeg_features.d2VarVarAmp(n) = var(var(abs(deriv2)));
    % replaced with
    eeg_features.d2VarAmp;
    
    %Mean of individual channel var in ampltiude 
    % eeg_features.d2MeanVarAmp(n) = mean(var(abs(deriv2)));
    % replaced with
    eeg_features.d2MeanAmp;
    eeg_features.d2VarAmp;
    %

    fft2d = fft(deriv2);


    %% modified
    % cannot get following per channel
    
    %Max of maxes of channel fourier ampltiudes
    % eeg_features.d2MaxMaxFourAmp(n) = max(max(abs(fft2d)));
    % replaced with
    eeg_features.d2MaxFourAmp(1:nbchan,n) = max(abs(fft2d))';

    %Mean of maxes of channel fourier ampltiudes 
    % eeg_features.d2MeanMaxFourAmp(n) = mean(max(abs(fft2d)));
    % replaced with
    eeg_features.d2MeanFourAmp(1:nbchan,n) = mean(abs(fft2d))';

    %Var of maxes of channel fourier ampltiudes 
    % eeg_features.d2VarMaxFourAmp(n) = var(max(abs(fft2d)));
    % replaced with
    eeg_features.d2VarFourAmp(1:nbchan,n) = var(abs(fft2d))';
    %

    % TEMPORAL FEATURES FROM EEG_PLOTTING FOLDER
    %method of line length calculation assumes constant spacing of data in
    %time
    linelengths = sum(abs(diff(eeg')));
    
    %avgd line length across all channels
    % eeg_features.linelengthmean(n) = mean(linelengths);
    % replaced with
    eeg_features.linelength(1:nbchan,n) = linelengths';

    
    %mean channel kurtosis
    % eeg_features.kurtavg(n) = mean(kurtosis(eeg'));
    % replaced with
    eeg_features.kurtchan(1:nbchan,n) = kurtosis(eeg')';
    

    % %average shannon entropy *magnitude* (i.e. absolute value)
    %% abs(wentropy) is only one value? why mean? not done per channel
    % % eeg_features.shanavg(n) = mean(abs(wentropy(eeg', 'shannon')));
    % % replaced with
    % eeg_features.shanchan(n) = mean(abs(wentropy(eeg', 'shannon')));
    % 

    %non-linear energy (code is directly from EEG_plotting; slightly modified)
    nle = zeros(1,length(eeg)-3);
    for i=4:length(eeg)
        nle(i-3) = eeg(i-1)*eeg(i-2)-eeg(i)*eeg(i-3);
    end

    %% cannot do per channel
    % eeg_features.nlemean(n) = mean(mean(abs(nle)));
    % eeg_features.nleavgstd(n) = mean(std(nle));

    % SPECTRAL FEATURES FROM EEG_PLOTTING FOLDER
    deltapow = bandpower(eeg', Fs,[1 4]);
    thetapow = bandpower(eeg', Fs,[4 8]);
    alphapow = bandpower(eeg', Fs,[8 12]);
    betapow = bandpower(eeg', Fs,[12 18]);

    total = bandpower(eeg', Fs, [1 18]); %total bandpower in bands above

    deltaratio = deltapow./total; %relative pow in delta band
    thetaratio = thetapow./total;%relative pow in theta band
    alpharatio = alphapow./total;%relative pow in alpha band
    betaratio = betapow./total;%relative pow in beta band

    deltatheta = deltapow./thetapow;
    deltaalpha = deltapow./alphapow;
    thetaalpha = thetapow./alphapow;
    % 
    % eeg_features.deltakurtosis(n) = kurtosis(deltapow,0);
    % eeg_features.thetakurtosis(n) = kurtosis(thetapow,0);
    % eeg_features.alphakurtosis(n) = kurtosis(alphapow,0);
    % eeg_features.betakurtosis(n) = kurtosis(betapow,0);
    % 

    eeg_features.deltarat(1:nbchan,n) = deltaratio';
    eeg_features.thetarat(1:nbchan,n) = thetaratio';
    eeg_features.alpharat(1:nbchan,n) = alpharatio';
    eeg_features.betarat(1:nbchan,n) = betaratio';
    % eeg_features.deltameanrat(n) = mean(deltaratio);
    % eeg_features.thetameanrat(n) = mean(thetaratio);
    % eeg_features.alphameanrat(n) = mean(alpharatio);
    % eeg_features.betameanrat(n) = mean(betaratio);
    % 
    % eeg_features.deltaminrat(n) = min(deltaratio);
    % eeg_features.thetaminrat(n) = min(thetaratio);
    % eeg_features.alphaminrat(n) = min(alpharatio);
    % eeg_features.betaminrat(n) = min(betaratio);
    % 
    % eeg_features.deltastdrat(n) = std(deltaratio);
    % eeg_features.thetastdrat(n) = std(thetaratio);
    % eeg_features.alphastdrat(n) = std(alpharatio);
    % eeg_features.betastdrat(n) = std(betaratio);
    % 
    % eeg_features.deltapctrat(n) = prctile(deltaratio, 95);
    % eeg_features.thetapctrat(n) = prctile(thetaratio, 95);
    % eeg_features.alphapctrat(n) = prctile(alpharatio, 95);
    % eeg_features.betapctrat(n) = prctile(betaratio, 95);
    % 

    % %relative ratio features
    eeg_features.deltatheta(1:nbchan,n) = deltatheta';
    eeg_features.deltaalpha(1:nbchan,n) = deltaalpha';
    eeg_features.thetaalpha(1:nbchan,n) = thetaalpha';
    % eeg_features.deltathetamean(n) = mean(deltatheta);
    % eeg_features.deltaalphamean(n) = mean(deltaalpha);
    % eeg_features.thetaalphamean(n) = mean(thetaalpha);
    % 
    % eeg_features.deltathetamin(n) = min(deltatheta);
    % eeg_features.deltaalphamin(n) = min(deltaalpha);
    % eeg_features.thetaalphamin(n) = min(thetaalpha);
    % 
    % eeg_features.deltathetastd(n) = std(deltatheta);
    % eeg_features.deltaalphastd(n) = std(deltaalpha);
    % eeg_features.thetaalphastd(n) = std(thetaalpha);
    % 
    % eeg_features.deltathetapct(n) = prctile(deltatheta, 95);
    % eeg_features.deltaalphapct(n) = prctile(deltaalpha, 95);
    % eeg_features.thetaalphapct(n) = prctile(thetaalpha, 95);
    % 

    %log entropy magnitude
    %% abs(wentropy) is only one value? why mean? not done per channel
    % log_entropy_magnitude = abs(wentropy(eeg', 'log energy'));
    % eeg_features.meanlogentropy(n) = mean(log_entropy_magnitude);
    % 
    % %magnitude of cross-correlation between channels (need to choose a lag)
    % cross_correlation = abs(xcorr(eeg')); %abs cross-cor. between columns/channels
    % eeg_features.xcorrmean(n) = mean(mean(cross_correlation));
    % eeg_features.xcorrstd(n) = std(cross_correlation, 1, 'all'); %std of all elements
    % 
    % corr = abs(corrcoef(eeg'));
    % eeg_features.corrmean(n) = mean(mean(corr));
    % eeg_features.xcorrstd(n) = std(corr, 1, 'all'); %std of all elements
    % 

    % %amplitude calculations
    amp = abs(eeg');
    % eeg_features.geomeanamp(n) = mean(geomean(amp));
    % eeg_features.harmmeanamp(n) = mean(harmmean(amp));
    eeg_features.geomeanamp(1:nbchan,n) = geomean(amp)';
    eeg_features.harmmeanamp(1:nbchan,n) = harmmean(amp)';
    % 

    % %skewness of amplitude distribution per channel
    % eeg_features.meanskewamp(n) = mean(skewness(amp, 0));
    % eeg_features.stdskewamp(n) = std(skewness(amp, 0));
    eeg_features.skewamp(1:nbchan,n) = skewness(amp, 0)';
    % eeg_features.overallskewamp(n) = skewness(reshape(amp.',1,[]), 0);
    % 

    % %iqr of amplitude
    % eeg_features.meaniqrchannelamp(n) = mean(iqr(amp));
    eeg_features.iqrchannelamp(1:nbchan,n) = iqr(amp)';
    % %iqr of signal values
    % eeg_features.overalliqramp(n) = iqr(eeg', 'all');
    % 

    %spectral entropy magnitude
    spect = [];
    spectkurt = [];
    changept_counter = 0;
    peak_counter = 0;
    for i = 1:size(eeg, 1)
        [se, te] = pentropy(abs(eeg(i, :)), Fs);
        spect(i, :) = se;
        spectkurt(i, :) = pkurtosis(abs(eeg(i,:)));
        changept_counter = changept_counter + numel(findchangepts(eeg(i, :)));
        peak_counter = peak_counter + numel(findpeaks(eeg(i, :)));
    end
    
    % %average spectral entropy across time and channels
    % eeg_features.avgspectent(n) = mean(mean(spect));
    % eeg_features.sdspectent(n) = std(mean(spect'));
    eeg_features.avgspectent(1:nbchan,n) = mean(spect,2);
    eeg_features.sdspectent(1:nbchan,n) = std(spect')';

    % %pct of points that are changepoints (via CPD algo)
    % eeg_features.pctchangepoint(n) = changept_counter/numel(eeg);
    % %pct of points taht are peaks via peak prominence
    % eeg_features.pctpeakpoint(n) = peak_counter/numel(eeg);
    
    % %SPECTRAL KURTOSIS
    % eeg_features.avgspectkurt(n) = mean(mean(spectkurt));
    % eeg_features.sdspectkurt(n) = std(mean(spectkurt'));
    eeg_features.avgspectkurt(1:nbchan,n) = mean(spectkurt,2);
    eeg_features.sdspectkurt(1:nbchan,n) = std(spectkurt')';
    % 

    % % Features based off of EEG_features_MATLAB_donotshare FOLDER
    % %rms amplitude
    rmsamp = sqrt(mean(eeg' .* eeg'));
    % eeg_features.meanrms(n) = mean(rmsamp);
    % eeg_features.sdrms(n) = std(rmsamp);
    eeg_features.meanrms(1:nbchan,n) = rmsamp';

    fprintf('...All done.\n')
    %% update variables
    n = n+1;
    start_idx = end_idx;
    end_idx = start_idx + 10*Fs - 1;
end

feature_eeg = eeg_features;
end
