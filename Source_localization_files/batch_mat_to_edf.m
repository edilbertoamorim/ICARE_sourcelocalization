function batch_mat_to_edf(input_dir, output_dir)
    % BATCH_MAT_TO_EDF Converts all EEG .mat files in a folder to .edf
    % Skips conversion if the .edf file already exists.
    %
    % input_dir:  folder containing .mat files with struct x
    % output_dir: folder to save .edf files

    ft_defaults;

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    mat_files = dir(fullfile(input_dir, '*.mat'));

    for i = 1:length(mat_files)
        preproc_file = mat_files(i).name;
        [~, name, ~] = fileparts(preproc_file);
        out_fname = fullfile(output_dir, [name, '.edf']);

        if exist(out_fname, 'file')
            fprintf('⏩ Skipping %s (EDF already exists)\n', preproc_file);
            continue;
        end

        fprintf('\n🔄 Processing %s...\n', preproc_file);
        try
            loaded = load(fullfile(input_dir, preproc_file));
            x = loaded.x;

            if ~isreal(x.data)
                x.data = real(x.data);
            end

            data = double(x.data);            % channels x samples
            fs = x.srate;
            chan_labels = {x.chanlocs.labels};

            write_simple_edf(out_fname, data, fs, chan_labels);
            fprintf('✅ Saved EDF: %s\n', out_fname);

        catch ME
            warning('⚠️ Failed to convert %s: %s', preproc_file, ME.message);
        end
    end
end
