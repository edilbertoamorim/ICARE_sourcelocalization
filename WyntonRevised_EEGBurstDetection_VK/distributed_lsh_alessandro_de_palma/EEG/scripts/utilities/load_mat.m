function [ mat ] = load_mat( filename )
%load_mat Loads .mat file and returns the variable it is stored to.
% The only point of this function is to comply with the
% Parallel Computing Toolbox Transparency rules.

    mat = load(filename);
    
end
