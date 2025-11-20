function out_table = attach_labels(features_table, features_resolution, labels_table, labels_resolution)
% ATTACH_LABELS Merge labels into a feature table with different resolutions.
%
% INPUTS
%   features_table       : table. Each row is one feature sample. Must contain a 'Part' column.
%   features_resolution  : numeric. Duration (in seconds or samples) of one feature row.
%   labels_table         : table. Each row is one label sample.
%   labels_resolution    : numeric. Duration of one label row.
%
% OUTPUT
%   out_table            : table. features_table with an extra column 'Label' 
%
% Aggregation rules:
%   Numeric columns -> mean() over the label window.
%   Non-numeric columns -> mode() over the label window.
%
% Error conditions:
%   - feature_resolution must be an integer multiple of labels_resolution.

    %% Identify numeric vs categorical/mode columns
    mean_cols = ["Other_prob","Seizure_prob","LPD_prob","GPD_prob", ...
                 "LRDA_prob","GRDA_prob","BCI_value"];
    mode_cols = ["six_label","final_label","has_artifact","artifact_types"];

    % Ensure these exist in the labels table
    if ~all(ismember(mean_cols, labels_table.Properties.VariableNames))
        error('Some mean columns are missing from labels_table.');
    end
    if ~all(ismember(mode_cols, labels_table.Properties.VariableNames))
        error('Some mode columns are missing from labels_table.');
    end

    %% Resolution compatibility check
    r = features_resolution / labels_resolution;

    if abs(r - round(r)) > 1e-9
        error('Feature resolution (%.3f) is not a multiple of label resolution (%.3f).', ...
              features_resolution, labels_resolution);
    end

    lab_window = round(r);  % number of label rows per feature row

    %% Preallocate outputs
    nFeat = height(features_table);

    % Preallocate numeric mean outputs
    mean_out = array2table(nan(nFeat, numel(mean_cols)), 'VariableNames', mean_cols);

    % Preallocate categorical/mode outputs
    % Convert them to categorical if needed
    mode_out = table();
    for c = mode_cols
        column_data = labels_table.(c);
        if ~iscategorical(column_data)
            column_data = categorical(column_data);
        end
        mode_out.(c) = categorical(repmat(missing, nFeat, 1), categories(column_data));
    end

    %% Loop over parts
    parts = features_table.Part;
    unique_parts = unique(parts);

    for p = unique_parts(:)'
        % Feature rows that belong to this Part
        feat_rows = find(parts == p);

        % Label index range equivalent to this Part
        start_idx = (p - 1) * lab_window + 1;
        end_idx   = p * lab_window;

        % Check available label length
        if start_idx > height(labels_table)
            % No labels available for this part → stays NaN/missing
            continue
        end

        % Limit end index to the labels table length
        end_idx = min(end_idx, height(labels_table));

        % Extract labels in the window
        win = labels_table(start_idx:end_idx, :);

        %% Compute means for numeric columns
        for c = mean_cols
            x = win.(c);
            if isnumeric(x)
                val = mean(x, 'omitnan');
            else
                % If a "numeric" column is unexpectedly not numeric
                val = nan;
            end
            mean_out{feat_rows, c} = val;
        end

        %% Compute modes for categorical columns
        for c = mode_cols
            x = win.(c);
            if ~iscategorical(x)
                x = categorical(x);
            end

            if isempty(x)
                mode_val = missing;
            else
                mode_val = mode(x);
            end

            mode_out{feat_rows, c} = mode_val;
        end
    end

    %% Combine everything into one output table
    out_table = [features_table, mean_out, mode_out];
end
