%% Run preprocessing and save result.
%% Out of date!! 

code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
addpath(genpath(code_folder));

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
        [eeg_processed, eeg_unprocessed] = get_preprocessed([filename_no_ext ext], file_folder, use_saved_preprocessed, save_preprocessed);
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
