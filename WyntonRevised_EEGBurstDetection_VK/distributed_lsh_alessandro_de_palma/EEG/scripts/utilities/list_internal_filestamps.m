function [ ] = list_internal_filestamps( patientfiles_folder )

%list_internal_filestamps creates a file in the format: edf-filename header-starttime (one per line)
% Relies on the same assumptions for merge_segments_to_patients.


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

    % Iterate on patients.
    for k=1:length(patient_cell)

        patient_filename = patient_cell{k}

        ['Processing patient: ' char(patient_filename)]

        % Keep on trying to read from file until it succeeds.
        write_success = false;
        while ~write_success
            try
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
                write_success = true;
            catch
                disp(['Error when reading from patient file: ' char(patient_file)])
            end
        end

        % Read first segment.
        remaining_from_start = 2;
        try
            header = edfread(char(segment_cell{1}));
            start = [char(header.startdate) ' ' char(header.starttime)];
            [path, name, ext] = fileparts(char(segment_cell{c_index}));
            system([char(name) ' - ' char(start) '>> internal_timestamp_list.txt']); % Print line.
        catch
            disp(['Segment crashed: ' char(segment_cell{1})])
            % If the segment crashed, move on the start until it doesn't.
            found_start = false;
            c_index = 2;
            while ~found_start && c_index <= length(segment_cell)
                try
                    header = edfread(char(segment_cell{c_index}));
                    found_start = true;
                    start = [char(header.startdate) ' ' char(header.starttime)];
                    [path, name, ext] = fileparts(char(segment_cell{c_index}));
                    system([char(name) ' - ' char(start) '>> internal_timestamp_list.txt']); % Print line.
                catch
                    disp(['Segment crashed: ' char(segment_cell{c_index})])
                end
                c_index = c_index + 1;
            end
            remaining_from_start = c_index;
            % If no segment is valid, move on to the next patient.
            if ~found_start
                continue
            end
        end

        % Iterate on the segments of this patient (ordered according to their timestamps).
        for k2 = remaining_from_start:length(segment_cell)
            segment_filename = segment_cell{k2};

            ['Processing segment: ' char(segment_filename)]

            % Handle segment.
            try
                header = edfread(char(segment_filename));
            catch
                disp(['Segment crashed: ' char(segment_filename)])
                continue
            end
            [path, name, ext] = fileparts(char(segment_filename));
            start = [char(header.startdate) ' ' char(header.starttime)];
            system(['echo "' char(name) ' - ' char(start) '" >> internal_timestamp_list.txt']); % Print line.

        end

        ['Terminated patient' char(patient_filename)]
    end

    result = 'Terminated with success!'

end
