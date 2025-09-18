function [correlation] = correlation(x,y)
%CORRELATION - returns the cross-correlation similarity between signals
%   x and y

% maxlag = length(x)-1;
[correlations, lags] = xcorr(x, y);

% [correlations, lags] = xcorr(x, y);
correlation = max(correlations);
end

