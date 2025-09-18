%% Implement basic burst suppression detection according to paper by Brandon.
%% See paper - https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3939433/

function [zs] = label_local_zs(signal,srate)
% Find burst suppression in a signal
%   signal - a matrix of n_channels X n_samples
    [n_channels, n_samples] = size(signal);
    zs = zeros(n_channels, n_samples);
    if n_samples==0
        return;
    end
    for i=1:n_channels
        channel_zs = find_zs_channel(signal(i, :), srate);
        zs(i, :) = channel_zs;
    end
end

function [channel_zs] = find_zs_channel(data,srate)
% Find burst suppression in a single channel
%  data - nonempty vector of n_samples
    
    % parameters
    [forgetting_time, burst_threshold] = DetectBsParams.get_params('forgetting_time', 'burst_threshold');
    beta = exp(-1/(forgetting_time*srate));
    
    n_samples = size(data, 2);

    % Go forwards
    variances_f = zeros(1, n_samples);
    mus_f = zeros(1, n_samples); 
    
    prev_mu_f = data(1);  % start this at the first value of the data
    prev_variance_f = 0; 
    
    
    for i=1:n_samples
        x_i = data(i);
        mu = beta*prev_mu_f + (1-beta)*x_i;
        variance = beta*prev_variance_f + (1-beta)*((x_i - mu)^2);
        variances_f(i) = variance;
        mus_f(i) = mu;
        prev_mu_f = mu;
        prev_variance_f = variance;
    end
    channel_zs_f = double(variances_f > burst_threshold);
    
    % Go backwards
%     variances_b = zeros(1, n_samples);
%     mus_b = zeros(1, n_samples);    
%     prev_mu_b = data(end);
%     prev_variance_b = 0;
%     
%     for i=n_samples:-1:1
%         x_i = data(i);
%         mu = beta*prev_mu_b + (1-beta)*x_i;
%         variance = beta*prev_variance_b + (1-beta)*((x_i - mu)^2);
%         variances_b(i) = variance;
%         mus_b(i) = mu;
%         prev_mu_b = mu;
%         prev_variance_b = variance;
%     end
%     channel_zs_b = double(variances_b > burst_threshold);
   
    channel_zs = channel_zs_f;
    % For debugging only.
%    variances_mus_truezs = true_zs;
%    variances_mus_truezs = [variances_mus_truezs; channel_zs];
%    variances_mus_truezs = [variances_mus_truezs; data];

end
