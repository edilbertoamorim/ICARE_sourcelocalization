function [pt_excel] = Feature_Source_Localization_ALL(job_id)

%% Add paths
addpath  /wynton/protected/home/amorim/gvelasquez/fieldtrip-20230716/external/eeglab
addpath   /wynton/protected/home/amorim/gvelasquez/fieldtrip-20230716/
addpath   /wynton/protected/home/amorim/gvelasquez/eeglab2023.0
ft_defaults

%% Load Standard MNI Lead Field Matrix and Atlas Source Model
load("MNI_DKA_Standard_Lead_Field.mat");

%% Prep the feature data

%Directory containing the feature data per channel
dir_path_feat= '/wynton/protected/group/lee-phi/Source_Localization/MGH_EEG_preprocessed/_features_chan/';
%Output_dir
out_dir = '/wynton/protected/home/amorim/gvelasquez/Source_localization_Wynton/';
%Excel sheet containing the patient IDs, feature file names, and time from
%ROSC
rosc_times = readtable('Source_loc_time_ROSC_wynton_MGH.xlsx');

%%Load ROSC Times and feature files; then create time arrays
data = [];

for i = 1:length(rosc_times.feature_file)
    data.feature_og(i,1) = load(strcat(dir_path_feat,char(rosc_times.feature_file(i))));
    time = [];
    t_rosc = rosc_times.time_from_rosc(i);
    
    for t = 1:length(data.feature_og(i).x.BCI)
        seconds = t_rosc + (10*t);
        time(1,t) = seconds;
    end
    
    data.feature_og(i).x.time = time;
end

%%Concatenate feature data for each patient
ptid = [];
ptid = unique(rosc_times.ptid_og);
for i = job_id
    %Find indices containing the files for a single patient
    patient_indx = find(strcmp(rosc_times.ptid_og,ptid(i)));
    %Create structure containing all feature data for a single patient
    for f = 1:length(patient_indx)
        all_pt_data(f) = data.feature_og(patient_indx(f));
    end
    %Obtain list of features to loop through and concatonate into data
    %structure
    features_list = fieldnames(all_pt_data(1).x);
    for f = 2:length(features_list)
        data.features.(char(ptid(i))).(char(features_list(f))) = all_pt_data(1).x.(char(features_list(f)));
        if length(all_pt_data)>=2
            for x = 2:length(all_pt_data)
                data.features.(char(ptid(i))).(char(features_list(f))) = cat(2, data.features.(char(ptid(i))).(char(features_list(f))), all_pt_data(x).x.(char(features_list(f))));
            end
        end
    end
    
end

%% Create arrays to hold data
id = {};
Hour = [];
Feature = {};

%Rename ventricles in atlas. Cannot create structure with names
%'3rd-Ventricle' and '4th-Ventricle'
atlas.tissuelabel(10) = {'Third_Ventricle'};
atlas.tissuelabel(11) = {'Fourth_Ventricle'};
for i = 2:length(atlas.tissuelabel)
    roi = strrep((char(atlas.tissuelabel(i))),'-','_');
    ROI_struct.(char(roi)) = [];
end
roi_list = fieldnames(ROI_struct);

%% Loop each pateint and each feature through source localization

for p = job_id
    %Get time series range in hours
    start_h = round(min(data.features.(char(ptid(p))).time)/3600);
    end_h = round(max(data.features.(char(ptid(p))).time)/3600);
    range = end_h-start_h-1;
    %Loop through each available hour in the time series
    for t = 1:range
        segment_hour = start_h + (t-1);
        time_index = find(data.features.(char(ptid(p))).time >= (start_h*3600 + ((t-1)*3600)) & data.features.(char(ptid(p))).time <= (start_h*3600 + ((t-1)*3600) + 3600));
        if isempty(time_index) == 0
            for f = 2:(length(features_list)-1)
                time_index(time_index > (length(data.features.(char(ptid(p))).(char(features_list(f)))))) = [];
                feat_segment = data.features.(char(ptid(p))).(char(features_list(f)))(:,time_index);
                %Fill in table arrays for this feature segment
                id((length(id)+1),1) = ptid(p);
                Hour((length(Hour)+1),1) = segment_hour;
                Feature((length(Feature)+1),1) = features_list(f);
                fprintf('Running Source Localization for Patient %s, Hour %d, Feature %s. \n', char(ptid(p)), segment_hour, char(features_list(f)));

                %% Run Champagne

                Y_tot = feat_segment;

                %%%you will need to do data processing including filtering, decimate, etc. You will also need to select a period of time instead of using entire sequence.
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

                %% Create Source Model of Power Averaged over each ROI in the atlas

                %%Create avg.pow variable with NaN for those positions outside the brain
                %%avg.pow is the average power generated from the source localization
                rsource.avg.pow = NaN(length(leadfdc.pos),1);
                [C, I2] = sort(mean(avgpower(:, :), 2));
                for i = 1:length(I2);
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
        end
    end
end

%% Create table with all Feature/ROI data
Source_loc_features = table(id, Feature, Hour); 
all_roi_data = struct2table(ROI_struct);
Source_loc_features = [Source_loc_features all_roi_data];
pt_excel = strcat('Source_loc_feature_data_ALL_', char(ptid(job_id)), '.xlsx');
excel_file = fullfile(out_dir, pt_excel);
writetable(Source_loc_features, excel_file);
