function [] = fix_write_matrix(file_path)
    [file_folder, filename_no_ext, ext] = fileparts(file_path);
    done_filepath = fullfile(file_folder, [filename_no_ext '_actually_fixed.txt']);
    
    old_done_filepath = fullfile(file_folder, [filename_no_ext '_fixed.txt']);
    if exist(old_done_filepath, 'file')==2
        % undo all the stuff from before
        disp('attempted fix before, undoing...');
        delete(old_done_filepath);
        delete(file_path);
        movefile([file_path '.old'], file_path);
    end
    
    if exist(done_filepath, 'file')==2
        disp(['already fixed', file_path]);
        return
    end

    disp(['fixing ' file_path]);

    fid = fopen(file_path,'r');
    header = fgetl(fid);
    next_line = fgetl(fid);
    fclose(fid);
    if isempty(next_line) || (isnumeric(next_line) && next_line==-1)
        disp('empty file, returning');
        copyfile(file_path, [file_path '.old']);
        fid = fopen(done_filepath, 'w');  
        fclose(fid);
        return;
    end
    
    matrix = dlmread(file_path, '\t', 1, 0);
    [num_rows, num_cols] = size(matrix);
    assert(num_cols==2);
    if mod(num_rows, 2)==1
        last_full_row = floor(num_rows/2);
        shared_row = last_full_row+1;
        col_1_elts = matrix(1:last_full_row, :);
        col_1_elts = reshape(col_1_elts', [last_full_row*2, 1]);
        col_1 = [col_1_elts;matrix(shared_row, 1)];
        col_2_elts = matrix(shared_row+1:end, :);
        col_2_elts = reshape(col_2_elts', [last_full_row*2, 1]);
        col_2 = [matrix(shared_row, 2);col_2_elts];
    else
        col_1 = reshape(matrix(1:num_rows/2, :)', [num_rows, 1]);
        col_2 = reshape(matrix(num_rows/2+1:end, :)', [num_rows, 1]);
    end
    corrected_matrix = [col_1 col_2];
    
    header_cell = strsplit(header, '\t');
    if isempty(strfind(header, 'index'))
        formatter = '%f';
    else
        formatter = '%.0f';
    end
    movefile(file_path, [file_path '.old']);
    write_matrix(file_path, corrected_matrix, formatter, '\t', header_cell);
    
    % Write a text file to indicate we are done.    
    fid = fopen(done_filepath, 'w');  
    fclose(fid);
end
