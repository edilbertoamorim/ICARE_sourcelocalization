function ROI_mask = get_ROI_mask(atlas, leadfdc, insideix, roi_list)
%BUILD_ROI_MASK Create voxel masks for each ROI based on an atlas and lead field
%
%   ROI_mask = build_ROI_mask(atlas, leadfdc, insideix, roi_list)
%
%   INPUTS:
%       atlas     - FieldTrip atlas structure with fields:
%                   .tissue   -> atlas labels in source space
%                   .dim      -> 3D dimensions of the atlas
%                   .pos      -> positions of atlas voxels
%       leadfdc   - lead field structure from FieldTrip
%                   must contain fields: .pos and .inside
%       insideix  - indices of voxels inside the brain region of interest
%       roi_list  - cell array of ROI names (excluding "Other")
%
%   OUTPUT:
%       ROI_mask  - struct with a logical mask per ROI
%                   Each field corresponds to one ROI in roi_list
%                   Mask length matches the number of inside voxels
%
%   NOTE:
%       This function uses FieldTrip's ft_sourceinterpolate.
%       Make sure FieldTrip is added to your MATLAB path before running.

    %% --- Build dummy source model to match lead field space ---
    src_template = [];
    src_template.avg.pow = zeros(size(leadfdc.pos,1),1);  % one entry per voxel
    src_template.inside = insideix;                       % provided inside voxels
    src_template.outside = find(~leadfdc.inside);         % complement
    src_template.pos = leadfdc.pos;                       % voxel positions
    src_template.method = 'average';

    %% --- Interpolate atlas to lead field space ---
    cfg = [];
    cfg.parameter = 'tissue';        % interpolate tissue labels
    cfg.interpmethod = 'nearest';    % nearest neighbor to preserve discrete labels
    cfg.verbose       = 'no';        % suppress FieldTrip output
    atlas_on_source = ft_sourceinterpolate(cfg, atlas, src_template);

    %% --- Build ROI masks ---
    ROI_mask = struct();
    for i = 1:length(roi_list) 
        full_mask = atlas_on_source.tissue == i; 
        ROI_mask.(roi_list{i}) = full_mask(insideix); % keep only voxels inside brain
        % roi_list{i}
        % sum(full_mask) % See how many voxel for i-th ROI
    end
end