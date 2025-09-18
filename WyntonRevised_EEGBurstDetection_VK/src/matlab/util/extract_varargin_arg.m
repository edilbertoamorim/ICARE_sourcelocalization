function [arg_value, new_varargin] = extract_varargin_arg(arg_name, default_value, varargin)
%EXTRACT_VARGARIN_ARG 
%   Extracts an argument from varargin by name and removes that argument
%   from varargin, if it exists. 
%   If argument doesn't exist, returns defualt_value
    new_varargin = varargin;
    arg_index = find(strcmp(varargin, arg_name));
    if isempty(arg_index)
        arg_value = default_value;
    else
        arg_value = varargin{arg_index+1};
        new_varargin(arg_index:arg_index+1) = [];
    end
end