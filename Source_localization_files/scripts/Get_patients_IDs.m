% Author: A.Faloppa
% 21/09/2025
%
% Purpose of the code: Get patients IDs from I-CARE dataset in physionet
%
% Usage:
%   Be sure to have wfdb-app-toolbox added to your path and internet connection
%
%   Run the script
%
% As output an excel table will be saved in Source_licalization_files
% The Patients can be filtered before storing (see end of this file)

% --- Step 1: Define base URL and fetch patient directories ---
clear; close all; clc;

baseURL = 'https://physionet.org/files/i-care/2.1/training/';
listing = webread(baseURL);  % Fetch directory listing

% Extract patient IDs (skip 'RECORD' directory)
patientDirs = regexp(listing, 'href="([^"]+)"', 'tokens');
patientDirs = [patientDirs{:}]';
patientDirs = patientDirs(~ismember(patientDirs, {'../'}));
patientDirs = patientDirs(~ismember(patientDirs, {'RECORDS'}));

% Remove trailing slashes
patientDirs = cellfun(@(x) regexprep(x, '/$', ''), patientDirs, 'UniformOutput', false);

% --- Step 2: Initialize table to store metadata ---
metaData = table();

% --- Step 3: Loop through each patient directory ---
for i = 1:length(patientDirs)
    patientID = patientDirs{i};
    txtURL = sprintf('%s%s/%s.txt', baseURL, patientID, patientID);

    fprintf('Processing patient %s (%d of %d)...\n', patientID, i, length(patientDirs));
    
    try
        % Read patient metadata text file
        txtLines = strsplit(webread(txtURL), '\n');
    catch
        warning('Failed to read %s', txtURL);
        continue;
    end
    
    % --- Parse key-value pairs from the text file ---
    data = struct();
    for j = 1:length(txtLines)
        line = strtrim(txtLines{j});
        if isempty(line), continue; end
        tokens = strsplit(line, ':');
        if numel(tokens) < 2, continue; end
        
        % Clean field name
        key = strtrim(tokens{1});
        key = regexprep(key, '\s+', '_');       % spaces → underscores
        key = matlab.lang.makeValidName(key);   % ensure valid field name
        
        value = strtrim(tokens{2});
        
        % Keep Patient as string
        if strcmpi(key, 'Patient')
            value = string(value);
        else
            % Convert numeric and boolean values
            numVal = str2double(value);
            if ~isnan(numVal)
                value = numVal;
            elseif strcmpi(value, 'True')
                value = true;
            elseif strcmpi(value, 'False')
                value = false;
            else
                value = string(value);   % convert other strings to string type
            end
        end
        
        % Store in struct
        data.(key) = value;
    end

    % --- Convert struct to table ---
    T = struct2table(data, 'AsArray', true);  % force as row
    metaData = [metaData; T];                  % concatenate
end

% --- Step 4: Optional Filter ---
% metaData = metaData(~isnan(metaData.Outcome), :);
% filteredData = metaData(metaData.Outcome == "Good", :);
filteredData = metaData(metaData.CPC == 1, :);


% --- Step 5: Write metadata to Excel file ---
writetable(filteredData, 'ICARE_patient_metadata.xlsx');
fprintf('Metadata saved to ICARE_patient_metadata.xlsx\n');
