%% Open EEG mat files, convert to edf and run bs_detection pipeline
function write_simple_edf(filename, data, fs, chan_labels)
% WRITE_SIMPLE_EDF writes EEG data to a basic EDF file (minimal header)
% Inputs:
%   filename    - string, output EDF filename (with .edf)
%   data        - numeric matrix, channels x samples
%   fs          - sampling rate in Hz
%   chan_labels - cell array of strings, channel labels

nChan = size(data, 1);
nSamples = size(data, 2);

recordDuration = 1; % seconds per data record (fixed 1s)
samplesPerRecord = fs * recordDuration;
nDataRecords = floor(nSamples / samplesPerRecord);

% Pad data if not exact multiple of samplesPerRecord
if nDataRecords * samplesPerRecord < nSamples
    nDataRecords = nDataRecords + 1;
    padSamples = nDataRecords * samplesPerRecord - nSamples;
    data = [data, zeros(nChan, padSamples)];
end

% EDF header fields
version = '0       ';                % 8 bytes
patientID = repmat(' ', 1, 80);     % 80 bytes
recordID = repmat(' ', 1, 80);      % 80 bytes
startDate = datestr(now, 'dd.MM.yy'); % 8 bytes
startTime = datestr(now, 'HH.mm.ss'); % 8 bytes
headerBytes = 256 + nChan * 256;     % 256 + 256*nChan
reserved = repmat(' ', 1, 44);       % 44 bytes
numDataRecordsStr = sprintf('%-8d', nDataRecords);
durationDataRecordStr = sprintf('%-8d', recordDuration);
numSignalsStr = sprintf('%-4d', nChan);

% Build channel-specific header strings (fixed-length fields)
labelStr = '';
for i = 1:nChan
    lbl = chan_labels{i};
    if length(lbl) > 16
        lbl = lbl(1:16);
    end
    labelStr = [labelStr, sprintf('%-16s', lbl)];
end

transducerType = repmat(sprintf('%-80s', ' '), 1, nChan);
physDimension = repmat(sprintf('%-8s', 'uV'), 1, nChan);
physMin = repmat(sprintf('%-8s', '-100'), 1, nChan);
physMax = repmat(sprintf('%-8s', '100'), 1, nChan);
digMin = repmat(sprintf('%-8s', '-2048'), 1, nChan);
digMax = repmat(sprintf('%-8s', '2047'), 1, nChan);
prefiltering = repmat(sprintf('%-80s', 'none'), 1, nChan);
samplesPerRecordStr = repmat(sprintf('%-8d', samplesPerRecord), 1, nChan);
reservedChan = repmat(sprintf('%-32s', ' '), 1, nChan);

% Open file
fid = fopen(filename, 'w', 'ieee-le'); % EDF files are little endian

% Write fixed header
fixed_header = [ ...
    sprintf('%-8s', version), ...
    sprintf('%-80s', patientID), ...
    sprintf('%-80s', recordID), ...
    sprintf('%-8s', startDate), ...
    sprintf('%-8s', startTime), ...
    sprintf('%-8d', headerBytes), ...
    sprintf('%-44s', reserved), ...
    sprintf('%-8d', nDataRecords), ...
    sprintf('%-8d', recordDuration), ...
    sprintf('%-4d', nChan) ...
];

fwrite(fid, fixed_header, 'char');

% Write channel headers
fprintf(fid, '%s', labelStr);
fprintf(fid, '%s', transducerType);
fprintf(fid, '%s', physDimension);
fprintf(fid, '%s', physMin);
fprintf(fid, '%s', physMax);
fprintf(fid, '%s', digMin);
fprintf(fid, '%s', digMax);
fprintf(fid, '%s', prefiltering);
fprintf(fid, '%s', samplesPerRecordStr);
fprintf(fid, '%s', reservedChan);

% Convert data to int16 scaled to digital range [-2048 2047]
% Here we scale data linearly between physMin and physMax to digMin/digMax
physMinVal = -100;
physMaxVal = 100;
digMinVal = -2048;
digMaxVal = 2047;

% Clip data to physMin/physMax range
data(data < physMinVal) = physMinVal;
data(data > physMaxVal) = physMaxVal;

scale = (digMaxVal - digMinVal) / (physMaxVal - physMinVal);
dataScaled = int16((data - physMinVal) * scale + digMinVal);

% Write data records, channel-wise interleaved
% Data in EDF is stored as samples per record, channels interleaved
for rec = 1:nDataRecords
    startSample = (rec-1)*samplesPerRecord + 1;
    endSample = rec*samplesPerRecord;
    segment = dataScaled(:, startSample:endSample);
    fwrite(fid, segment', 'int16'); % transpose to write channel samples interleaved
end

fclose(fid);
end
