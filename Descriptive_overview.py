#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan  5 10:49:54 2026

@author: alexfaloppa
"""

import os
import re
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from collections import defaultdict


# ---------------------------------------------------------------------
# %% Configuration
# ---------------------------------------------------------------------

# Hour limits (inclusive)
HOUR_MIN = 0
HOUR_MAX = 72  # set None to disable upper bound

# Consistency filtering parameters
CONSISTENCY_MIN = 0.0   # require >= 80% coverage
MIN_HOURS = 3           # minimum number of available hours

BASE_DIR = "./Data/OUTPUT/Source_Reconstruction/"
FEATURE_SUBDIR = "03_FeaturesCHAN"

# Regex to extract hour from filename
RE_HOUR = re.compile(r"_H(\d+)_")


# ---------------------------------------------------------------------
# %% Containers
# ---------------------------------------------------------------------

rows_hourly = []
patient_hours = defaultdict(set)


# ---------------------------------------------------------------------
# %% Main parsing loop
# ---------------------------------------------------------------------

for patient_id in sorted(os.listdir(BASE_DIR)):
    patient_path = os.path.join(BASE_DIR, patient_id)

    if not os.path.isdir(patient_path):
        continue

    feat_path = os.path.join(patient_path, FEATURE_SUBDIR)
    if not os.path.isdir(feat_path):
        continue

    for fname in os.listdir(feat_path):
        if not fname.endswith(".csv"):
            continue

        m = RE_HOUR.search(fname)
        if m is None:
            continue

        hour = int(m.group(1))

        if hour < HOUR_MIN:
            continue
        if HOUR_MAX is not None and hour > HOUR_MAX:
            continue

        fpath = os.path.join(feat_path, fname)

        try:
            df = pd.read_csv(fpath)
        except Exception:
            continue

        # final_label (categorical)
        if "final_label" in df.columns:
            label_mode = df["final_label"].dropna().mode()
            final_label_mode = label_mode.iloc[0] if not label_mode.empty else np.nan
        else:
            final_label_mode = np.nan

        # BCI (numerical)
        if "BCI_value" in df.columns:
            bci_mean_hour = df["BCI_value"].dropna().mean()
        else:
            bci_mean_hour = np.nan

        rows_hourly.append(
            {
                "patient_id": patient_id,
                "hour": hour,
                "final_label_mode": final_label_mode,
                "bci_mean_hour": bci_mean_hour,
            }
        )

        patient_hours[patient_id].add(hour)


# ---------------------------------------------------------------------
# %% Hour-level dataframe
# ---------------------------------------------------------------------

df_hourly = (
    pd.DataFrame(rows_hourly)
    .sort_values(["patient_id", "hour"])
    .reset_index(drop=True)
)


# ---------------------------------------------------------------------
# %% Patient-level summary
# ---------------------------------------------------------------------

rows_summary = []

for patient_id, hours in patient_hours.items():
    hours = sorted(hours)

    if not hours:
        continue

    min_h = min(hours)
    max_h = max(hours)

    data_length = len(hours)
    hour_span = max_h - min_h + 1
    gaps = hour_span - data_length
    consistency = data_length / hour_span if hour_span > 0 else np.nan

    labels_patient = (
        df_hourly
        .loc[df_hourly["patient_id"] == patient_id, "final_label_mode"]
        .dropna()
    )
    patient_label = labels_patient.mode().iloc[0] if not labels_patient.empty else np.nan

    bci_patient = (
        df_hourly
        .loc[df_hourly["patient_id"] == patient_id, "bci_mean_hour"]
        .dropna()
        .mean()
    )

    rows_summary.append(
        {
            "patient_id": patient_id,
            "data_length": data_length,
            "gaps": gaps,
            "consistency": consistency,
            "patient_final_label_mode": patient_label,
            "patient_bci_mean": bci_patient,
        }
    )

df_patient_summary = (
    pd.DataFrame(rows_summary)
    .sort_values("patient_id")
    .reset_index(drop=True)
)


# ---------------------------------------------------------------------
# %% Filter patients
# ---------------------------------------------------------------------

df_patient_filtered = (
    df_patient_summary
    .loc[
        (df_patient_summary["consistency"] >= CONSISTENCY_MIN) &
        (df_patient_summary["data_length"] >= MIN_HOURS)
    ]
    .reset_index(drop=True)
)

df_patient_filtered.to_csv(
    "analyze_patients_list_new.csv",
    index=False
)

filtered_patient_ids = set(df_patient_filtered["patient_id"])


# ---------------------------------------------------------------------
# %% Plotting helper function
# ---------------------------------------------------------------------

def plot_raster_and_hist(
    completed_hours,
    title_suffix,
    output_png
):
    """
    Inputs
    ------
    completed_hours : dict
        patient_id -> sorted list of hours
    title_suffix : str
        Label added to plot titles
    output_png : str
        Output filename

    Output
    ------
    Saves raster + histogram figure to disk with summary info
    """

    patient_ids = sorted(completed_hours.keys(), key=lambda x: int(x))
    y_positions = {pid: i for i, pid in enumerate(patient_ids)}

    all_hours = [h for hrs in completed_hours.values() for h in hrs]
    max_hour = max(all_hours) if all_hours else 0

    n_patients = len(patient_ids)
    total_datapoints = len(all_hours)

    fig, (ax_raster, ax_hist) = plt.subplots(
        2, 1,
        figsize=(12, 6),
        sharex=True,
        gridspec_kw={"height_ratios": [2, 1]}
    )

    palette = sns.color_palette("tab20", n_colors=n_patients)
    patient_colors = {pid: palette[i] for i, pid in enumerate(patient_ids)}

    # Raster plot
    for pid, hours in completed_hours.items():
        y = y_positions[pid]
        color = patient_colors[pid]
        for h in hours:
            ax_raster.plot(
                [h - 0.4, h + 0.4],
                [y, y],
                linewidth=1,
                color=color
            )

    ax_raster.set_ylabel("patient index")
    ax_raster.set_xlim(0, max_hour + 1)
    ax_raster.set_title(f"available eeg hours per patient ({title_suffix})")

    # Downsample y labels
    n_labels = min(10, len(patient_ids))
    label_indices = np.linspace(0, len(patient_ids) - 1, n_labels, dtype=int)
    ax_raster.set_yticks(label_indices)
    ax_raster.set_yticklabels([int(patient_ids[i]) for i in label_indices])

    # Vertical 6-hour grid
    for ax in (ax_raster, ax_hist):
        for h in np.arange(0, max_hour + 1, 6):
            ax.axvline(h, linewidth=0.5, linestyle="--", alpha=0.4)

    # Summary info (patients and datapoints)
    ax_raster.text(
        0.99, 0.01,
        f"Number of Patients: {n_patients}\n"
        f"Number of Datapoints: {total_datapoints}",
        transform=ax_raster.transAxes,
        ha="right",
        va="bottom",
        fontsize=9,
        bbox=dict(boxstyle="round", facecolor="white", alpha=0.8)
    )

    # Histogram
    sns.histplot(
        x=all_hours,
        ax=ax_hist,
        binwidth=1,
        stat="count",
        edgecolor="black",
        linewidth=0.5
    )

    ax_hist.set_xlabel("hour")
    ax_hist.set_ylabel("count")
    ax_hist.set_title(f"distribution of available eeg hours ({title_suffix})")

    sns.despine()
    plt.tight_layout()
    plt.savefig(output_png, dpi=150, bbox_inches="tight")
    plt.close(fig)



# ---------------------------------------------------------------------
# %% Plot: ALL patients
# ---------------------------------------------------------------------

completed_hours_all = {
    pid: sorted(hours) for pid, hours in patient_hours.items()
}

plot_raster_and_hist(
    completed_hours_all,
    title_suffix="all patients",
    output_png="available_eeg_hours_all_patients.png"
)


# ---------------------------------------------------------------------
# %% Plot: FILTERED patients only
# ---------------------------------------------------------------------

completed_hours_filtered = {
    pid: sorted(hours)
    for pid, hours in patient_hours.items()
    if pid in filtered_patient_ids
}

plot_raster_and_hist(
    completed_hours_filtered,
    title_suffix="filtered patients",
    output_png="available_eeg_hours_filtered_patients.png"
)
