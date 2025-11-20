% Utils with functions to align and interpolate atlas and MRI templates

% mri = ft_read_mri('warped_MIITRA.nii.gz');
% atlas = ft_read_atlas('warped_DK_atlas.nii.gz');

% roi_labels = readtable('DesikanKilliany-LabelID-LabelName-05mm.txt');
% 
% for roi = 1:length(atlas.tissuelabel)
% 
%     old_label = atlas.tissuelabel{roi};
%     roi_id = sscanf(old_label, 'tissue %d');
%     roi_name_index = roi_labels.Var1 == roi_id;
% 
%     atlas.tissuelabel{roi} = char(roi_labels.Var2(roi_name_index));
% end

cfg = [];
cfg.parameter  = 'tissue';
cfg.method     = 'nearest';        % important!
cfg.resolution = 1;                % 1 mm isotropic
atlas_rs = ft_volumereslice(cfg, atlas);

cfg = [];
cfg.parameter     = 'tissue';  % or 'pow' or whatever your atlas uses
cfg.interpmethod  = 'nearest'; % nearest-neighbor to preserve ROI labels
cfg.vol           = mri;       % target MRI
atlas_on_mri = ft_sourceinterpolate(cfg, atlas_rs, mri);

cfg = [];
cfg.method        = 'ortho';  % slices view; 
cfg.funparameter  = 'tissue'; % field from atlas_on_mri
cfg.maskparameter = cfg.funparameter; % mask to only show ROIs
cfg.funcolormap   = 'jet';    % color map
cfg.opacitymap    = 'rampup'; 
ft_sourceplot(cfg, atlas_on_mri);

cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'mni';  % or the MRI coordsys
atlas_realigned = ft_volumerealign(cfg, atlas_on_mri);

cfg = [];
cfg.method        = 'ortho';  % slices view;
cfg.funparameter  = 'tissue'; % field from atlas_on_mri
cfg.maskparameter = cfg.funparameter; % mask to only show ROIs
cfg.funcolormap   = 'jet';    % color map
cfg.opacitymap    = 'rampup'; 
ft_sourceplot(cfg, atlas_realigned);



