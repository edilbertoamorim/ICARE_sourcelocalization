function [ merged_struct ] = create_merged_patient_file( output_folder, name, current_struct )
%CREATE_MERGED_PATIENT_FILE This function is necessary due to the transparency
%policies of MatLab's parfor.
% https://www.mathworks.com/help/distcomp/transparency.html
% It returns a pointer to the file so that processing is done out of
% memory.

    filename = [char(output_folder) char(strcat(name, '-merged'))];
    merged_struct = matfile(filename, 'Writable', true);
    merged_struct.header = current_struct.header;
    merged_struct.name = current_struct.name;

end
