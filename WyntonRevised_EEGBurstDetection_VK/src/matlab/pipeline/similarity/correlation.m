function [correlation] = correlation(x,y)
%CORRELATION - returns the cross-correlation similarity between signals
%   x and y
[correlations, lags] = xcorr(x, y);
correlation = max(correlations);
end

