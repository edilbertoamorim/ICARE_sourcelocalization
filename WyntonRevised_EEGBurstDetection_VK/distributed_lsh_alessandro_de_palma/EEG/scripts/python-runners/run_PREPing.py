import os

def run_PREP(merged_folder, code_folder, output_folder, eeglab_folder, n_workers):
    # Run the PREPing matlab script.

    # matlab -nodisplay -nosplash -nodesktop -r "<commands>"
    # merge_segments_to_patients( patientfiles_folder, code_folder, output_folder )
    matlab_command = "matlab -nodisplay -nosplash -nodesktop -r \"{}; {}; exit\" > /home/ubuntu/outputs/PREPoutput-MGH.txt"
    addpath_command = "addpath(genpath({}))".format(code_folder)
    PREP_command = "PREP_merged_files({}, {}, {}, {}, {})".format(merged_folder, output_folder, eeglab_folder, code_folder, n_workers)
    os.system(matlab_command.format(addpath_command, PREP_command))
    print(matlab_command.format(addpath_command, PREP_command))


if __name__ == "__main__":

    merged_folder = "\'/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-merged-dataset/MGH\'"
    code_folder = "\'/afs/csail.mit.edu/u/a/adepalma/Documents/EEG-code3/\'"
    output_folder = "\'/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/MGH/\'"
    eeglab_folder = "\'/afs/csail.mit.edu/u/a/adepalma/Documents/eeglab/eeglab14_1_1b/\'"
    n_workers = 6 # To ensure we don't run out of memory (conservative).

    run_PREP(merged_folder, code_folder, output_folder, eeglab_folder, n_workers)
