%% ================================
% Build Lead Field (Forward Model)
% ================================
% Author A.Faloppa 20/09/2025
% This script generate a lead field forward model for source reconstruction
% It might take from 5 to 15 minues depending on the resolution defined
%
% Only fieldtrip tool is needed for this script (overlap with eeglab might cause errors)
% Add to the path Source_localization_files functions
%
% Input : mri data (optionally manually loaded in 'mri' - fieldtrip format)
% Output : File in output_dir

clear; clc;

leadfield_file = 'Source_localization_files/Standard_DK_MNI_atlas.mat';
load(leadfield_file);

ft_defaults

%% Parameters
output_dir  = 'Source_localization_files/leadfield_output';
high_res    = 6;     % mm grid spacing
low_res     = 10;    % mm grid spacing
inwardshift = -0.5;  % push source grid inward to avoid skull boundary
normalizeLF = 'yes'; % normalize leadfield vectors
plot_flag   = 0;     % Plot all ROI in different figures (WARNING 86 figures) 

if ~exist(output_dir, 'dir'); mkdir(output_dir); end

if ~exist('mri','var')
    error('MRI variable "mri" not found.');
end

%% 2) Define the 19 electrodes you want
elec_labels = {'Fp1','Fp2','F3','F4','C3','C4','P3','P4','O1','O2',...
               'F7','F8','T3','T4','T5','T6','Fz','Cz','Pz'};

%% 3) Compute leadfields and resources 

% prepare common steps !! Might take long time !!
[headmodel, elec_aligned, scalp_mesh] = prepare_headmodel_and_electrodes(mri, elec_labels);

% low-resolution leadfield
[LF_low, leadfield_low, inside_low, src_low] = compute_sourcemodel_and_leadfield(mri, elec_aligned, headmodel, low_res, inwardshift, normalizeLF);

% high-resolution leadfield
[LF_high, leadfield_high, inside_high, src_high] = compute_sourcemodel_and_leadfield(mri, elec_aligned, headmodel, high_res, inwardshift, normalizeLF);

% Build dummy source model to get voxels mask
% atlas.tissuelabel{10} = 'Third_Ventricle';
% atlas.tissuelabel{11} = 'Fourth_Ventricle';
roi_list = strrep(atlas.tissuelabel, '-', '_'); 

% Interpolate atlas to source model for plotting
[source_on_mri, atlas_model, ROI_mask2] = interpolate_atlas_to_source(leadfield_high, inside_high, mri, atlas, roi_list, plot_flag);

%% 4) Save files
save(fullfile(output_dir,'leadfield_19elec.mat'), ...
    'LF_low', 'leadfield_low', 'inside_low', ...
    'LF_high', 'leadfield_high', 'inside_high', ...
    'headmodel', 'elec_aligned', ...
    'roi_list', 'source_on_mri', 'atlas_model', 'ROI_mask');

