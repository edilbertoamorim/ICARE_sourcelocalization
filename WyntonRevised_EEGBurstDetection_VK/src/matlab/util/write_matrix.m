function [] = write_matrix(file_path, matrix, format, delimiter, column_titles)
% Writes a matrix to an output file
%   file_path - desired path of the output file
%   matrix - n x m matrix
%   format - a format string specifying format for each number. Eg: %f
%   delimiter - delimiter between elements in a row. Eg: '\t';
%   column_titles - cell array of strings, of titles for each column. 
%                   Printed at beginning of file.

out_fid = fopen(file_path, 'w');

header_c = join(column_titles, delimiter);
header = [header_c{1} '\n'];
fprintf(out_fid, header);

[~, m] = size(matrix);
num_formatters = cell(1, m);
num_formatters(:) = {format};
row_formatter_c = join(num_formatters, delimiter);
row_formatter = [row_formatter_c{1} '\n'];
fprintf(out_fid, row_formatter, matrix');
fclose(out_fid);
