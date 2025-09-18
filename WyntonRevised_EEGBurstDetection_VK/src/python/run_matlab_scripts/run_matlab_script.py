import os
import sys

def run_script(code_folder, script_path, script_name, run_id):
    # matlab_prefix = "/afs/csail.mit.edu/system/common/etc/environment/sh/"
    matlab_command = "matlab -nodisplay -nosplash -nodesktop -r \"{}; {}; exit\" > output.txt &"
    matlab_command = "(matlab -nodisplay -nosplash -nodesktop -r \"{}; {}; exit\") 2>&1 | tee -a {}{}.log" 

    addpath_command = "addpath(genpath({}))".format(code_folder)
    runscript_command = "run({})".format(script_path)
    print(matlab_command.format(addpath_command, runscript_command, script_name, run_id))
    os.system(matlab_command.format(addpath_command, runscript_command, script_name, run_id))
    print(matlab_command.format(addpath_command, runscript_command, script_name, run_id))
    print('Done :)')


if __name__ == "__main__":

    # runs a matlab script in the repo

    # change code_folder and script_dir as necessary.

    # first argument is path to matlab script file which you want to run, relative to 'script_dir'
    # second argument (optional) specifies the run tag (run_id), so output is written to 'run_{script_name}{run_id}.log'

    # location of all the matlab source code
    code_folder = "'/wynton/group/lee/ICARE_Burst_Detection/EEGBurstDetection/src/matlab'"
    # location of the matlab scripts
    script_dir = "/wynton/group/lee/ICARE_Burst_Detection/EEGBurstDetection/src/matlab/scripts"

    script_file = sys.argv[1]

    if len(sys.argv) > 2:
        run_id = sys.argv[2]
    else:
        run_id = ''

    script_path = "\'{}/{}\'".format(script_dir, script_file)

    script_name = os.path.splitext(os.path.basename(script_file))[0]
    run_script(code_folder, script_path, script_name, run_id)
