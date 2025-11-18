

# -----------------------------------------------------------
# SurfIce Python script to:
# 1. Load mesh
# 2. Detect patient folders in OUTPUT/Source_Reconstruction
# 3. For each patient, check that 04_FeaturePlots and 05_Niftis exist and are non-empty
# 4. For each NIfTI, load overlay, take snapshots from multiple angles
# 5. Save snapshots in the 04_FeaturePlots folder with the NIfTI filename
#
# Notes:
# - Inputs: directory structure with patient_ID folders
# - Outputs: PNG snapshots for each overlay
# - No functions are defined; the script is linear and sequential
# -----------------------------------------------------------

import os
import gl

gl.resetdefaults()

# -----------------------------------------------------------
# Define folder structure relative to script location
# -----------------------------------------------------------

base_dir = "/Users/alexfaloppa/Desktop/ICARE_sourcelocalization"
data_dir = os.path.join(base_dir, "Data")
src_recon_dir = os.path.join(data_dir, "OUTPUT", "Source_Reconstruction")

nifti_sub = "05_Niftis"
plot_sub  = "04_FeaturePlots"

mesh_file = os.path.join(base_dir, r"Source_localization_files\source_on_mri_200.mz3")

# -----------------------------------------------------------
# User-defined views and colormap
# -----------------------------------------------------------

vmin = 0
vmax = 70

views = [
    (0,  90, "_S"),
    (-180,   -90, "_I"),
    (-110, 20, "_L"),
    (110,  20, "_R"),
]

colormap_name = "hot"     # example; any SurfIce LUT name is acceptable

# -----------------------------------------------------------
# Setup SurfIce display
# -----------------------------------------------------------

gl.resetdefaults()
gl.meshload(mesh_file)
gl.backcolor(255, 255, 255)   # white background
gl.overlaycloseall()

print("Base directory:", base_dir)
print("Looking for patients in:", src_recon_dir)

# -----------------------------------------------------------
# Scan patient directories
# -----------------------------------------------------------
if not os.path.isdir(src_recon_dir):
    print("ERROR: Directory not found:", src_recon_dir)
else:
    entries = os.listdir(src_recon_dir)
    patient_ids = [p for p in entries if os.path.isdir(os.path.join(src_recon_dir, p))]
    print("Found", len(patient_ids), "patient folders")

    for pid in patient_ids:

        patient_path = os.path.join(src_recon_dir, pid)
        nifti_path   = os.path.join(patient_path, nifti_sub)
        plot_path    = os.path.join(patient_path, plot_sub)

        print("\n--- Patient:", pid, "---")

        if not os.path.isdir(nifti_path):
            print("Skipping:", nifti_path, "does not exist")
            continue
        if not os.path.isdir(plot_path):
            print("Skipping:", plot_path, "does not exist")
            continue

        nii_files = [f for f in os.listdir(nifti_path) if f.endswith(".nii") or f.endswith(".nii.gz")]
        if len(nii_files) == 0:
            print("Skipping:", "no NIfTI files found in", nifti_path)
            continue

        print("Found", len(nii_files), "NIfTI files")

        if not os.path.exists(plot_path):
            os.makedirs(plot_path)

        # ---------------------------------------------------
        # Process first 4 NIfTIs
        # ---------------------------------------------------
        for nii_file in nii_files:

            nii_full = os.path.join(nifti_path, nii_file)
            print("Processing:", nii_file)

            try:
                gl.overlaycloseall()
                gl.overlayload(nii_full)
                gl.overlaycolorname(1, colormap_name)
                gl.overlayminmax(1, vmin, vmax)
            except Exception as e:
                print("ERROR loading overlay:", e)
                continue

            nii_base = nii_file.replace(".nii.gz", "").replace(".nii", "")
            out_base = os.path.join(plot_path, nii_base + "_SRF.png")

            # ---------------------------------------------------
            # Save each view separately for now
            # ---------------------------------------------------
            for az, el, suf in views:
                gl.azimuthelevation(az, el)
                out_png = out_base.replace("_SRF", "_SRF" + suf)  # add view suffix
                try:
                    gl.savebmp(out_png)
                except Exception as e:
                    print("ERROR saving PNG:", e)

            print("Saved", len(views), "views for", nii_file)
