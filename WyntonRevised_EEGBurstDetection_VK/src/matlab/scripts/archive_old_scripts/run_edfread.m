%% Run read_edf and save result.

eeg_struct_folder = fullfile(Config.get_configs('output_dir'), 'eeg_struct/');
code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');
addpath(genpath(code_folder));
addpath(genpath(ale_code_folder));

files = get_todo_files();

num_files = size(files, 2);

use_saved_preprocessed = 0;
save_preprocessed = 0;

for i=1:num_files
    filename = files{i}
    [file_folder, filename_no_ext, ext] = fileparts(filename);
	disp(file_folder);
	disp([filename_no_ext ext]);
	try
		save_path = fullfile(eeg_struct_folder, [filename_no_ext, '_eeg_struct.mat']);
		if exist(save_path, 'file')==2
			disp([save_path 'already exists, continuing']);
			continue;
		end
        disp('start edf_to_struct')
        tic
        eeg_struct = edf_to_struct([filename_no_ext ext], file_folder);
        toc
        disp('done edf_to_struct')
        disp(['Saving eeg_struct '  filename_no_ext]);
        save(save_path, 'eeg_struct');
        
%        disp('start load eeg_struct')
%        tic
%        eeg_struct_loaded = load(fullfile(eeg_struct_folder, [filename_no_ext, '_eeg_struct.mat']), '-mat');
%        toc
%        disp('done load eeg_struct')
	catch ME
		if strcmp(ME.identifier, 'EDFREAD:NanHeaderNs')
			disp(['!!!!!!!!!!!!!! ' filename ' !!!!!!!!!!!!!!!!']);
			fprintf([ME.identifier ' in file\n' filename '\n' ME.message]);
			continue;
		else
			rethrow(ME)
		end
	end
%     disp([filename_no_ext, 'start artifact detection...']);
% 	tic
%     is_artifact = detect_artifacts(eeg_processed);
% 	toc
%     disp([filename_no_ext, 'done artifact detection...']);
end
