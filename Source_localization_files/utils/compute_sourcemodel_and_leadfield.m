function [LFmatrix, leadfield, inside_idx, sourcemodel] = compute_sourcemodel_and_leadfield(mri, elec_aligned, headmodel, grid_res, inwardshift, normalizeLF)
%COMPUTE_SOURCEMODEL_AND_LEADFIELD Compute source grid and leadfield
%
% Inputs:
%   mri          - FieldTrip MRI structure
%   elec_aligned - aligned electrode structure
%   headmodel    - FieldTrip headmodel
%   grid_res     - grid resolution in mm
%   inwardShift  - inward shift of source grid (mm, default 0)
%   normalizeLF  - 'yes' or 'no' (default 'yes')
%
% Outputs:
%   LFmatrix     - numeric leadfield [sensors x (voxels*3)]
%   leadfield    - FieldTrip leadfield structure
%   inside_idx   - indices of voxels inside brain
%   sourcemodel  - FieldTrip sourcemodel

%% Create source grid
cfg = [];
cfg.resolution = grid_res;
cfg.method = 'basedonmri';
cfg.grid.unit = 'mm';
cfg.mri = mri;
cfg.inwardshift = inwardshift;
sourcemodel = ft_prepare_sourcemodel(cfg);

inside_idx = find(sourcemodel.inside);
fprintf('Total voxels inside brain: %d\n', numel(inside_idx));

%% Compute leadfield
cfg = [];
cfg.elec = elec_aligned;
cfg.headmodel = headmodel;
cfg.sourcemodel = sourcemodel;
cfg.channel = elec_aligned.label;
cfg.normalize = normalizeLF;
leadfield = ft_prepare_leadfield(cfg);

% Convert to numeric matrix
LFmatrix = cell2mat(leadfield.leadfield(inside_idx));

fprintf('Leadfield size: %d sensors x %d columns\n', size(LFmatrix,1), size(LFmatrix,2));
[LFmatrix, inside_idx, removed_idx] = remove_nan_voxels(LFmatrix, inside_idx);

% Quick visualization
figure;
ft_plot_headmodel(headmodel,'facealpha',0.1);
hold on;
ft_plot_mesh(sourcemodel.pos(inside_idx,:),'vertexcolor','g');
ft_plot_mesh(sourcemodel.pos(removed_idx,:),'vertexcolor','r');
ft_plot_sens(elec_aligned,'style','r*');
title(strcat("19 EEG Electrodes, Headmodel, and Source Grid ", string(grid_res), " mm resolution"));
axis equal;
xlabel('x'); ylabel('y'); zlabel('z');


end

%% Helper: Remove voxels with NaNs
function [LFmatrix_clean, inside_idx_clean, removed_idx] = remove_nan_voxels(LFmatrix, inside_idx)
%REMOVE_NAN_VOXELS Remove voxels with NaNs in the leadfield matrix
%
% Inputs:
%   LFmatrix   - [Nsensors x (Nvox*3)] leadfield matrix
%   inside_idx - indices of voxels inside the brain
%
% Outputs:
%   LFmatrix_clean     - cleaned leadfield matrix
%   inside_idx_clean   - corresponding cleaned inside_idx
%   removed_idx        - indices of voxels that were removed (relative to inside_idx)

Nsensors = size(LFmatrix, 1);
Nvox = numel(inside_idx);

% reshape to [Nsensors x 3 x Nvox] for voxel-wise handling
LF3 = reshape(LFmatrix, Nsensors, 3, Nvox);

% identify voxels with any NaNs
bad_vox = any(any(isnan(LF3), 2), 1);

fprintf('Removing %d voxels with NaNs from leadfield (out of %d)\n', sum(bad_vox), Nvox);

% remove bad voxels
LF3(:, :, bad_vox) = [];
inside_idx_clean = inside_idx(~bad_vox);

% indices of removed voxels relative to inside_idx
removed_idx = inside_idx(bad_vox);

% reshape back to [Nsensors x (Nvox*3)]
LFmatrix_clean = reshape(LF3, Nsensors, []);

fprintf('New leadfield size: %d sensors x %d columns\n', size(LFmatrix_clean,1), size(LFmatrix_clean,2));
end