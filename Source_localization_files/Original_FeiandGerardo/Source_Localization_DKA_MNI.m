function [pt_excel_feat] = feat_Clipping_Source_Localization(job_id)

%% Add paths
% addpath('C:/Users/afaloppa/Desktop/Source_Localization-main/eeglab2025.0.0');
% addpath('C:/Users/afaloppa/Desktop/Source_Localization-main/fieldtrip-20250106');
% addpath('C:/Users/afaloppa/Desktop/Source_Localization-main/fieldtrip-20250106/external/eeglab');
ft_defaults

%% Load Standard MNI Lead Field Matrix and Atlas Source Model
load("MNI_DKA_Standard_Lead_Field.mat");

%% Prep the data
%Inputs  % afaloppa modified
    % %Durectory containing the EEG or feature data per channel
    % dir_path_preproc=  '/wynton/protected/group/amorim-phi/Source_Localization/EEG_Data/All_Preprocessed/';
    % %Excel sheet containing the patient ID's, feature file names, and time from ROSC
    % rosc_times = readtable('Source_loc_time_ROSC_wynton.xlsx');
    % %Directory containing the feature data to be 
    % feature_dir = '/wynton/protected/home/amorim/usr/feature_results/...';

    % Directory containing the EEG or feature data per channel
    dir_path_preproc = 'C:/Users/afaloppa/Desktop/Source_Localization-main/Data/All_Preprocessed/';
    % Excel sheet containing the patient ID's, feature file names, and time from ROSC
    rosc_times = readtable('C:/Users/afaloppa/Desktop/Source_Localization-main/Source_loc_time_ROSC_wynton.xlsx');
    % Directory containing the feature data to be localized
    feature_dir = 'C:/Users/afaloppa/Desktop/Source_Localization-main/Data/feature_results/';

    %% Set upper limit for segment_hour
    max_segment_hour = 73; 
    %% Define feature name at the top
    feature_name = 'Bursts';
%Outputs
    %Output directory for source_localization data
    out_dir_source_loc = 'C:/Users/afaloppa/Desktop/Source_Localization-main/Data/source_data/';
    % Output directory for hours w/ feat data check
    out_dir_hrs = 'C:/Users/afaloppa/Desktop/Source_Localization-main/Data/feat_hours/';
    % Output directory for images of feats
    Folder2Save = 'C:/Users/afaloppa/Desktop/Source_Localization-main/Data/feat_plotted/';

    % Create output directories if they do not exist  % afaloppa modified
    if ~exist(out_dir_source_loc, 'dir'); mkdir(out_dir_source_loc); end
    if ~exist(out_dir_hrs, 'dir'); mkdir(out_dir_hrs); end
    if ~exist(Folder2Save, 'dir'); mkdir(Folder2Save); end

%%Set patient ID variable
ptid = [];
ptid = unique(rosc_times.ptid_og);

wynton_id = 1;  % afaloppa modified

%%Load ROSC Times and feature files; then create time arrays
data = [];

all_preproc_files = dir(fullfile(dir_path_preproc, '*.mat'));
%Load preprocessed file and establish time array using time from ROSC
preproc_file = all_preproc_files(wynton_id).name;
data.preproc = load(strcat(dir_path_preproc,(char(preproc_file))));
Fs = 100 % data.preproc.x.srate;
time = [];
rosc_table_index = find(contains(rosc_times.preproc_file, char(all_preproc_files(wynton_id).name)));
t_rosc = rosc_times.time_from_rosc(rosc_table_index);
for t = 1:length(data.preproc.x.data)
    seconds = t_rosc + (t/Fs);
    time(1,t) = seconds;
end

data.preproc.x.time = time;

%Load feature data
feature_files = dir(fullfile(feature_dir, '**','*.csv'));

%Find indices containing the file being processed
[~, fileName, ~] = fileparts(preproc_file);
patient_indx = find(contains({feature_files.name},fileName));

%Create table to hold feat clips
var_names = {'feat_start_index', 'feat_end_index'}; % afaloppa modified
features_table = array2table(zeros(0, 2), 'VariableNames', var_names);
for bc = 1:length(patient_indx)
    bc_indx = patient_indx(bc);
    csv_path = fullfile(feature_files(bc_indx).folder, feature_files(bc_indx).name);
    csv = readtable(csv_path);
    csv{:,:} = csv{:,:} ./ 100; %%%Assumes a sampling rate of 100
    csv{:,:} = csv{:,:} + t_rosc;
    features_table = vertcat(features_table, csv);
end
data.preproc.feature = features_table;

%% Create arrays to hold data
%Arrays for source localization data
id = {};
Preprocessed_File = {};
Hour = [];
Feat_Number = [];
Feature = {};

%Arrays for feat hours check
id_feat_hrs = {};
preproc_file_ft_hr = {};
hour_ft_hr = [];
feat_yn = [];

%% Rename ventricles in atlas.
%Cannot create structure with names '3rd-Ventricle' and '4th-Ventricle'
atlas.tissuelabel(10) = {'Third_Ventricle'};
atlas.tissuelabel(11) = {'Fourth_Ventricle'};
for i = 2:length(atlas.tissuelabel)
    roi = strrep((char(atlas.tissuelabel(i))),'-','_');
    ROI_struct.(char(roi)) = [];
end
roi_list = fieldnames(ROI_struct);

%% Loop each pateint and each feature through source localization

%Get time series range in hours
start_h = floor(min(data.preproc.x.time)/3600);
end_h = ceil(max(data.preproc.x.time)/3600);
range = end_h-start_h;

%Loop through each available hour in the time series
for t = 1:range
    segment_hour = start_h + (t-1);
    if (segment_hour < max_segment_hour) ==1
        feat_start_indx_col = data.preproc.feature.feat_start_index;
        feat_indices = find(feat_start_indx_col >= (start_h*3600 + ((t-1)*3600)) & feat_start_indx_col <= (start_h*3600 + ((t-1)*3600) + 3600));
        if isempty(feat_indices) == 0
            %Remove additional data which may make its way in
            feat_indices(feat_indices > (length(feat_start_indx_col))) = [];            
            %% Loop through the first 10 feats for this hour            
            for ft = 1:length(feat_indices)                
                feat_index_in_table = feat_indices(ft);
                %Set feat start time
                feat_start = data.preproc.feature.feat_start_index(feat_index_in_table);
                feat_start_time_indx = find(data.preproc.x.time == feat_start);
                %Set feat end time
                feat_end = data.preproc.feature.feat_end_index(feat_index_in_table);
                feat_end_time_indx = find(data.preproc.x.time == feat_end);
                %Get feat segment from preprocessed EEG data
                preproc_segment = data.preproc.x.data(:,feat_start_time_indx:feat_end_time_indx);

                %Fill in table arrays for this feature segment
                id((length(id)+1),1) = rosc_times.ptid_og(rosc_table_index);
                Preprocessed_File((length(Preprocessed_File)+1),1) = rosc_times.preproc_file(rosc_table_index);
                Hour((length(Hour)+1),1) = segment_hour;
                Feat_Number((length(Feat_Number)+1),1) = ft;
                Feature((length(Feature)+1),1) = {feature_name};

                %Fill in checks for feat hours table 
                id_feat_hrs((length(id_feat_hrs)+1),1) = rosc_times.ptid_og(rosc_table_index);
                preproc_file_ft_hr((length(preproc_file_ft_hr)+1),1) = rosc_times.preproc_file(rosc_table_index);
                hour_ft_hr((length(hour_ft_hr)+1),1) = segment_hour;
                feat_yn((length(feat_yn)+1),1) = 1;

                fprintf('Running Source Localization for Patient %s, Hour %d, feat Number %d, Feature %s. \n', char(rosc_times.ptid_og(rosc_table_index)), segment_hour, ft, char({'band_pow'}));

                %% Save plot of EEG Segment
                [data_fieldtrip] = fun_mat_2_edf(dir_path_preproc,preproc_file);
                data_fieldtrip.trial{1,1} = preproc_segment;
                data_fieldtrip.time{1,1} = data.preproc.x.time(:,feat_start_time_indx:feat_end_time_indx);

                %% Replace the names of the EEG files  % afaloppa modified
                % data_fieldtrip.label{1, 8} ='T7'; % T3
                % data_fieldtrip.label{1, 12}='T8'; % T4
                % data_fieldtrip.label{1, 13}='P7'; % T5
                % data_fieldtrip.label{1, 17}='P8'; % T6

                %Save the EEG plot
                cfg            = [];
                cfg.viewmode   = 'vertical';
                cfg.blocksize  = 10;
                ft_databrowser(cfg, data_fieldtrip);
                image_name =strcat(char(rosc_times.ptid_og(rosc_table_index)),'_Hour_',num2str(segment_hour),'_featNum_', num2str(ft),'.png');
                image_name_full = fullfile(Folder2Save,image_name);
                ui_controls = findall(gcf, 'Type', 'uicontrol');
                delete(ui_controls);
                saveas(gcf,image_name_full);

                %% Run Champagne
                
                Y_tot = preproc_segment;

                %%%you will need to do data processing including filtering, decimate, etc. You will also need to select a period of time instead of using entire sequence.
                y = transpose(Y_tot);
                sigu_init =norm(transpose(y)*y)*eye(size(y,2))*1e-6;
                %Y_tot = Y_tot(:, 1:100);
                [gamma,x_ChangHeteroChamp_ori,w,c,LK_ChampCC1,noise_hetero] = champ_noise_up(Y_tot, LFmatrix, sigu_init,80, 1,   0,  1,  0, 0,0, 1e-16);
                apower1 = zeros((size(x_ChangHeteroChamp_ori, 1)), (size(x_ChangHeteroChamp_ori, 2))); % size1 /3  % afaloppa modified
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
                leadfdc.pos(index(I1(1:no_of_sources)), :); %* 100  

                %% Create Source Model of Power Averaged over each ROI in the atlas

                %%Create avg.pow variable with NaN for those positions outside the brain
                %%avg.pow is the average power generated from the source localization
                rsource.avg.pow = NaN(length(leadfdc.pos),1);
                [C, I2] = sort(mean(avgpower(:, :), 2));
                for i = 1:length(I2)
                    temp = C(i);
                    rsource.avg.pow(index(I2(i))) = temp;
                end

                %Create inside, outside, and method variables
                rsource.inside = insideix;
                rsource.outside = find(leadfdc.inside==0);
                rsource.method = 'average';

                %dim is not very necessary
                rsourceAtlas.dim = leadfdc.dim;
                %%inside is from leadfield matrix
                rsourceAtlas.inside = rsource.inside;
                %%Outside
                rsourceAtlas.outside = rsource.outside;
                %%Method
                rsourceAtlas.method = rsource.method;
                %%pos is from leadfiled matrix
                rsourceAtlas.pos = leadfdc.pos;
                %%average power over time averaged per ROI
                rsourceAtlas.avg.pow = rsource.avg.pow;

                %%Interpolate the source model onto the mri
                cfg            = [];
                cfg.downsample = 1;
                cfg.parameter  = 'pow';
                cfg.interpmethod = 'nearest';
                %%mri_data is the mri data you use to do the source localization
                rsourceInt_atlas  =ft_sourceinterpolate(cfg, rsourceAtlas, mri);

                %%Interpolate the atlas onto the source model above
                cfg = [];
                cfg.interpmethod = 'nearest';
                cfg.parameter = 'tissue';
                sourcemodel2 = ft_sourceinterpolate(cfg, atlas, rsourceInt_atlas);

                %%Average the power of sources within each ROI
                tot_roi= length(atlas.tissuelabel);

                %Remove all voxels labeled as "Other"
                rsourceInt_atlas.pow(find(sourcemodel2.tissue==1)) = NaN;
                %Obtain mean power of the feature over each ROI, adjust the source
                %model to reflect means, and send data to ROI structure
                for i=2:tot_roi
                 x = find(sourcemodel2.tissue==i);
                 m = nanmean(rsourceInt_atlas.pow(x));
                 rsourceInt_atlas.pow(x) = m;
                 ROI_struct.(char(roi_list(i-1)))((length(ROI_struct.(char(roi_list(i-1))))+1),1) = m;
                end            
            end
        else
            %Fill in checks for feat hours table 
            id_feat_hrs((length(id_feat_hrs)+1),1) = rosc_times.ptid_og(rosc_table_index);
            preproc_file_ft_hr((length(preproc_file_ft_hr)+1),1) = rosc_times.preproc_file(rosc_table_index);
            hour_ft_hr((length(hour_ft_hr)+1),1) = segment_hour;
            feat_yn((length(feat_yn)+1),1) = 0;
        end
    end
end

%% Create table with all Feature/ROI data

%Create table with Source Localization data
Source_loc_features = table(id, Feature, Hour, Feat_Number); 
all_roi_data = struct2table(ROI_struct);
Source_loc_features = [Source_loc_features all_roi_data];

%Create table with feat hours check
feat_hours_checks = table(id_feat_hrs, preproc_file_ft_hr, hour_ft_hr, feat_yn);

%Write tables to csv
pt_excel_feat = strcat('Source_loc_band_pow_feats_', char(fileName), '.xlsx');
excel_file_sl = fullfile(out_dir_source_loc, pt_excel_feat);
writetable(Source_loc_features, excel_file_sl);

pt_excel_ft_hrs = strcat('Source_loc_feat_hours_', char(fileName), '.xlsx');
excel_file_bh = fullfile(out_dir_hrs, pt_excel_ft_hrs);
writetable(feat_hours_checks, excel_file_bh);
