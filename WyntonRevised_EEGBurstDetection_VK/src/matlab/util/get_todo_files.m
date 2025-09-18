function [files] = get_todo_files()
%GET_TODO_FILES Util function for scripts
%   Reads todo_files_list and returns todo_files in a cell array
    files_list_filename = Config.get_configs('todo_files_list');

    files = {};
    fid = fopen(files_list_filename);
    file = fgetl(fid);
    i = 1;
    while ischar(file)
        files{i} = file;
        i = i + 1;
        file = fgetl(fid);
    end
    fclose(fid);
end

