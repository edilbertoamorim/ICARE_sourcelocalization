function cfg = read_config(file)
% READ_CONFIG reads a MATLAB-style configuration TXT file
% and returns a struct with all variables.
%
% Input:
%   file - path to the config TXT file
% Output:
%   cfg  - struct with configuration variables

    % Read all lines
    fid = fopen(file, 'r');
    if fid == -1
        error('Cannot open file: %s', file);
    end
    txt = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
    txt = txt{1};
    
    % Remove empty lines
    txt = txt(~cellfun('isempty', strtrim(txt)));
    
    % Concatenate lines into one string
    code = strjoin(txt, '\n');
    
    % Evaluate in a function scope and capture variables
    S = struct();
    evalin('caller', 'try, end'); % ensure safe context
    eval(code);   % variables created in workspace
    vars = whos;
    
    % Copy variables into struct
    cfg = struct();
    for i = 1:length(vars)
        cfg.(vars(i).name) = eval(vars(i).name);
    end
    
end
