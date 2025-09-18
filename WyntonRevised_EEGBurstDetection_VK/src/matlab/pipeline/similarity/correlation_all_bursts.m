function [correlation] = correlation_all_bursts(x,y)
%CORRELATION - returns the cross-correlation similarity between signals
%   x and y

% if length(x)<99
%     no_zeros = 99-length(x)
%     zero_vector = zeros(1,no_zeros)
%     x = [x zero_vector]
% end
% 
% if length(y)<99
%     no_zeros = 99-length(y)
%     zero_vector = zeros(1,no_zeros)
%     y = [y zero_vector]
% end

maxlag = length(x)-1;
[correlations, lags] = xcorr(x, y, maxlag, 'coeff');
correlation = max(correlations);
end

