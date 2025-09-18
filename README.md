# EEG Burst Source Localization Pipeline

WARNING : Pipleine in development. (Some scripts might not be optimised)
 
## Overview
This repository contains a pipeline for detecting EEG bursts, extracting burst ranges, performing source localization / reconstruction and ROI-based analysis.  
It was developed for analyzing patient-specific EEG data and performing group-level analysis using **EEGLAB**, **FieldTrip**, and custom MATLAB scripts.

The pipeline is designed to:
- Detect EEG bursts automatically
- Extract burst time ranges
- Perform source localization using standard MRI and lead fields
- Bayesian Learning Beamforming Surce Reconstruction (SBL-BF) (IN DEVELOPMENT...)

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
├── Source_localization_files/        # Additional scripts & resources for source analysis
│
├── WyntonRevised_EEGBurstDetection_VK/  # Burst detection functions
│
├── A1_Burst_Detection.m              # Step 1: Detect bursts in raw EEG
├── A2_Burst_ranges_extraction.m      # Step 2: Extract time ranges of detected bursts
├── B1_Burst_Source_Localization.m    # Step 3: Perform source localization per burst
├── C1_Source_Reconstruction.m        # Step 4: Combine and reconstruct ROI data
├── C2_Plot_normalized_ROIs.m         # Step 5: Visualize normalized ROI data
│
└── README.md                         # This file
```

---

## Pipeline Steps

### Step 0: Setup
1. Install MATLAB (R2021b or later recommended).
2. Add EEGLAB and FieldTrip toolboxes to your working folder and MATLAB path (in code):

   addpath('eeglab2025.0.0')  
   addpath('fieldtrip-20250106')  

3. Make sure the following folders are also added to your MATLAB path:  
   - Source_localization_files  
   - WyntonRevised_EEGBurstDetection_VK  

### Step 1: Burst Detection
- Run A1_Burst_Detection.m to detect bursts from raw EEG signals.  
- **Input:** Preprocessed EEG file (e.g., in Data/ folder)  
- **Output:** Burst detection results saved in the same folder  

### Step 2: Extract Burst Ranges
- Run A2_Burst_ranges_extraction.m to extract precise start and end times of detected bursts.  
- **Input:** Output from Step 1  
- **Output:** Burst time range table for each channel  

### Step 3: Burst Source Localization
- Run B1_Burst_Source_Localization.m to perform source localization for each detected burst.  
- Uses FieldTrip functions and standard pre-computed lead fields.  
- **Input:** Burst ranges + MNI lead fields  
- **Output:** Source power estimates per burst  

> **Note:** If lead fields are not already generated, run LFmgeneration.m using mri data and adapting the electrodes to the headmodel (manually) before Step 3.

### Step 4: ROI Reconstruction
- WARNING : Development...
- Run C1_Source_Reconstruction.m to reconstruct voxels time series and compute features per ROI.  
- **Input:** Burst ranges + MNI lead fields    
- **Output:** ROI-based time series  

### Step 5: ROI Visualization
- WARNING : Development...

### Dependencies
- MATLAB (R2021b or newer)  
- EEGLAB (included in eeglab2025.0.0/)  
- FieldTrip (included in fieldtrip-20250106/)  

### Notes
- For detailed explanation of parameters, check comments inside each .m file.

## References

- Cai, C., Hashemi, A., Diwakar, M., Haufe, S., Sekihara, K., & Nagarajan, S. S. (2021). Robust estimation of noise for electromagnetic brain imaging with the Champagne algorithm. *NeuroImage*, 224, 117441. https://doi.org/10.1016/j.neuroimage.2020.117441

- Cai, C., Chen, J., Findlay, A. M., Mizuiri, D., Sekihara, K., Kirsch, H. E., & Nagarajan, S. S. (2021). Clinical validation of the Champagne algorithm for epilepsy spike localization. *Frontiers in Human Neuroscience*, 15, 642819. https://doi.org/10.3389/fnhum.2021.642819

- Cai, C., Long, Y., Ghosh, S., Hashemi, A., Gao, Y., Diwakar, M., Haufe, S., Sekihara, K., Wu, W., & Nagarajan, S. S. (2023). Bayesian adaptive beamformer for robust electromagnetic brain imaging of correlated sources in high spatial resolution. *IEEE Transactions on Medical Imaging*, 42(9), 2502–2512. https://doi.org/10.1109/TMI.2023.3256963

- Hinkley, L. B. N., Dale, C. L., Cai, C., Zumer, J., Dalal, S., Findlay, A., Sekihara, K., & Nagarajan, S. S. (2020). NUTMEG: Open source software for M/EEG source reconstruction. *Frontiers in Neuroscience*, 14, 710. https://doi.org/10.3389/fnins.2020.00710

