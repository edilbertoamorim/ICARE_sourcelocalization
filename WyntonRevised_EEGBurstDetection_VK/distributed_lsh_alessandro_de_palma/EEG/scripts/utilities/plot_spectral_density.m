function [ ] = plot_spectral_density( x, SAMPLING_FREQUENCY )
%PLOT_SPECTRAL_DENSITY Plot spectral density of signal x, having Fs SAMPLING_FREQUENCY.
% https://www.mathworks.com/examples/signal/mw/signal-ex08634157-power-spectral-density-estimates-using-fft

    periodogram(x,rectwin(length(x)),length(x),SAMPLING_FREQUENCY)
    title('Spectral density estimate (periodogram)')

end

