function write_log(logFile, fname, elapsedTime)
% write_log
% Appends a line to a log text file with the file name,
% processing time, and the current date/time.

    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    logMsg = sprintf('%s | %s | %.3f seconds\n', ...
                     timestamp, fname, elapsedTime);

    % Append to file
    fid = fopen(logFile, 'a');     % 'a' = append, auto-creates if missing
    if fid == -1
        warning('Could not open log file: %s', logFile);
        return;
    end

    fprintf(fid, '%s', logMsg);
    fclose(fid);

end