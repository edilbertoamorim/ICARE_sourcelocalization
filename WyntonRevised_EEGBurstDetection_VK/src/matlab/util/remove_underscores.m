function [pt_id] = remove_underscores(pt_id)

underscore_locations = find(pt_id == '_')

if isempty(underscore_locations) == 0
    pt_id = strcat(pt_id(1:underscore_locations(1)-1),pt_id(underscore_locations(1)+1:end))
end
end


