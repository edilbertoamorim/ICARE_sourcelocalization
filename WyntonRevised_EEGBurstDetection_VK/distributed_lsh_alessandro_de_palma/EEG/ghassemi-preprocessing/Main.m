%STEP 1:CONVERT EDFs To MAT
ConvertToMat(1,1);

%STEP 2: GET THE SUBJECT IDScd 
setSubjectIds;

% -----------------------------------------------
% WE HAVE MOST OF THE CODE FROM HERE

%STEP 3: MERGE THE EDF FILES FOR EACH PATIENT INTO A SINGLE FILE.
MergeAll(1,1);
%the merger failed for these files:
%   '/nobackup1b/users/ghassemi/EEGs/CA_Merged/d_EEGIC083_all.mat'
%     '/nobackup1b/users/ghassemi/EEGs/CA_Merged/d_EEGIC114_all.mat'
%     '/nobackup1b/users/ghassemi/EEGs/CA_Merged/d_EEGIC133_all.mat'
%     '/nobackup1b/users/ghassemi/EEGs/CA_Merged/d_EEGIC176_all.mat'
%     '/nobackup1b/users/ghassemi/EEGs/CA_Merged/d_PAE030_all.mat'
%     '/nobackup1b/users/ghassemi/EEGs/CA_Merged/d_PAE059_all.mat'

%STEP 4: PRE-PROCESS THE MERGED EDFs
MAT_TO_EEGLAB(1,1);

%STEP 5: COMPUTE POPULATION FEATURES FOR OUTLIERS DETECTION.
artifact_Extract_Moments
artifact_Extract_Spectra(1,1);
COMPUTE_ARTIFACT_INDICIES;

%STEP 6: FIND THE ARTIFACTS IN THE SIGNALS
Mark_Artifacts(1,1);

%STEP 7: REEPOCH THE SIGNAL TO 5 MINS.
reEpoch(1,1);

% END OF THE CODE WE HAVE.
% -----------------------------------------------

% Alessandro: we have the code to compute the features for a single segment
% on his public repo.
%STEP 8: COMPUTE FEATURES.
computeSingleChannelFeatures
computeMultiChannelFeatures

%STEP 9: GENERATE COVARIATES TABLE
/nobackup1b/users/ghassemi/EEGs/Patinet Data/Generate_Covariates_Table_v2.m

% Alessandro: this has to do with his parallel and distributed execution of
% the code.
%STEP 10: MERGE FEATURES.
MergeFeaturesSingle
MergeFeatures
