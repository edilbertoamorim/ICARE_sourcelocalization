function [ stats ] = compute_statistics_EEGLab( input, sampling_frequency )
%compute_statistics_EEGLab
%   Compute statistics for an EEGLab structure (input) and save them to a
%   structure of the form: (each feature is computed per channel per
%   epoch).
%       variance
%       skew
%       kurtosis
%       power_0_2_band
%       power_20_40_band

    %TODO: in case interpolated data must not be used, this might have to be modified.
    %TODO: since the number of channels per epoch will be variable, the implementation might need a cell.

    % Get statistical moments.
    c_var = squeeze(var(input.data,[],2));   % var is a matlab function computing a vector's variance.
    c_skew = squeeze(skewness(input.data,[],2));  % skewness is a matlab function computing a vector's skewness.
    c_kurt = squeeze(kurtosis(input.data,[],2));  % kurtosis is a matlab function computing a vector's kurtosis.

    % Extract the 0-2 Hz BandPower for all subjects.
    c_band_0_2 = zeros(size(input.data,1), size(input.data,3));
    for j = 1:size(input.data,1)
        for k = 1:size(input.data,3)
            c_band_0_2(j,k) = bandpower(input.data(j,:,k),sampling_frequency,[0.5,2]);  % 0.5 because that's the high pass in PREP_EEGLab.
        end
    end

    % Extract the 20-40 Hz BandPower for all subjects.
    c_band_20_40 = zeros(size(input.data,1), size(input.data,3));
    for j = 1:size(input.data,1)
        for k = 1:size(input.data,3)
            c_band_20_40(j,k) = bandpower(input.data(j,:,k),sampling_frequency,[20,40]);
        end
    end

    stats.variance = c_var;
    stats.skew = c_skew;
    stats.kurtosis = c_kurt;
    stats.power_0_2_band = c_band_0_2;
    stats.power_20_40_band = c_band_20_40;

end
