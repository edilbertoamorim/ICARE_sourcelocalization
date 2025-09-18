%% Read edfs and run basic standardization. Saves eeglab_eeg struct. 

% create the save_folder if it does not exist
% Assumes folder "Config.get_configs('output_dir')" already exists
[status, ~, ~] = mkdir(Config.get_configs('output_dir'), 'eeglab');
assert(status==1);

eeg_struct_folder = fullfile(Config.get_configs('output_dir'), 'eeg_struct/');
eeglab_save_folder = fullfile(Config.get_configs('output_dir'), 'eeglab/');
code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');
addpath(genpath(code_folder));
addpath(genpath(ale_code_folder));

files = get_todo_files();

num_files = size(files, 2);

errs_in_row = 0;

for i=1:num_files
    filename = files{i}
    [file_folder, filename_no_ext, ext] = fileparts(filename);
    patient_id = get_pt_from_fname(filename);
	disp(file_folder);
	disp([filename_no_ext ext]);
	try
		eeglab_save_path = fullfile(eeglab_save_folder, patient_id, [filename_no_ext, '_eeglab.mat']);
		if exist(eeglab_save_path, 'file')==2
            disp('eeglab file already exists, loading...');
            tic
            eeglab_struct = load(eeglab_save_path, '-mat', 'eeg_eeglab_unprocessed');
            toc
            eeglab = eeglab_struct.('eeg_eeglab_unprocessed');
            if isfield(eeglab, 'data')
                [nchans, ns] = size(eeglab.data);
                if nchans==0 || ns==0
                    disp('ERROR ERROR ERROR ERROR!!!!');
                    disp(['eeglab file already exists, but nchans, ns=' num2str(nchans) num2str(ns)]);
                else
                    disp([eeglab_save_path 'eeglab file already exists, continuing']);
                    continue;
                end
            else
                disp('ERROR ERROR ERROR!!!!');
                disp('eeglab file already exists, but eeglab.data does not');
            end
		end
		eeg_struct_save_path = fullfile(eeg_struct_folder, [filename_no_ext, '_eeg_struct.mat']);
		if exist(eeg_struct_save_path, 'file')==2
			disp([eeg_struct_save_path 'eeg_struct already exists, getting saved']);
			eeg_struct_struct = load(eeg_struct_save_path, '-mat', 'eeg_struct');
            eeg_struct = eeg_struct_struct.('eeg_struct');
		else
			disp('start edf_to_struct')
			tic
			eeg_struct = edf_to_struct([filename_no_ext ext], file_folder);
			toc
			disp('done edf_to_struct')
			%disp(['Saving eeg_struct '  filename_no_ext]);
			%save(save_path, 'eeg_struct');
		end
		disp('start standardize_struct');
		tic
		standardized_struct = standardize_struct(eeg_struct);
		toc
		disp('start struct_to_EEGLab');
		tic
        SAMPLING_FREQUENCY = eeg_struct.header.frequency(1);  % This assumes that the sampling frequency does not change across channels.
        SUB_EPOCH_LENGTH = SAMPLING_FREQUENCY*5;  % 5s sub-epochs.
		eeg_eeglab_unprocessed = struct_to_EEGLab(standardized_struct, SUB_EPOCH_LENGTH);
		toc
		disp('Done - saving')
		tic
        [status, ~, ~] = mkdir(eeglab_save_folder, patient_id);
        assert(status==1);
        % Use v7.3 to save the larger files
		save(eeglab_save_path, 'eeg_eeglab_unprocessed', '-v7.3');
		toc
		errs_in_row = 0;
        
	catch ME
		if strcmp(ME.identifier, 'EDFREAD:NanHeaderNs')
			disp(['!!!!!!!!!!!!!! ' filename ' !!!!!!!!!!!!!!!!']);
			fprintf([ME.identifier ' in file\n' filename '\n' ME.message]);
			continue;
		else
			errs_in_row = errs_in_row + 1;
			if errs_in_row > 4
				rethrow(ME)
			else
				disp('!!!!!!!! ERROR ERROR ERROR ERROR!!!!!!!');
				disp(ME)	
				disp(ME.identifier)
				disp(ME.message)
			end
		end
	end
%     disp([filename_no_ext, 'start artifact detection...']);
% 	tic
%     is_artifact = detect_artifacts(eeg_processed);
% 	toc
%     disp([filename_no_ext, 'done artifact detection...']);
end
