function [headmodel, elec_aligned, scalp_mesh] = prepare_headmodel_and_electrodes(mri, elec_labels)
%PREPARE_HEADMODEL_AND_ELECTRODES Segment MRI, create headmodel, align electrodes
%
% Inputs:
%   mri         - FieldTrip MRI structure
%   elec_labels - cell array of electrode labels to use
%
% Outputs:
%   headmodel   - FieldTrip headmodel
%   elec_aligned- aligned electrode structure
%   scalp_mesh  - optional scalp mesh for plotting / alignment

%% Load full 10-20 electrodes
elec_all = ft_read_sens('standard_1020.elc');

% Find requested electrodes
[tf, idx] = ismember(elec_labels, elec_all.label);
if ~all(tf)
    error('Some requested electrodes not found in standard_1020.elc.');
end

% Subset electrodes
elec = elec_all;
elec.label   = elec_all.label(idx);
elec.chanpos = elec_all.chanpos(idx,:);
elec.elecpos = elec_all.elecpos(idx,:);
if isfield(elec_all,'tra')
    elec.tra = elec_all.tra(idx, idx);
else
    elec.tra = eye(length(idx));
end

%% Align electrodes to MRI if not in MNI space

% cfg = [];
% cfg.method = 'interactive';  % if you want GUI, but optional
% cfg.coordsys = 'spm';        % aligns MRI to AC-PC space
% mri_realigned = ft_volumerealign(cfg, mri);
% cfg = [];
% cfg.output = 'scalp';
% segmented = ft_volumesegment(cfg, mri);
% 
% % Optional: smooth scalp mesh to help alignment
% scalp_mesh = ft_prepare_mesh([], segmented);

% % 3) Automatic alignment
% cfg = [];
% cfg.method    = 'headshape';
% cfg.headshape = scalp_mesh; % scalp mesh
% cfg.elec      = elec;
% cfg.warp      = 'rigidbody'; % only translate/rotate
% elec_aligned1 = ft_electroderealign(cfg);
% 
%
% % Manual Alignment
% % rot_deg     = [0, 0, -88];      % rotation around x, y, z in degrees
% % scale_factor= [1.2 1.2 1.2];    % scale for x,y,z
% % translation = [20 10 26];       % translation in mm
% 
% rot_deg     = [0, 0, 0];      % rotation around x, y, z in degrees
% scale_factor= [1 1 1];    % scale for x,y,z
% translation = [0 0 30];       % translation in mm
% 
% elec_aligned = transform_plot_electrodes(elec_aligned1, scalp_mesh, rot_deg, scale_factor, translation);

% If already aligned skip previous part
elec_aligned = elec; 

cfg = [];
cfg.output = 'scalp';
segmented = ft_volumesegment(cfg, mri);

% Optional: smooth scalp mesh to help alignment
scalp_mesh = ft_prepare_mesh([], segmented);

figure;
ft_plot_sens(elec, 'label', 'on');
hold on;
if ~isempty(scalp_mesh)
    ft_plot_mesh(scalp_mesh, 'facecolor', [0.8 0.8 0.8], 'facealpha', 0.3, 'edgecolor', 'none');
end
axis equal;
title('Aligned Electrodes');

%% Segment MRI and create headmodel
cfg = [];
cfg.output = {'scalp', 'skull', 'brain'};
segmented_mri = ft_volumesegment(cfg, mri);

cfg = [];
cfg.method = 'bemcp';  % alternative 'dipoli 'or 'singleshell' for more precise
headmodel = ft_prepare_headmodel(cfg, segmented_mri);

end

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