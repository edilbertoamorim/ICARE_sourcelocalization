function [eeg_eeglab_unprocessed] = load_eeglab_eeg(filepath, use_saved, save_result)
%LOAD_EEGLAB_EEG - Gets the eeglab eeg object for an edf

% Input 
%     use_saved - boolean. optional. default is true. 
%         if true and saved eeglab eeg object exists, loads that
%         eeglab eeg object instead of re-creating it. 
%     save_result - boolean. optional. default is true. 
%         if true, saves any newly created eeglab eeg object to a matfile.
%         The matfile is saved inside an 'eeglab' subdirectory of the 
%        'output_dir' specified in Config.m

% Output
%     eeg_eeglab_unprocessed - raw eeglab eeg object, as read in from the
%       edf, with channel nomenclature standardization

% Notes
%     Expects any saved files to be inside 'eeglab' subdirectory of the 
%        'output_dir' specified in Config.m. If this folder doesn't exist,
%        this script creates it.

    if nargin < 3
        use_saved = 1;
    end
    if nargin < 4
        save_result = 1;
    end
    
    [file_folder, filename_no_ext, ext] = fileparts(filepath);
    patient_id = get_pt_from_fname(filepath);

    % create the save_folder if it does not exist
    [status, ~, ~] = mkdir(Config.get_configs('output_dir'), 'eeglab');
    assert(status==1);
    
    eeglab_save_folder = fullfile(Config.get_configs('output_dir'), 'eeglab/');
    eeglab_save_path = fullfile(eeglab_save_folder, patient_id, [filename_no_ext, '_eeglab.mat']);
    
    requires_load = true;
    if use_saved && exist(eeglab_save_path, 'file')==2
        % If use_saved and saved file already exists, load it
        disp('eeglab file already exists, loading...');
        t = tic;
        eeglab_struct = load(eeglab_save_path, '-mat', 'eeg_eeglab_unprocessed');
        toc(t);
        eeg_eeglab_unprocessed = eeglab_struct.('eeg_eeglab_unprocessed');
        % Check if the loaded struct actually contains data
        is_loaded_good = check_loaded_eeglab(eeg_eeglab_unprocessed);
        requires_load = ~is_loaded_good;
    end
    if requires_load
        % Create eeglab struct 
        disp('start edf_to_struct')
        tic
        % Read file to a struct.
        eeg_struct = edf_to_struct([filename_no_ext ext], [file_folder '/']);
        toc
        disp('start standardize_struct');
        tic
        % Unify nomenclature across hospitals, downsample, retrieve channel locations, convert to EEGLab.
        standardized_struct = standardize_struct(eeg_struct);
        toc
        disp('start struct_to_EEGLab');
        tic
        SAMPLING_FREQUENCY = eeg_struct.header.frequency(1);  % This assumes that the sampling frequency does not change across channels.
        SUB_EPOCH_LENGTH = SAMPLING_FREQUENCY*5;  % 5s sub-epochs.
        eeg_eeglab_unprocessed = struct_to_EEGLab(standardized_struct, SUB_EPOCH_LENGTH);
        
        % If save_result, then save the eeglab struct.
        if save_result
            [status, ~, ~] = mkdir(eeglab_save_folder, patient_id);
            assert(status==1);
            disp(['Saving eeglab '  filename_no_ext]);
            % Use v7.3 to save the larger files
            save(eeglab_save_path, 'eeg_eeglab_unprocessed', '-v7.3');
        end
        disp(['Done loading and saving eeglab ' filename_no_ext]);
    end
end

function [is_good] = check_loaded_eeglab(eeglab)
% CHECK_LOADED_EEGLAB - check that a loaded in eeglab eeg object is
%   nonempty, and that its sample rate matches our desired sample rate
    is_good = false;
    if isfield(eeglab, 'data')
        [nchans, ns] = size(eeglab.data);
        if nchans==0 || ns==0
            disp('ERROR ERROR ERROR ERROR!!!!');
            disp(['eeglab file already exists, but nchans, ns=' num2str(nchans) num2str(ns)]);
        else
            target_frequency = PrepArtifactParams.get_params('target_frequency');
            if eeglab.srate == target_frequency
                disp('loaded eeglab file seems good');
                is_good = true;
            end
        end
    else
        disp('ERROR ERROR ERROR!!!!');
        disp('eeglab file already exists, but eeglab.data does not');
    end
end
