patientfiles_folder = '~/eeg/patients/';
ale_code_folder = '~/eeg/coma_EEG_alice_zhan/distributed_lsh_alessandro_de_palma/EEG/scripts/';
addpath(genpath(ale_code_folder));

%% Preliminaries.
system(['find ' char(patientfiles_folder) ' -print | grep "patient_" > file_list.txt']);

% Read the just created file with all patients on separate lines, line by line.
fid = fopen('file_list.txt');
patient_filename = fgetl(fid);  % File associated to a given patient, containing all the patients.

% Create cell array of patient filenames.
patient_cell = {};
iteration = 1;
while ischar(patient_filename)
    patient_cell{iteration} = string(patient_filename);

    patient_filename = fgetl(fid);
    iteration = iteration + 1;
end
fclose(fid);

for k=1:length(patient_cell)
    patient_filename = patient_cell{k};
	disp(patient_filename);
    
    patient_file = fopen(patient_filename);
    segment_filename = fgetl(patient_file);  % Contains a single patient's file (ordered).
    segment_cell = {};  % Cell of segment names.
    iteration = 1;
    while ischar(segment_filename)
        segment_cell{iteration} = string(segment_filename);
	
        segment_filename = fgetl(patient_file);
        iteration = iteration + 1;
    end
    fclose(patient_file);
    for j=1:length(segment_cell)
        segment_filepath = segment_cell{j};
		disp(segment_filepath);
		try
		    [hdr, ~] = edfread(segment_filepath);
		    disp(hdr.frequency(1));
		catch
			disp('Problem with edfread');
		end
    end
end
