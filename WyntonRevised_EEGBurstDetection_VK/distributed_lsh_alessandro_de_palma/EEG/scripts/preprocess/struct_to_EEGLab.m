function [ output ] = struct_to_EEGLab( input, epoch_length )
%standardize_struct_to_EEGLab Unify (across hospitals) channel nomenclature, crop and convert to EEGLab with channel locations.

%   Retrieve standardized
%   locations and convert to EEGLab format. Input is a struct in the same format of edf_to_stuct.m.
%   epoch_length is the length of an epoch in seconds. Epochs will be later used for artifact detection.


    %% Constants.
    FREQUENCY = input.header.frequency(1); % assumes we have the same frequency for all the channels.
    N_CHANNELS = 19;  % Final number of channels.
    N_HOURS = 72;  % Number of hours to keep.
    CUTOFF = FREQUENCY*60*60*N_HOURS;  % Hours in terms of samples.
    DATA_LENGTH = size(input.matrix, 2);

    %% Crop to N_HOURS, convert to EEGLab and retrieve standardized locations.
    stop_here = min(CUTOFF, DATA_LENGTH);  % Crop.

    % And make sure we have a clean 5 min cut.
    stop_here = epoch_length*floor(stop_here/epoch_length);
    data = input.matrix(1:N_CHANNELS,1:stop_here);

    % Import the EEGs into EEGLab format.
    EEG = pop_importdata('data', data, ...
            'dataformat', 'array', ...
            'nbchan', N_CHANNELS,...
            'srate', FREQUENCY);

    EEG.SID = input.name;
    EEG.chanlocs = readlocs('MGH.locs');  % Read MGH location file.

    output = EEG;

end
