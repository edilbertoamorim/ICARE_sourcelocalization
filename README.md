# EEG Source Reconstruction Pipeline

WARNING : Pipeline in development. (Some scripts might not be optimized)
 
## Overview
This repository contains a pipeline for extracting EEG data from the I-CARE dataset, performing source reconstruction and ROI-based analysis.  
It was developed for analyzing patient-specific EEG data and performing group-level analysis using **EEGLAB**, **FieldTrip**, **wfdb-toolbox** and custom MATLAB scripts.

The pipeline is designed to:
- Generate a lead-Field forward model (A standard sample is provided)
- Extract and filter patients info from the I-CARE dataset
- Perform source reconstruction/localization using standard MRI and lead fields
- Bayesian Learning Beamforming Source Reconstruction (SBL-BF) (IN DEVELOPMENT...)

---

### Repository Structure

```
Source_localization/
│
├── Data/                             # Example EEG datasets and outputs
│
├── eeglab2025.0.0/                   # EEGLAB toolbox (required for preprocessing)
│
├── fieldtrip-20250106/               # FieldTrip toolbox (required for source localization)
│
├── wfdb-app-toolbox/                 # WFDB toolbox (required for physionet data extraction)
│
├── Source_localization_files/        # Additional scripts & resources for source analysis
│
│
├── A1_Source_Reconstruction.m        # Step 1: Process Patients Data and extract source level features
├── A2_Plot_Features.m                # Step 2: Plot Features
│
└── README.md                         # This file
```

---

## Pipeline Steps

### Step 0.1: Setup
1. Install MATLAB (R2021b or later recommended).
2. Add toolboxes to your working folder and MATLAB path (in code):

   addpath('eeglab2025.0.0')  
   addpath('fieldtrip-20250106')  
   addpath('wfdb-app-toolbox') 

3. Make sure the following folders are also added to your MATLAB path:  
   - Source_localization_files   

### Step 0.2: Files Preparation
- A standard Lead-field matrix is provided
- The file scripts/LFM_generation.m allows personalised generation of forward models starting from individual MRI data in Fieldtrip format. An atlas is also needed (sample DK Atlas provided)
- Run scripts/Get_patients_ID.m to generate the list of patients to process (this list can be filtered if needed)  

### Step 1: Process Patients
- Run A1_Source_localization.m to extract precise start and end times of detected bursts.  
- **Input:** Source_localization_files/ICARE_patient_metadata.xlsx 
- **Output:** Features and PSDs saved in Data/OUTPUT/Source_Reconstruction/<PATIENT_ID>

> **Note:** If lead fields are not already generated, run LFM_generation.m using mri data and adapting the electrodes to the headmodel (manually) before Step 1.

### Step 2: Visualize Features
- Run A2_Plot_Features.m to generate the features maps.  
- Uses FieldTrip functions and standard pre-computed lead fields.  
- **Input:** Features Table + MNI lead fields  
- **Output:** Figures in Data/OUTPUT/Source_Reconstruction/<PATIENT_ID>/04_figures
- WARNING : Development...


### Dependencies
- MATLAB (R2021b or newer)  
- EEGLAB (included in eeglab2025.0.0 - download: https://sccn.ucsd.edu/eeglab/download.php)  
- FieldTrip (included in fieldtrip-20250106 - download: https://www.fieldtriptoolbox.org/download/)  
- WFDB toolbox for Matlab (version 0.10 or above - https://github.com/ikarosilva/wfdb-app-toolbox?tab=readme-ov-file)  

### Notes
- For detailed explanation of parameters, check comments inside each .m file.
- The scripts **LFM_generation.m** and **Get_patient_IDs.m** are needed to create the resources needed in the main scripts 

## References

- Cai, C., Long, Y., Ghosh, S., Hashemi, A., Gao, Y., Diwakar, M., Haufe, S., Sekihara, K., Wu, W., & Nagarajan, S. S. (2023). Bayesian adaptive beamformer for robust electromagnetic brain imaging of correlated sources in high spatial resolution. *IEEE Transactions on Medical Imaging*, 42(9), 2502–2512. https://doi.org/10.1109/TMI.2023.3256963

- Hinkley, L. B. N., Dale, C. L., Cai, C., Zumer, J., Dalal, S., Findlay, A., Sekihara, K., & Nagarajan, S. S. (2020). NUTMEG: Open source software for M/EEG source reconstruction. *Frontiers in Neuroscience*, 14, 710. https://doi.org/10.3389/fnins.2020.00710

- Delorme, A. & Makeig, S. (2004). EEGLAB: an open-source toolbox for analysis of single-trial EEG dynamics including independent component analysis. Journal of Neuroscience Methods, 134(1): 9-21. https://doi.org/10.1016/j.jneumeth.2003.10.009

- Oostenveld, R., Fries, P., Maris, E., & Schoffelen, J.-M. (2011). FieldTrip: Open source software for advanced analysis of MEG, EEG, and invasive electrophysiological data. Computational Intelligence and Neuroscience, 2011, Article ID 156869. https://doi.org/10.1155/2011/156869

- Silva, I., Moody, B., & Moody, G. (2021). Waveform Database Software Package (WFDB) for MATLAB and Octave (version 0.10.0). PhysioNet. https://doi.org/10.13026/6zcz-e163

- Amorim, E., Zheng, W., Lee, J. W., Herman, S., Ghassemi, M., Sivaraju, A., Gaspard, N., Hofmeijer, J., van Putten, M. J. A. M., Reyna, M., Clifford, G., & Westover, B. (2023). I-CARE: International Cardiac Arrest REsearch consortium Database (version 2.1). PhysioNet. RRID:SCR_007345. https://doi.org/10.13026/m33r-bj81

