function [ ] = merge_segments_to_patients( patientfiles_folder, output_folder, n_workers )
%MERGE_SEGMENTS_TO_PATIENTS Merge all the segments associated to a given
%patient into the same struct (for its format, see edf_to_struct.m).
% Assumes that create_patient_file_lists.py has been correctly run and has (possibly a part of) its
% output in patientfiles_folder.
% Passing as patientfiles_folder a single hospital, one can choose to execute the merge on a single hospital.

    %% Constants.
    N_CHANNELS = 19;  % Channels after standardization.
    TARGET_FREQUENCY = 100;  % Sampling frequency after standardization.

    N_HOURS = 72;  % Number of hours to keep.
    CUTOFF = TARGET_FREQUENCY*60*60*N_HOURS;  % Hours in terms of samples.

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

    %% Merge patients in parallel.
    parpool(n_workers);
    % Iterate on patients.
    parfor k=1:length(patient_cell)
    %for k=1:length(patient_cell)

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


        %% Create pre-allocated file.

        % Process first segment.
        remaining_from_start = 2;
        try
            segment_struct = edf_to_struct(char(segment_cell{1}), '');
        catch
            disp(['Segment crashed: ' char(segment_cell{1})])
            % If the segment crashed, move on the start until it doesn't.
            found_start = false;
            c_index = 2;
            while ~found_start && c_index <= length(segment_cell)
                try
                    segment_struct = edf_to_struct(char(segment_cell{c_index}), '');
                    found_start = true;
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
        c_segment_struct = standardize_struct(segment_struct);
        c_start_time = datetime(char(strcat(strcat(string(c_segment_struct.header.startdate), ','), string(c_segment_struct.header.starttime))), 'InputFormat', 'dd.MM.yy,HH.mm.ss');
        c_end_time = c_start_time + seconds(size(c_segment_struct.matrix, 2)/TARGET_FREQUENCY  - 1);
        start_time = c_start_time;
        end_time = c_end_time;  % Temporary end time used for merging.

        % Process last segment.
        actual_end = length(segment_cell);
        try
            f_segment_struct = edf_to_struct(char(segment_cell{length(segment_cell)}), '');
        catch
            disp(['Segment crashed: ' char(segment_cell{length(segment_cell)})])
            found_end = false;
            c_index = length(segment_cell)
            while ~found_end && c_index >= 1
                try
                    segment_struct = edf_to_struct(char(segment_cell{c_index}), '');
                    found_end = true;
                catch
                    disp(['Segment crashed: ' char(segment_cell{c_index})])
                end
                c_index = c_index - 1;
            end
            actual_end = c_index;
        end
        final_struct = standardize_struct(f_segment_struct);
        f_start_time = datetime(char(strcat(strcat(string(final_struct.header.startdate), ','), string(final_struct.header.starttime))), 'InputFormat', 'dd.MM.yy,HH.mm.ss');
        f_end_time = f_start_time + seconds(size(final_struct.matrix, 2)/TARGET_FREQUENCY);
        total_size = min(TARGET_FREQUENCY*seconds(f_end_time-start_time), CUTOFF);

        % Keep on trying to write to file until it succeeds.
        write_success = false;
        while ~write_success
            try
                % Compute its length and allocate file for the merged segments.
                merged_struct = create_merged_patient_file(output_folder, c_segment_struct.name, c_segment_struct);
                merged_struct.matrix = zeros(N_CHANNELS, total_size);  % Allocate the matrix in advance to 0's to reduce writings to the file.
                merged_struct.matrix(1:N_CHANNELS, 1:min(size(c_segment_struct.matrix, 2), CUTOFF)) = c_segment_struct.matrix(:, 1:min(CUTOFF, size(c_segment_struct.matrix, 2)));
                write_success = true;
            catch
                disp(['Error when writing for: ' char(c_segment_struct.name)])
            end
        end

        % Iterate on the segments of this patient (ordered according to their timestamps).
        for k2 = remaining_from_start:actual_end
            segment_filename = segment_cell{k2};

            ['Processing segment: ' char(segment_filename)]

            % Handle segment.
            try
                segment_struct = edf_to_struct(char(segment_filename), '');
            catch
                disp(['Segment crashed: ' char(segment_filename)])
                continue
            end
            size(segment_struct.matrix, 2) * size(segment_struct.matrix, 1) * 8 / (2^32)
            c_segment_struct = standardize_struct(segment_struct);

            c_start_time = datetime(char(strcat(strcat(string(c_segment_struct.header.startdate), ','), string(c_segment_struct.header.starttime))), 'InputFormat', 'dd.MM.yy,HH.mm.ss');
            c_end_time = c_start_time + seconds(size(c_segment_struct.matrix, 2)/TARGET_FREQUENCY - 1);

            current_start = min(TARGET_FREQUENCY*seconds(end_time-start_time), CUTOFF);
            assert(current_start >= 0, 'current size negative!');

            %% Perform merging
            %TODO: Mohammad's adding 1.1574e-05 to the difference. Why?

            % Offset from previous' segment end (it might be negative).
            gap_samples = TARGET_FREQUENCY*seconds(c_start_time-end_time);  % The gap might be even one month of data.

            % The new segment overlaps with the previous.
            old_start = current_start;
            current_start = current_start + gap_samples;

            % If this segment starts after 72h, we're done.
            if current_start >= CUTOFF
                break
            end

            % Compute the length after merging.
            future_start = current_start + size(c_segment_struct.matrix, 2);

            if current_start < 0
                % This is a segment starting at the same point as the
                % origin of the patient. Re-write only if it has more
                % samples than the ones we have.
                if future_start < old_start
                    continue
                end
                current_start = 0;
                future_start = current_start + size(c_segment_struct.matrix, 2);
            end

            % Append the new segment, but never append over 72h.
            if future_start >= CUTOFF
                % Keep on trying to write to file until it succeeds.
                write_success = false;
                while ~write_success
                    try
                        merged_struct.matrix(1:N_CHANNELS, (current_start+1):CUTOFF) = c_segment_struct.matrix(1:N_CHANNELS, 1:(CUTOFF - current_start));
                        write_success = true;
                    catch
                        disp(['Error when writing for: ' char(c_segment_struct.name)])
                    end
                end

                end_time = start_time + seconds(CUTOFF/100);
                break
            else
                assert(future_start < CUTOFF, 'future size larger than CUTOFF when merging');
                assert(future_start-(current_start+1) >= 0, 'future_size-(current_size+1) < 0');
                % Keep on trying to write to file until it succeeds.
                write_success = false;
                while ~write_success
                    try
                        % Append the new segment.
                        merged_struct.matrix(1:N_CHANNELS, (current_start+1):future_start) = c_segment_struct.matrix(:, :);
                        write_success = true;
                    catch
                        disp(['Error when writing for: ' char(c_segment_struct.name)])
                    end
                end
                end_time = c_end_time;
            end
        end

        ['Terminated patient' char(patient_filename)]
    end

    result = 'Terminated with success!'

end
