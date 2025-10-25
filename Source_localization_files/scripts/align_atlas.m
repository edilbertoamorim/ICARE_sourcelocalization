

cfg = [];
cfg.parameter     = 'tissue';  % or 'pow' or whatever your atlas uses
cfg.interpmethod  = 'nearest'; % nearest-neighbor to preserve ROI labels
cfg.vol           = mri;       % target MRI
atlas_on_mri = ft_sourceinterpolate(cfg, atlas, mri);

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


cfg = [];
cfg.parameter  = 'tissue';
cfg.filename   = 'atlas_new_aligned.nii.gz';
cfg.filetype   = 'nifti_gz';
cfg.dataformat = 'nifti_gz';
ft_volumewrite(cfg, atlas_realigned);



