import os

def run_merging(patientfiles_folder, code_folder, output_folder, n_workers):
    # Run the merging matlab script.

    # matlab -nodisplay -nosplash -nodesktop -r "<commands>"
    # merge_segments_to_patients( patientfiles_folder, code_folder, output_folder )
    matlab_command = "nohup matlab -nodisplay -nosplash -nodesktop -r \"{}; {}; exit\" > /home/ubuntu/outputs/output.txt &"
    addpath_command = "addpath(genpath({}))".format(code_folder)
    merge_segments_command = "merge_segments_to_patients({}, {}, {})".format(patientfiles_folder, output_folder, n_workers)
    os.system(matlab_command.format(addpath_command, merge_segments_command))
    print(matlab_command.format(addpath_command, merge_segments_command))


if __name__ == "__main__":

    patientfiles_folder = "\'/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-dataset/patients-internal-timestamp/\'"
    code_folder = "\'/afs/csail.mit.edu/u/a/adepalma/Documents/EEG-code/\'"
    output_folder = "\'/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-merged-dataset/\'"
    n_workers = 10 # To ensure we don't run out of memory (conservative).

    run_merging(patientfiles_folder, code_folder, output_folder, n_workers)
