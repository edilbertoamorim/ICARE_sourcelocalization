# Quick start guide for how to run the entire pipeline and create the figures seen in the thesis:
## Run the pipeline in MATLAB
See section C.2.2 of the appendix of the thesis, particularly subsection `scripts/run`
### Create a list of files to process
1. Create a `todo_files_list`, or a txt file where each line is the path to an EDF you wish to process. If you would like to rerun the pipeline on all currently stored EEGs, use 'src/sample_data/bs/subset_files.txt'
### Edit the configuration and parameters
2. Edit `src/matlab/config_and_params/Config.m` to match your local configuration
3. Edit any parameters you like in `src/matlab/config_and_params/...Params.m`
### Run the pipeline
4. Go to `src/matlab/scripts/run`. Run `write_similarities_all_bursts.m`
