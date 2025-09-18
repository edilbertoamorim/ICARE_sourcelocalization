
%% Clear variables
clc
clear
close all

%% Add paths
addpath C:\Users\gvelasquez\Documents\MATLAB\fieldtrip-20230716\external\eeglab
addpath  C:\Users\gvelasquez\Documents\MATLAB\fieldtrip-20230716\
ft_defaults

%% Patient MRI and EEG data file
PID = 'C:\Users\gvelasquez\Documents\Source_localization_Fei\dataset\mni_icbm152_t1_tal_nlin_sym_09c';
Folder2Save = 'C:\Users\gvelasquez\Documents\Source_localization_Fei\document';

mri = ft_read_mri([PID '.nii']);
mri = ft_determine_coordsys(mri);

% MRI realigning
cfg          = [];
cfg.method   = 'interactive';
cfg.coordsys = 'ctf';
mri          = ft_volumerealign(cfg,mri); % perform one more time this step

%MRI reslice
cfg = [];
cfg.method = 'linear';
mri_reslice = ft_volumereslice(cfg, mri);

% MRI segmentation
cfg                = [];
cfg.brainthreshold = 0.5;
cfg.scalpthreshold = 0.05; % default is 0.1
cfg.spmmethod      = 'old';
cfg.skullthreshold = 0.5;
cfg.brainsmooth    = 5;
cfg.scalpsmooth    = 13;
cfg.skullsmooth    = 5;
cfg.output         = {'brain','skull','scalp'};
segmentedmri       = ft_volumesegment(cfg, mri_reslice);

% Source plot
segmentedmri_indexed = ft_checkdata(segmentedmri, 'segmentationstyle', 'indexed')

segmentedmri_indexed.anatomy = mri_reslice.anatomy;

cfg = [];
cfg.method = 'ortho';
cfg.anaparameter = 'anatomy';
cfg.funparameter = 'tissue';
cfg.funcolormap = [
  0 0 0
  1 0 0
  0 1 0
  0 0 1
  ];
ft_sourceplot(cfg, segmentedmri_indexed)

cfg             = [];
cfg.tissue      = {'brain','skull','scalp'};
cfg.numvertices = [3000 2000 1000];
bnd = ft_prepare_mesh(cfg,segmentedmri);

%figure;
%ft_plot_mesh(bnd(3),'facecolor','none'); %scalp
%ft_plot_mesh(bnd(2),'facecolor','none'); %skull
%ft_plot_mesh(bnd(1),'facecolor','none'); %brainw
%% 

cfg              = [];
cfg.conductivity = [1 1/8 1] * 0.33;
cfg.method       = 'bemcp'; % You can also specify 'openmeeg', 'bemcp', or another method.dipoli
vol              = ft_prepare_headmodel(cfg, bnd);
%% 

sens            = ft_read_sens('standard_1020.elc');
newsens         = ft_determine_units(sens);
labels          = {'Fp1', 'Fp2', 'F3', 'F4', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2', 'F7', 'F8', 'T3', 'T4', 'T5' 'T6', 'Fz', 'Cz', 'Pz'};
usedelec        = [1:19];
ss              = length(labels)+3;
newsens.chanpos = sens.chanpos(1:ss, :);
newsens.elecpos = sens.elecpos(1:ss, :);
newsens.label   = sens.label(1:ss);
newsens.chantype = sens.chantype(1:ss);
newsens.chanunit = sens.chanunit(1:ss);
strlabel = lower(string(sens.label));

for i = 1:length(labels)
    nameA = lower(labels{i});
    ix = find(nameA == strlabel);
    newsens.chanpos(i+ 3, :)= sens.chanpos(ix, :);
    newsens.elecpos(i+3, :)= sens.elecpos(ix, :);
    newsens.label(i+3) =sens.label(ix);
end

vox_Nas = mri.cfg.fiducial.nas;  % fiducials saved in mri structure
vox_Lpa = mri.cfg.fiducial.lpa;
vox_Rpa = mri.cfg.fiducial.rpa;
vox2head = mri.transform; % transformation matrix of individual MRI

% transform voxel indices to MRI head coordinates
head_Nas = ft_warp_apply(vox2head, vox_Nas, 'homogenous'); % nasion
head_Lpa = ft_warp_apply(vox2head, vox_Lpa, 'homogenous'); % Left preauricular
head_Rpa = ft_warp_apply(vox2head, vox_Rpa, 'homogenous'); % Right preauricular

elec_mri.chanpos = [head_Nas;head_Lpa; head_Rpa];
elec_mri.elecpos = [head_Nas;head_Lpa; head_Rpa];
elec_mri.label   = {'Nz', 'LPA', 'RPA'};
elec_mri.unit    = 'mm';

cfg          = [];
cfg.method   = 'fiducial';
cfg.template = elec_mri;
cfg.elec     = newsens;
cfg.fiducial = {'Nz', 'LPA', 'RPA'};
elec_new     = ft_electroderealign(cfg);

cfg           = [];
cfg.method    = 'interactive';
cfg.elec      = elec_new;
cfg.headshape = vol.bnd(3);
elec_new1     = ft_electroderealign(cfg);

cfg           = [];
cfg.method    = 'project';
cfg.elec      = elec_new1;
cfg.headshape = vol.bnd(3);
elec_new1     = ft_electroderealign(cfg);

figure;
ft_plot_sens(elec_new1,  'label', 'on');
hold on;
ft_plot_mesh(vol.bnd(3),'facealpha', 1, 'edgecolor', 'none', ...
    'facecolor', [0.65 0.65 0.65]); %scalp

elec_new1.chanpos   = elec_new1.chanpos(4:end, :);
elec_new1.chantype  = elec_new1.chantype(4:end);
elec_new1.chanunit  = elec_new1.chanunit(4:end);
elec_new1.elecpos   = elec_new1.elecpos(4:end, :);
elec_new1.label     = elec_new1.label(4:end);

cfg                 = [];
cfg.resolution      = 5; %in mm
cfg.headmodel       = vol;
cfg.inwardshift     = 5; %shifts dipoles away from surfaces
sourcemodel         = ft_prepare_sourcemodel(cfg);
%% 

%elec_new1 = rmfield(elec_new1, 'tra');
[headmodel_fem_eeg_tr, elec] = ft_prepare_vol_sens(vol, elec_new1);

cfg               = [];
cfg.sourcemodel   = sourcemodel;
cfg.headmodel     = headmodel_fem_eeg_tr;
cfg.elec          = elec;
cfg.reducerank    = 3;
cfg.backproject   = 'no';
leadfield_bem_eeg = ft_prepare_leadfield(cfg);

leadfdc = leadfield_bem_eeg;

figure; hold on;
ft_plot_mesh(vol.bnd(1), 'edgecolor', 'none'); %scalp
alpha 0.5;  camlight;
ft_plot_mesh(leadfdc.pos(leadfdc.inside,:));

insideix = find(leadfdc.inside==1);
LFmatrix = zeros([length(leadfdc.label), sum(leadfdc.inside) * 3]);
index = insideix;
for i = 1:length(insideix)
    ix = insideix(i);
    temp = leadfdc.leadfield{ix};
    LFmatrix(:, ((i-1)* 3+1) : (3 * i)) = temp;
end

for i=1:size(LFmatrix,2)
    LFmatrix(:,i) = LFmatrix(:,i)./sqrt(sum(LFmatrix(:,i).^2));
end

leadfdc.label(1:length(labels))= strcat('E',  leadfdc.label(1:length(labels)));
elec.label = leadfdc.label(1:length(labels));
%% Inspect EEG and determine peak times 

dir_path= 'C:\Users\gvelasquez\Documents\Source_localization_Fei\dataset\';
mat_edf_path = 'preprocessed_4e82a717d9fc8134f52f72c715411a98ac23b31e7d2d1700ec2795729b123960_20180625_142953.mat';
[data_fieldtrip] = fun_mat_2_edf(dir_path,mat_edf_path);

cfg             = [];
ft_databrowser(cfg, data_fieldtrip);

%% topography for each spike

%peak_time = [48.6 49.7;149.5 151.3;353 355;549 550.5;561 562];
peak_time = [35 44];

for p_i=1:1:size(peak_time,1)
    
    cfg             = [];
    cfg.toilim      = [peak_time(p_i,1) peak_time(p_i,2)]; % selected time interval to segment the data
    raw_eeg_data    = ft_redefinetrial(cfg, data_fieldtrip);
    
    raw_eeg_data1=raw_eeg_data;
    
    cfg = [];
    artf = ft_databrowser(cfg, raw_eeg_data);
    
    %% Replace the names of the EEG files
    raw_eeg_data1.label{1, 8} ='T7'; % T3
    raw_eeg_data1.label{1, 12}='T8'; % T4
    raw_eeg_data1.label{1, 13}='P7'; % T5
    raw_eeg_data1.label{1, 17}='P8'; % T6

    
    % visually inspect the data
    cfg            = [];
    cfg.viewmode   = 'vertical';
    cfg.blocksize  = 10;
    ft_databrowser(cfg, raw_eeg_data1);
    image_name =strcat(num2str(peak_time(p_i,1)),'_',num2str(peak_time(p_i,2)),'eeg','.png');
    image_name_full = fullfile(Folder2Save,image_name);
    saveas(gcf,image_name_full)
    
    %%
    cfg = [];
    cfg.demean = 'yes';
    cfg.baselinewindow = 'all';
    
    demeaned_data = ft_preprocessing(cfg, raw_eeg_data1);
    
    cfg = [];
    cfg.method = 'wavelet';
    cfg.foilim = [1 40];
    cfg.toi = peak_time(p_i,1):0.005:peak_time(p_i,2);
    cfg.width = 7;
    cfg.pad = 'nextpow2';
    
    tfr = ft_freqanalysis(cfg, demeaned_data);
    %% topography plot
    cfg = [];
    cfg.ylim = [1 40]; % Hz
    cfg.xlim = [peak_time(p_i,1) peak_time(p_i,2)]; % s
    cfg.parameter = 'powspctrm';
    cfg.baselinetype = 'absolute';
    cfg.layout = 'EEG1020.lay';
    figure; ft_topoplotTFR(cfg,tfr); colorbar
    image_name =strcat(num2str(peak_time(p_i,1)),'_',num2str(peak_time(p_i,2)),'topoplotTFR','.png');
    image_name_full = fullfile(Folder2Save,image_name);
    saveas(gcf,image_name_full)
    
    
    Y_tot = raw_eeg_data.trial{1, 1};
    
    %%%you will need to do data processing including filtering, decimate, etc. You will also need to select a period of time instead of using entire sequence.
    Y_tot = detrend(transpose(Y_tot));
    Y_tot = transpose(Y_tot);
    y = transpose(Y_tot);
    sigu_init =norm(transpose(y)*y)*eye(size(y,2))*1e-6;
    %Y_tot = Y_tot(:, 1:100);
    [gamma,x_ChangHeteroChamp_ori,w,c,LK_ChampCC1,noise_hetero] = champ_noise_up(Y_tot, LFmatrix, sigu_init,80, 1,   0,  1,  0, 0,0, 1e-16);
    apower1 = zeros((size(x_ChangHeteroChamp_ori, 1)/3), (size(x_ChangHeteroChamp_ori, 2)));
    apower2 = apower1;
    apower3 =apower1;
    
    for i = 1:(size(x_ChangHeteroChamp_ori, 1)/3)
        apower1(i, :)= x_ChangHeteroChamp_ori((3 * (i-1) + 1), :); ...
            apower2(i, :)= x_ChangHeteroChamp_ori((3 * (i-1) + 2), :); ...
            apower3(i, :)= x_ChangHeteroChamp_ori((3 * (i-1) + 3), :); ...
            
    end
    
    avgpower = (apower1.^2 + apower2.^2 + apower3.^2)/3;
    maxpower = sum(avgpower, 2);
    dirpower = [sum(apower1.^2, 2) sum(apower2.^2, 2) sum(apower3.^2, ...
        2)];
    dirpower = dirpower/max(max(dirpower));
    
    no_of_sources=100;
    stime = 1:size(avgpower, 2);
    [B, I1] = sort(-sum(avgpower(:, :), 2));
    selectpower = [apower1(I1(1:2), :); apower2(I1(1:2), :); apower3(I1(1:2), :)];
    leadfdc.pos(index(I1(1:no_of_sources)), :) %* 100
    plot(transpose(avgpower(I1(1:2), :)))
    
    
    
    %% Plot source with maximum power
    cfg = [];
    cfg.locationcoordinates = 'head';
    cfg.location = leadfdc.pos(index(I1(1:no_of_sources)), :);
    cfg.location  = cfg.location(1,:);
    ft_sourceplot(cfg,mri);
    image_name =strcat(num2str(peak_time(p_i,1)),'_',num2str(peak_time(p_i,2)),'sourceplot','.png');
    image_name_full = fullfile(Folder2Save,image_name);
    saveas(gcf,image_name_full);
    
   
    %% plot 10 sources on brain
    
    figure; hold on;
    ft_plot_mesh(vol.bnd(1), 'edgecolor', 'none','vertexsize',2); %scalp
    alpha 0.1; camlight;
    ft_plot_mesh(leadfdc.pos(leadfdc.inside,:),'vertexsize',2);
    loca=leadfdc.pos(index(I1(1:no_of_sources)), :);
    plotColors = hsv(no_of_sources);
    for i=1:1:no_of_sources
        x=loca(i,1);
        y=loca(i,2);
        z=loca(i,3);
        p=plot3(x,y,z,'o','Color',[plotColors(i,1),plotColors(i,2),plotColors(i,3)]);
        p.LineWidth = 3;
        str= string(num2str(i));
        textscatter3(x,y+2,z,str,'FontWeight','bold');
    end
    image_name =strcat(num2str(peak_time(p_i,1)),'_',num2str(peak_time(p_i,2)),'10_sources','.png');
    image_name_full = fullfile(Folder2Save,image_name);
    saveas(gcf,image_name_full);
    
    
    
end

