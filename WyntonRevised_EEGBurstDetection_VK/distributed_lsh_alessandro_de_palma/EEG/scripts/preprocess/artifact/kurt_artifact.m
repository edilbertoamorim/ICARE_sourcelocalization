function [ rejkurt ] = kurt_artifact( stats_cell, pop_m_kurt, pop_m_kurt, numstds, i )
%kurt_artifact Returns the epochs of patient i (ordering of global_PREPed_list.txt) which contain kurtosis artifacts.
% Adapted from Ghassemi.

    %TODO: in case interpolated data must not be used, this might have to be modified.

    rejkurt = stats_cell.kurtosis{i} > pop_m_kurt + numstds*pop_s_kurt |...
                  stats_cell.kurtosis{i} < pop_m_kurt - numstds*pop_s_kurt;

end
