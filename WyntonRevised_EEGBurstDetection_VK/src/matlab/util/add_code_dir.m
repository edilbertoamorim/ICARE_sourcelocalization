% adds the necessary directories so that all functions/scripts used 
% are in the path

addpath(genpath('../config_and_params'));
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');
my_code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
addpath(genpath(my_code_folder));
addpath(genpath(ale_code_folder));