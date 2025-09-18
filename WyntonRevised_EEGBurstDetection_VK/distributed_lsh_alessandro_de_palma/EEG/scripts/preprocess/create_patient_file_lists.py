# The goal of this file is to create a separate file for each patient. Each of these files contains the list of files associated to that patient (one per line).

import sys
import subprocess
import collections
import os
import mne

# dataset_path = /afs/csail.mit.edu/u/a/adepalma/NFS/EEG-dataset
# output_path = /afs/csail.mit.edu/u/a/adepalma/NFS/EEG-dataset/patients

def name_sorting_criterion(s, hospital):
    """
    Sort according to the timestamps present in the filenames.
    """

    (temp, filename)  = os.path.split(s)  # Get only filename.
    splitted_name = filename.split("_")

    if hospital == "BWH":
        return splitted_name[4]

    elif hospital == "MGH":
        return splitted_name[4] + "_" + splitted_name[5]

    elif hospital == "yale":
        return splitted_name[4]

    elif hospital == "BIDMC":
        return splitted_name[4] + "_" + splitted_name[5]


def edf_sorting_criterion(s):
    """
    Sort according to the timestamps present within the files.
    """

    try:
        edf = mne.io.read_raw_edf(s)
        return edf.info['meas_date']
    except:
        return 0


def create_patients_files(dataset_path, output_path):

    find = subprocess.check_output(['find', "{}".format(dataset_path), "-print"]).decode("utf-8")
    lines = find.split("\n")
    output_lines = [x for x in lines if x.endswith(".edf")]

    BWH = [x for x in output_lines if "/bwh_" in x]  # List containing all BWH files.
    MGH = [x for x in output_lines if "/CA_MGH_" in x]  # List containing all MGH files.
    yale = [x for x in output_lines if "/ynh_" in x]  # List containing all Yale files.
    BIDMC = [x for x in output_lines if "/CA_BIDMC_" in x]  # List containing all BIMDC files.

    # Preprocess BWH files. e.g., bwh_104_4_1_20141023T134748.edf
    BWH_patients = collections.defaultdict(list)
    for segment in BWH:
        (temp, filename)  = os.path.split(segment)  # Get only filename.
        splitted_name = filename.split("_")
        BWH_patients[splitted_name[1]].append(segment)
    for patient in BWH_patients:
        f = open('{}/BWH/patient_{}'.format(output_path, patient), 'w')
        BWH_patients[patient].sort(key=lambda x: edf_sorting_criterion(x))  # Sort list of files so that they are in temporal order.
        for line in BWH_patients[patient]:
            print(line, file=f)

    # Preprocess BIMDC files. e.g., CA_BIDMC_25_1_20150518_003841.edf
    BIDMC_patients = collections.defaultdict(list)
    for segment in BIDMC:
        (temp, filename)  = os.path.split(segment)  # Get only filename.
        splitted_name = filename.split("_")
        BIDMC_patients[splitted_name[2]].append(segment)
    for patient in BIDMC_patients:
        f = open('{}/BIDMC/patient_{}'.format(output_path, patient), 'w')
        BIDMC_patients[patient].sort(key=lambda x: edf_sorting_criterion(x))  # Sort list of files so that they are in temporal order.
        for line in BIDMC_patients[patient]:
            print(line, file=f)

    # Preprocess Yale files. e.g., ynh_115_1_0_20140224T080129.edf
    yale_patients = collections.defaultdict(list)
    for segment in yale:
        (temp, filename)  = os.path.split(segment)  # Get only filename.
        splitted_name = filename.split("_")
        yale_patients[splitted_name[1]].append(segment)
    for patient in yale_patients:
        f = open('{}/yale/patient_{}'.format(output_path, patient), 'w')
        yale_patients[patient].sort(key=lambda x: edf_sorting_criterion(x))  # Sort list of files so that they are in temporal order.
        for line in yale_patients[patient]:
            print(line, file=f)

    # Preprocess MGH files. e.g., CA_MGH_sid21_10_20120416_081853.edf
    MGH_patients = collections.defaultdict(list)
    for segment in MGH:
        (temp, filename)  = os.path.split(segment)  # Get only filename.
        splitted_name = filename.split("_")
        patient_id = splitted_name[2][3:len(splitted_name[2])]
        MGH_patients[patient_id].append(segment)
    for patient in MGH_patients:
        f = open('{}/MGH/patient_{}'.format(output_path, patient), 'w')
        MGH_patients[patient].sort(key=lambda x: edf_sorting_criterion(x))  # Sort list of files so that they are in temporal order.
        for line in MGH_patients[patient]:
            print(line, file=f)


if __name__ == "__main__":

    # Input format: output_path dataset_path

    output_path = sys.argv[1]
    dataset_path = sys.argv[2]

    create_patients_files(dataset_path, output_path)
