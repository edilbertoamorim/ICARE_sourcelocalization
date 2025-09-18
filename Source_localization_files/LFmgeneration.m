%% ================================
% Build Lead Field (Forward Model)
% ================================
% Input : mri data (manually loaded in 'mri')
% Output : File in output_dir

clear; clc;

leadfield_file = 'Source_localization_files/mri_data.mat';
load(leadfield_file,  'mri');

%% Parameters
output_dir  = 'Source_localization_files/leadfield_output';
grid_res    = 10;    % mm grid spacing
inwardshift = -1.5;  % push source grid inward to avoid skull boundary
normalizeLF = 'yes'; % normalize leadfield vectors

if ~exist(output_dir, 'dir'); mkdir(output_dir); end

if ~exist('mri','var')
    error('MRI variable "mri" not found.');
end

%% 2) Define the 19 electrodes you want
elec_labels = {'Fp1','Fp2','F3','F4','C3','C4','P3','P4','O1','O2',...
               'F7','F8','T3','T4','T5','T6','Fz','Cz','Pz'};

%% 3) Load full 10-20 electrodes
elec_all = ft_read_sens('standard_1020.elc');

% Find indices
[tf, idx] = ismember(elec_labels, elec_all.label);
if ~all(tf)
    error('Some requested electrodes not found in standard_1020.elc.');
end

% Subset electrodes correctly
elec = elec_all;
elec.label   = elec_all.label(idx);
elec.chanpos = elec_all.chanpos(idx,:);
elec.elecpos = elec_all.elecpos(idx,:);
% Optional: identity montage for EEG
if isfield(elec_all,'tra')
    elec.tra = elec_all.tra(idx, idx);
else
    elec.tra = eye(length(idx));
end

%% 4) Align electrodes to MRI
cfg = [];
cfg.method = 'interactive';  % if you want GUI, but optional
cfg.coordsys = 'spm';        % aligns MRI to AC-PC space
mri_realigned = ft_volumerealign(cfg, mri);
cfg = [];
cfg.output = 'scalp';
segmented = ft_volumesegment(cfg, mri);

% Optional: smooth scalp mesh to help alignment
scalp_mesh = ft_prepare_mesh([], segmented);

% 3) Automatic alignment
cfg = [];
cfg.method    = 'headshape';
cfg.headshape = scalp_mesh; % scalp mesh
cfg.elec      = elec;
cfg.warp      = 'rigidbody'; % only translate/rotate
elec_aligned1 = ft_electroderealign(cfg);

rot_deg     = [0, 0, -88];      % rotation around x, y, z in degrees
scale_factor= [1.2 1.2 1.2];    % scale for x,y,z
translation = [15 10 24];       % translation in mm

elec_aligned = transform_plot_electrodes(elec_aligned1, scalp_mesh, rot_deg, scale_factor, translation);

%% 5) Segment MRI and create headmodel
cfg = [];
cfg.output = {'brain','skull','scalp'};
segmented_mri = ft_volumesegment(cfg, mri);

cfg = [];
cfg.method = 'dipoli';  % or 'singleshell' for faster
headmodel = ft_prepare_headmodel(cfg, segmented_mri);

%% 6) Create source grid
cfg = [];
cfg.grid.resolution = grid_res;
cfg.grid.unit = 'mm';
cfg.mri = mri;
cfg.inwardshift = inwardshift;
sourcemodel = ft_prepare_sourcemodel(cfg);

inside_idx = find(sourcemodel.inside);
fprintf('Total voxels inside brain: %d\n', numel(inside_idx));

%% 7) Compute leadfield
cfg = [];
cfg.elec = elec_aligned;
cfg.headmodel = headmodel;
cfg.grid = sourcemodel;
cfg.channel = elec_aligned.label;
cfg.normalize = normalizeLF;
leadfield = ft_prepare_leadfield(cfg);

% Convert to numeric matrix [sensors x (voxels * 3)]
LFmatrix = cell2mat(leadfield.leadfield(inside_idx));

fprintf('Leadfield size: %d sensors x %d columns\n', size(LFmatrix,1), size(LFmatrix,2));

%% 8) Save
save(fullfile(output_dir,'leadfield_19elec.mat'), ...
     'LFmatrix','leadfield','inside_idx','sourcemodel','headmodel','elec_aligned');

%% 9) Quick visualization
figure;
ft_plot_headmodel(headmodel,'facealpha',0.1);
hold on;
ft_plot_mesh(sourcemodel.pos(inside_idx,:),'vertexcolor','g');
ft_plot_sens(elec_aligned,'style','r*');
title('19 EEG Electrodes, Headmodel, and Source Grid');
axis equal;
xlabel('x'); ylabel('y'); zlabel('z');



%%%%%%%%%%%%%%%%%%%%%%
%% Helper Functions %%
%%%%%%%%%%%%%%%%%%%%%%

function elec_transformed = transform_plot_electrodes(elec, scalp_mesh, rot_deg, scale_factor, translation)
%TRANSFORM_PLOT_ELECTRODES Apply rotation, scale, translation to electrodes and plot
%
% Inputs:
%   elec        - FieldTrip electrode structure
%   scalp_mesh  - FieldTrip scalp mesh (optional, can pass [])
%   rot_deg     - 1x3 rotation angles [x y z] in degrees
%   scale_factor- scalar or 1x3 for scaling
%   translation - 1x3 vector in mm [x y z]
%
% Output:
%   elec_transformed - transformed electrode structure

% Copy electrode structure
elec_transformed = elec;

% Convert degrees to radians
rot_rad = rot_deg * pi / 180;

% Rotation matrices
Rx = [1 0 0; 0 cos(rot_rad(1)) -sin(rot_rad(1)); 0 sin(rot_rad(1)) cos(rot_rad(1))];
Ry = [cos(rot_rad(2)) 0 sin(rot_rad(2)); 0 1 0; -sin(rot_rad(2)) 0 cos(rot_rad(2))];
Rz = [cos(rot_rad(3)) -sin(rot_rad(3)) 0; sin(rot_rad(3)) cos(rot_rad(3)) 0; 0 0 1];

R = Rz * Ry * Rx;  % combined rotation

% Apply rotation, scaling, translation
elec_transformed.chanpos = (elec_transformed.chanpos * R') .* scale_factor + translation;
elec_transformed.elecpos = (elec_transformed.elecpos * R') .* scale_factor + translation;

% Plot electrodes
figure;
ft_plot_sens(elec_transformed, 'label', 'on');
hold on;
if ~isempty(scalp_mesh)
    ft_plot_mesh(scalp_mesh, 'facecolor', [0.8 0.8 0.8], 'facealpha', 0.3, 'edgecolor', 'none');
end
axis equal;
title('Transformed Electrodes');

end
