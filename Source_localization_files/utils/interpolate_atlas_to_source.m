function [source_on_mri, atlas_on_source, ROI_mask] = interpolate_atlas_to_source(leadfdc, insideix, mri, atlas, roi_list, plot_flag)
%INTERPOLATE_ATLAS_TO_SOURCE Interpolates atlas labels onto a lead field source space
% and plots the voxel locations for each ROI.
%
%   [atlas_on_source, source_model] = interpolate_atlas_to_source(leadfdc, insideix, mri, atlas, roi_list)
%
%   INPUTS:
%       leadfdc   - Lead field structure with fields:
%                   .dim, .pos, .inside
%       insideix  - Indices of voxels considered "inside" the brain
%       mri       - MRI structure from FieldTrip
%       atlas     - Atlas structure with fields:
%                   .tissue, .pos, .dim
%       roi_list  - Cell array of ROI names (excluding "Other")
%
%   OUTPUTS:
%       source_on_mri    - MRI interpolated onto the lead field source grid (template for plotting)
%       atlas_on_source  - Structure containing interpolated atlas tissue labels (get tissue labels mask)
%       ROI_mask         - struct with a logical mask per ROI
%                          Each field corresponds to one ROI in roi_list
%                          Mask length matches the number of inside voxels
%
%   REQUIREMENTS:
%       FieldTrip must be installed and on the MATLAB path.

    %% --- Build dummy high-density source model ---
    % dummy source model to match lead field space (dim leadfc)
    src_template = [];
    src_template.dim      = leadfdc.dim;
    src_template.pos      = leadfdc.pos;
    src_template.inside   = insideix;
    src_template.outside  = find(~leadfdc.inside);
    src_template.method   = 'average';

    % Initialize power vector
    powvec = nan(size(leadfdc.pos, 1), 1);
    powvec(insideix) = nan;  % assign zero to inside voxels
    src_template.avg.pow = powvec;

    %% --- Interpolate MRI onto lead field source model grid ---
    cfg = [];
    cfg.downsample    = 1;
    cfg.interpmethod  = 'nearest';
    cfg.parameter     = 'pow';
    cfg.verbose       = 'no';  % suppress FieldTrip output
    source_on_mri = ft_sourceinterpolate(cfg, src_template, mri);

    %% --- Interpolate atlas tissue labels onto source grid ---
    cfg = [];
    cfg.interpmethod  = 'nearest';
    cfg.parameter     = 'tissue';
    cfg.verbose       = 'no';
    atlas_on_source = ft_sourceinterpolate(cfg, atlas, source_on_mri);

    %% --- Build ROI masks ---
    % dummy source model to match lead field space (dim plain)
    src_template = [];
    src_template.avg.pow = zeros(size(leadfdc.pos,1),1);  % one entry per voxel
    src_template.inside = insideix;                       % provided inside voxels
    src_template.outside = find(~leadfdc.inside);         % complement
    src_template.pos = leadfdc.pos;                       % voxel positions
    src_template.method = 'average';

    % Interpolate atlas to lead field space ---
    cfg = [];
    cfg.parameter = 'tissue';        % interpolate tissue labels
    cfg.interpmethod = 'nearest';    % nearest neighbor to preserve discrete labels
    cfg.verbose       = 'no';        % suppress FieldTrip output
    atlas_on_LF = ft_sourceinterpolate(cfg, atlas, src_template);

    ROI_mask = struct();
    for i = 1:length(roi_list) 
        full_mask = atlas_on_LF.tissue == i; 
        ROI_mask.(roi_list{i}) = full_mask(insideix); % keep only voxels inside brain

        % See how many voxel for i-th ROI
        if plot_flag
            roi_list{i}
            sum(full_mask) 
        end
    end

    %% --- Plot voxel masks per ROI ---
    if plot_flag
        for r = 1:length(roi_list)
            roi_name = roi_list{r};
    
            % Create a copy for plotting
            atlas_tmp = source_on_mri;
    
            % Assign value 1 to voxels belonging to this ROI
            atlas_tmp.pow(atlas_on_source.tissue == r) = 1;
            clim = [0 1];
    
            % Plot the ROI
            cfg = [];
            cfg.method        = 'slice';
            cfg.funparameter  = 'pow';
            cfg.funcolormap   = 'plasma';
            cfg.funcolorlim   = clim;
            cfg.opacitylim    = [clim(1)*0.1, clim(2)];
            cfg.opacitymap    = 'rampup';
            cfg.maskparameter = 'pow';  % mask background
            cfg.locationcoordinates = 'voxel';
            cfg.crosshair     = 'yes';
            cfg.verbose       = 'no';
    
            figure_handle = figure;
            ft_sourceplot(cfg, atlas_tmp);
            title(roi_name, 'Interpreter', 'none');
    
            % Wait for the figure to close before proceeding
            waitfor(figure_handle);
        end
    end
end
