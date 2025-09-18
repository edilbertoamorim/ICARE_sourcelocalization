import os

def run_conversion(merged_folder, code_folder, output_folder):
    # Run the mat conversion matlab script.

    # matlab -nodisplay -nosplash -nodesktop -r "<commands>"
    # merge_segments_to_patients( patientfiles_folder, code_folder, output_folder )
    matlab_command = "nohup matlab -nodisplay -nosplash -nodesktop -r \"{}; {}; exit\" > /home/ubuntu/outputs/convertout.txt &"
    addpath_command = "addpath(genpath({}))".format(code_folder)
    conversion_command = "convert_mat_to_new_format({}, {})".format(merged_folder, output_folder)
    os.system(matlab_command.format(addpath_command, conversion_command))
    print(matlab_command.format(addpath_command, conversion_command))


if __name__ == "__main__":

    merged_folder = "\'/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-merged-dataset/\'"
    code_folder = "\'/afs/csail.mit.edu/u/a/adepalma/Documents/EEG-code3/\'"
    output_folder = "\'/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-merged-dataset/MGH/\'"

    run_conversion(merged_folder, code_folder, output_folder)
