function voxel_ts = run_SBL_Beamformer(Y, LF_low, LF_high, champ_iterations, n_dir, plot_flag)
%
%   INPUTS:
%       Y                 - Sensors signal to reconstruct [n_sensors, n_samples]
%       LF_low            - Low resolution lead-field matrix [n_sensor, n_dipoles] (grouped) 
%       LF_high           - High resolution lead-field matrix [n_sensor, n_dipoles] (grouped) 
%       champ_iterations  - Number of iterations of champagne alorithm [int]
%       n_dir             - Orientations of the lead fireld matrix [int]
%       plot_flag         - 1: plot champagne itearations; 0: don't plot [bool]
%
%   OUTPUT:
%       voxel_ts - Time series per voxel (reduced among the dipoles orientations)
%
%   Reference to : Bayesian Adaptive Beamformer for Robust Electromagnetic 
%                  Brain Imaging of Correlated Sources in High Spatial Resolution
%                  DOI: 10.1109/TMI.2023.3256963
%


    % Get LF and signal dimensions
    [n_sensors, total_cols_low] = size(LF_low);
    n_voxels_low = total_cols_low / n_dir;
    total_cols_high = size(LF_high,2);
    n_voxels_high = total_cols_high / n_dir;
    n_samples = size(Y,2);

    % Noise covariance (rough estimate)
    Sigma_e = eye(n_sensors) * (trace(Y*Y')/n_sensors) * 1e-3;
   
    % Compute model covariance with low res LF
    n_voxels = n_voxels_low; 
    LFmatrix = LF_low;

    % Noise update
    [voxel_cov,~,~,model_cov,~,sensors_cov] = champ_noise_up(Y, LFmatrix, Sigma_e, champ_iterations, n_dir, 1, plot_flag, 0, 4, 1, 1e-16);
    if plot_flag, close(figure(1)); end

    % Compute model data covariance Σ_Y = Σ_e + Σ_v L_v α_v L_v'
    Sigma_Y = sensors_cov;

    for v = 1:n_voxels
        L_v = LFmatrix(:, n_dir*(v-1)+1 : n_dir*v);         % [n_sensors x n_dir]
        Sigma_Y = Sigma_Y + L_v * voxel_cov(:,:,v) * L_v';  % add each voxel contribution
    end

    %% Beamformer Source Reconstruction using Champagne Posterior

    % Reconstruction with high res LF
    n_voxels = n_voxels_high; 
    LFmatrix = LF_high;

    disp("Running high resolution beamformer...")
    
    % Pre-factorize Σ_Y
    try
        R = chol(Sigma_Y);
        solve = @(X) R \ (R' \ X);   % Efficient triangular solve
    catch
        solve = @(X) Sigma_Y \ X;     % Fallback to direct solve
    end
    
    % Allocate output [n_dir * n_voxels x n_samples]
    X_hat = zeros(n_dir * n_voxels, n_samples);
    
    % Loop over voxels and reconstruct
    for v = 1:n_voxels
        col_idx = n_dir*(v-1)+1 : n_dir*v;
        L_v = LFmatrix(:, col_idx);              % [n_sensors x n_dir]
        
        % Compute beamformer weights: W_v = Σ_Y⁻¹ L_v (L_v' Σ_Y⁻¹ L_v)⁻¹

        nominator   = solve(L_v);                % Σ_Y⁻¹ * L_v
        denominator = L_v' * nominator;          % (L_v' Σ_Y⁻¹ L_v)⁻¹ [n_dir x n_dir]
        W_v = nominator / denominator;           % [n_sensors x n_dir]
        
        % Reconstruct source timecourses
        X_hat(col_idx, :) = W_v' * Y;            % [n_dir x n_samples]
    end
    
    % PCA reduction per voxel
    disp('Reducing 3 orientations → 1 time series per voxel using PCA...');
    voxel_ts = zeros(n_voxels, n_samples);  % final output: [n_voxels x n_samples]

    for v = 1:n_voxels
        idx = (v-1)*n_dir + (1:n_dir);  % indices for the 3 orientations of voxel v (grouped, not interleaved)
        S_v = X_hat(idx, :);            % [3 x n_samples]

        % Center the data across time
        S_v = S_v - mean(S_v, 2);

        % PCA using SVD
        [U,~,~] = svd(S_v, 'econ');     % U: [3 x 3]
        voxel_ts(v, :) = U(:,1)' * S_v; % Project onto first principal component
    end

    % % PCA reduction per ROI
    % ROI_ts = zeros(length(roi_list), n_samples);
    % 
    % for i = 1:length(roi_list)
    %     roi_list{i};
    %     mask = ROI_mask.(roi_list{i});   % logical mask over voxels
    %     vox_idx = find(mask);            % indices of voxels in this ROI
    % 
    %     if isempty(vox_idx)
    %         ROI_ts(i, :) = ones(1, n_samples);
    %         continue
    %     end
    % 
    %     S_roi = X_hat(vox_idx, :);   % [n_sources_in_ROI x n_samples]
    % 
    %     % center across time
    %     S_roi = S_roi - mean(S_roi, 2);
    % 
    %     % PCA via SVD
    %     [U,~,~] = svd(S_roi, 'econ');
    %     ROI_ts(i, :) = U(:,1)' * S_roi; % 1 x n_samples (1st PC)
    % end


end