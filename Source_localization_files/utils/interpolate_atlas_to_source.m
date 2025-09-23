function [atlas_on_source, source_model] = interpolate_atlas_to_source(leadfdc, insideix, mri, atlas, roi_list, plot_flag)
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
%       atlas_on_source - MRI interpolated onto the lead field source grid
%       source_model    - Structure containing interpolated atlas tissue labels
%
%   REQUIREMENTS:
%       FieldTrip must be installed and on the MATLAB path.

    %% --- Build dummy high-density source model ---
    src_template = [];
    src_template.dim      = leadfdc.dim;
    src_template.pos      = leadfdc.pos;
    src_template.inside   = insideix;
    src_template.outside  = find(leadfdc.inside == 0);
    src_template.method   = 'average';

    % Initialize power vector
    powvec = nan(size(leadfdc.pos, 1), 1);
    powvec(insideix) = 0;  % assign zero to inside voxels
    src_template.avg.pow = powvec;

    %% --- Interpolate MRI onto source model grid ---
    cfg = [];
    cfg.downsample    = 1;
    cfg.interpmethod  = 'nearest';
    cfg.parameter     = 'pow';
    cfg.verbose       = 'no';  % suppress FieldTrip output
    atlas_on_source = ft_sourceinterpolate(cfg, src_template, mri);

    %% --- Interpolate atlas tissue labels onto source grid ---
    cfg = [];
    cfg.interpmethod  = 'nearest';
    cfg.parameter     = 'tissue';
    cfg.verbose       = 'no';
    source_model = ft_sourceinterpolate(cfg, atlas, atlas_on_source);

    %% --- Plot voxel masks per ROI ---
    if plot_flag
        for r = 1:length(roi_list)
            roi_name = roi_list{r};
    
            % Create a copy for plotting
            atlas_tmp = atlas_on_source;
    
            % Assign value 1 to voxels belonging to this ROI
            atlas_tmp.pow(source_model.tissue == (r + 1)) = 1;  
            clim = [0 1];
    
            % Plot the ROI
            cfg = [];
            cfg.method        = 'slice';
            cfg.funparameter  = 'pow';
            cfg.funcolormap   = 'plasma';
            cfg.funcolorlim   = clim;
            cfg.opacitylim    = [clim(1)*0.1, clim(2)];
            cfg.opacitymap    = 'rampup';
            cfg.maskparameter = 'pow';           % mask background
            cfg.locationcoordinates = 'voxel';
            cfg.crosshair     = 'yes';
            cfg.verbose       = 'no';
    
            figure;
            ft_sourceplot(cfg, atlas_tmp);
            title(roi_name, 'Interpreter', 'none');
        end
    end
end
