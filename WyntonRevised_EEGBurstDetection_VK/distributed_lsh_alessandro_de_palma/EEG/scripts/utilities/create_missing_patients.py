"""
Creates a file with the patients that still have to be merged, given an output file of merge_segments_to_patients.m.
"""

import os

def create_missing_patients(outname, patientfiles_folder):

    done = set()
    total = set()

    os.system("grep \"Terminated patient\" {} > done.txt".format(outname))
    with open("done.txt", "r") as file:
        for line in file:
            linesplit = line.split(" patient")
            done.add(linesplit[1].strip())

    os.system("find {} -print | grep \"patient_\" > total.txt".format(patientfiles_folder))
    with open("total.txt", "r") as file:
        for line in file:
            total.add(line.strip())

    missing = total - done
    with open("missing_list.txt", "w") as file:
        for element in missing:
            print(element, file=file)

    return

if __name__ == "__main__":

    outname = "/home/ubuntu/outputs/outputyale.txt"
    patientfiles_folder = '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-dataset/patients-internal-timestamp/yale/'

    create_missing_patients(outname, patientfiles_folder)
