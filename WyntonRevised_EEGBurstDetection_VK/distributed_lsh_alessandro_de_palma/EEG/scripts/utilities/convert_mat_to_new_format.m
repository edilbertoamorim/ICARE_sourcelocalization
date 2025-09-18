function [ ] = convert_mat_to_new_format( merged_folder, output_folder )
%convert_mat_to_new_format Converts BIDMC and MGH mat files
% from mat.merged_struct and mat.matrix
% to mat.header and mat.matrix

    %% Preliminaries.
    system(['find ' char(merged_folder) ' -print | grep "CA_MGH_" > MGH_merged_list.txt']);
    system(['find ' char(merged_folder) ' -print | grep "CA_BIDMC_" > BIDMC_merged_list.txt']);
    system('cat MGH_merged_list.txt BIDMC_merged_list.txt > merged_list.txt');

    %Read the just created file with all patients on separate lines, line by line.
    fid = fopen('merged_list.txt');
    patient_filename = fgetl(fid);  % Merged file associated to a given patient.

    % Create cell array of patient filenames.
    patient_cell = {};
    iteration = 1;
    while ischar(patient_filename)
       patient_cell{iteration} = string(patient_filename);

       patient_filename = fgetl(fid);
       iteration = iteration + 1;
    end
    fclose(fid);

    %% Conversion.
    parpool(8);
    % Iterate on patients.
    parfor k=1:length(patient_cell)

        merged_patient_filename = char(patient_cell{k});
        ['Processing patient: ' char(merged_patient_filename)]

        merged_struct = load_mat(merged_patient_filename);

        output = create_merged_patient_file(output_folder, merged_struct.merged_struct.name, merged_struct.merged_struct);
        output.matrix = merged_struct.matrix;
        merged_struct = [];
    end
end
