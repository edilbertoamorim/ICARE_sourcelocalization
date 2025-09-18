function plot_ROIs(patient_ID, dir_input)

    % Create Output directories
    dir_out = fullfile(dir_input, 'features_loc_results');
    dir_table = [dir_out, '\01_table_files\'];
    out_dir_figures = [dir_out, '\02_ROI_mapping\', char(patient_ID), '_normalized'];
    if ~exist(out_dir_figures, 'dir'); mkdir(out_dir_figures); end

    % ------- Load saved table -------
    T = readtable(fullfile(dir_table, [char(patient_ID) '_ROIs.xlsx']));

    % ------- Load resources (same as in the original pipeline) -------
    ft_defaults
    leadfield_file = 'Source_localization_files/MNI_DKA_Standard_Lead_Field_Burst.mat';
    load(leadfield_file, 'atlas', 'leadfdc', 'insideix', 'mri');  % only what we actually need

    % --- Make atlas ROI labels identical to the ones used when saving ---
    atlas.tissuelabel(10) = {'Third_Ventricle'};
    atlas.tissuelabel(11) = {'Fourth_Ventricle'};
    atlas_roi_labels = cellfun(@(s) strrep(s,'-','_'), atlas.tissuelabel(2:end), 'uni', 0); % skip "Other"

    % ------- Precompute atlas→source-grid mapping ONCE -------
    src_template = [];
    src_template.dim      = leadfdc.dim;
    src_template.pos      = leadfdc.pos;
    src_template.inside   = insideix;
    src_template.outside  = find(leadfdc.inside==0);
    src_template.method   = 'average';
    src_template.avg.pow  = nan(size(leadfdc.pos,1),1);

    % --- Step 1:  ---
    powvec = nan(size(leadfdc.pos,1),1);
    powvec(insideix)=0;

    % leadfdc.pos(insideix(1:100), :); % source positions of strongest sources
    % src_template.pos      = leadfdc.pos;

    % --- Step 4: create source structure ---
    rsourceAtlas = src_template;
    rsourceAtlas.avg.pow = powvec;

    % Interpolate source power into MRI space
    cfg = [];
    cfg.downsample = 1;
    cfg.parameter    = 'pow';
    cfg.interpmethod = 'nearest';
    cfg.verbose  = 'no';   % disables most info prints
    rsourceInt_atlas = ft_sourceinterpolate(cfg, rsourceAtlas, mri);

    % Interpolate atlas labels onto source grid
    cfg = [];
    cfg.interpmethod = 'nearest';
    cfg.parameter    = 'tissue';
    cfg.verbose  = 'no';   % disables most info prints
    sourcemodel2     = ft_sourceinterpolate(cfg, atlas, rsourceInt_atlas);

    % ------- Decide which columns in the table are ROI columns -------
    roi_cols = intersect(T.Properties.VariableNames, atlas_roi_labels, 'stable');

    % ------- Loop by feature; fix color limits per feature -------
    feat_names = unique(T.FeatureName, 'stable');

    for f = 1:numel(feat_names)
        this_feat = feat_names{f};
        feat_rows = T(strcmp(T.FeatureName, this_feat), :);

        % Compute fixed color limits across ALL hours for this feature
        V = table2array(feat_rows(:, roi_cols));
        V = V(:); V = V(~isnan(V));
        if isempty(V), warning('No ROI values for feature %s.', this_feat); continue; end
        clim = [prctile(V, 10, "all"), prctile(V, 100, "all")];

        % Plot each hour for this feature using the SAME color limits
        for r = 1:height(feat_rows)

            for k = 1:numel(roi_cols)
                roi_name = roi_cols{k};
                val = feat_rows{r, roi_name};
                if isnumeric(val) && ~isnan(val)
                    ix_label = find(strcmp(atlas_roi_labels, roi_name), 1);
                    if ~isempty(ix_label)
                        tissue_code = ix_label + 1;                                      % +1 because 1 = "Other"
                        rsourceInt_atlas.pow(sourcemodel2.tissue == tissue_code) = val;  % assign ROI mean to all voxels
                    end
                end
            end

            % mask: keep only ROI voxels, discard "Other"
            % rsourceInt_atlas.pow(sourcemodel2.tissue == 1) = NaN;

            % --- Step 5: plot with fixed color limits ---
            cfg = [];
            cfg.method        = 'slice';
            cfg.funparameter  = 'pow';
            cfg.funcolormap   = 'plasma';
            cfg.funcolorlim   = clim;
            cfg.opacitylim    = [clim(1)*0.1, clim(2)];
            cfg.opacitymap    = 'rampup';
            cfg.maskparameter = 'pow'; % mask background
            cfg.locationcoordinates = 'voxel';
            cfg.crosshair     = 'yes';
            cfg.verbose  = 'no';   % disables most info prints
            figure; ft_sourceplot(cfg, rsourceInt_atlas);

            h = colorbar;
            feat_name_safe = strrep(this_feat, '_', '\_');
            h.Label.String = sprintf('%s: source power [a.u.]', feat_name_safe);

            % Save
            hr = feat_rows.Hour(r);
            out_name = [char(patient_ID) '_FeatN' num2str(f) '_' char(this_feat) '_Hour_' num2str(hr) '_ROI_normalized.png'];
            if ~exist(out_dir_figures, 'dir'), mkdir(out_dir_figures); end
            saveas(gcf, fullfile(out_dir_figures, out_name)); close(gcf);
        end
    end
end
