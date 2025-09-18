%% clear variables

clc
clear
close all

%% addpath fieldtrip

addpath  C:\Users\gvelasquez\Documents\MATLAB\fieldtrip-20230716
ft_defaults

%% Read MRI and determine coordinate system

PID = 'YNH30';
mri =ft_read_mri([PID '_T1_w.nii.gz']);

% cfg = [];
% ft_sourceplot(cfg, mri);

mri = ft_determine_coordsys(mri);

%% Aligh MRI to CTF coordinate system

cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'ctf';
mri_realigned  = ft_volumerealign(cfg,mri);

cfg = [];
ft_sourceplot(cfg, mri_realigned);
%% Reslice MRI
cfg = [];
cfg.method = 'linear';
mri_reslice = ft_volumereslice(cfg, mri_realigned);

cfg = [];
cfg.method = 'ortho';
ft_sourceplot(cfg, mri_reslice)

%% segmentation of brain 

cfg           = [];
cfg.brainthreshold = 0.5;
cfg.scalpthreshold = 0.05;%default is 0.1
cfg.spmmethod = 'old';
cfg.skullthreshold = 0.5;
cfg.brainsmooth   = 5;
cfg.scalpsmooth    = 5;
cfg.skullsmooth = 5;
cfg.output    = {'brain','skull','scalp'};
segmentedmri  = ft_volumesegment(cfg, mri_reslice);

disp(segmentedmri)

segmentedmri_indexed = ft_checkdata(segmentedmri, 'segmentationstyle', 'indexed')

disp(segmentedmri_indexed)

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
  
%% Prepare Mesh
cfg=[];
cfg.tissue={'brain','skull','scalp'};
cfg.numvertices = [3000 2000 1000];
bnd = ft_prepare_mesh(cfg,segmentedmri);

figure
ft_plot_mesh(bnd(3), 'facecolor',[0.2 0.2 0.2], 'facealpha', 0.3, 'edgecolor', [1 1 1], 'edgealpha', 0.05);
hold on;
ft_plot_mesh(bnd(2),'edgecolor','none','facealpha',0.4);
hold on;
ft_plot_mesh(bnd(1),'edgecolor','none','facecolor',[0.4 0.6 0.4]);

%% Create head model

cfg        = [];
cfg.conductivity = [1 1/8 1] * 0.33;
cfg.method ='bemcp'; % You can also specify 'openmeeg', 'bemcp', or another method.dipoli
headmodel        = ft_prepare_headmodel(cfg, bnd);

disp(headmodel)

%% Align electrodes to head model
elec = ft_read_sens('standard_1020.elc');

disp(elec)

elec = ft_determine_coordsys(elec)

cfg = [];
cfg.method = 'volume';
cfg.channel = {'nas', 'ini', 'lpa', 'rpa'};
fiducials = ft_electrodeplacement(cfg, mri_reslice);

cfg = [];
cfg.tissue      = 'scalp';
cfg.numvertices = 10000;
scalp = ft_prepare_mesh(cfg, segmentedmri);

cfg           = [];
cfg.method    = '1020';
cfg.fiducial.nas = fiducials.elecpos(1,:);
cfg.fiducial.ini = fiducials.elecpos(2,:);
cfg.fiducial.lpa = fiducials.elecpos(3,:);
cfg.fiducial.rpa = fiducials.elecpos(4,:);
elec_placed = ft_electrodeplacement(cfg, scalp);

%% Source model

% elec_new1.chanpos = elec_new1.chanpos(4:end, :);
% elec_new1.chantype = elec_new1.chantype(4:end);
% elec_new1.chanunit = elec_new1.chanunit(4:end);
% elec_new1.elecpos = elec_new1.elecpos(4:end, :);
% elec_new1.label = elec_new1.label(4:end);

%cfg = [];
%cfg.channel = elec_placed.label(4:end);
%elec_placed = ft_selectdata(cfg, elec_placed);

cfg                 = [];
cfg.resolution = 5; %in mm
cfg.headmodel       = headmodel
cfg.inwardshift     =5; %shifts dipoles away from surfaces
sourcemodel         = ft_prepare_sourcemodel(cfg);

%%

figure
hold on
ft_plot_headmodel(headmodel, 'facecolor', 'cortex', 'edgecolor', 'none');alpha 0.5; camlight;
ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));

%% prepare leadfield 
[headmodel_fem_eeg_tr, elec] = ft_prepare_vol_sens(headmodel, elec_placed);
cfg               = [];
cfg.sourcemodel          = sourcemodel;
cfg.headmodel     = headmodel_fem_eeg_tr;
cfg.elec          = elec;
cfg.reducerank    = 3;
cfg.backproject = 'no';
leadfield_bem_eeg = ft_prepare_leadfield(cfg);

leadfdc = leadfield_bem_eeg;
%% 

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

%leadfdc.label(1:length(labels))= strcat('E',  leadfdc.label(1:length(labels)));
%elec.label = leadfdc.label(1:length(labels));

%%%load time series data
Y_tot=load('preprocessed_28_68f2c833dbd35ffb062b43aa9a9b350c0a349631ae0f4be88547c87c60a63b1c_20131016_071324.edf.mat')

% %%%you will need to do data processing including filtering, decimate, etc. You will also need to select a period of time instead of using entire sequence.
 Y_tot = detrend(transpose(Y_tot));
 Y_tot = transpose(Y_tot);
 y = transpose(Y_tot);
 sigu_init =norm(transpose(y)*y)*eye(size(y,2))*1e-6;
% [gamma,x_ChangHeteroChamp_ori,w,c,LK_ChampCC1,noise_hetero] = champ_noise_up(Y_tot, LFmatrix, sigu_init,80,nd = 1,  vcs = 0,  plot_on = 1, coup= 0, noup=0,ncf = 0, 1e-6);
% apower1 = zeros((size(x_ChangHeteroChamp_ori, 1)/3), (size(x_ChangHeteroChamp_ori, 2)));
% apower2 = apower1;
% apower3 =apower1;
%
% for i = 1:(size(x_ChangHeteroChamp_ori, 1)/3)
% 	  apower1(i, :)= x_ChangHeteroChamp_ori((3 * (i-1) + 1), :); ...
% apower2(i, :)= x_ChangHeteroChamp_ori((3 * (i-1) + 2), :); ...
% apower3(i, :)= x_ChangHeteroChamp_ori((3 * (i-1) + 3), :); ...
%
% end
%
% avgpower = (apower1.^2 + apower2.^2 + apower3.^2)/3;
% maxpower = sum(avgpower, 2);
% dirpower = [sum(apower1.^2, 2) sum(apower2.^2, 2) sum(apower3.^2, ...
% 						      2)];
% dirpower = dirpower/max(max(dirpower));
%
% stime = 1:size(avgpower, 2);
% [B, I1] = sort(-sum(avgpower(:, :), 2));
% selectpower = [apower1(I1(1:2), :); apower2(I1(1:2), :); apower3(I1(1:2), :)];
% leadfd.pos(index(I1(1:20)), :) %* 100
% plot(transpose(avgpower(I1(1:2), :)))
% cfg = [];
% cfg.locationcoordinates = 'head'
% cfg.location = leadfd.pos(index(I1(1:20)), :)
% cfg.location  = cfg.location(1,    :)
% ft_sourceplot( cfg, mri)
