function [ ] = save_eeglab_to_mat( eeg, output_folder )
%save_eeglab_to_mat Save eeglab eeg to output_folder as a mat file.
% pipeline to the merged patient files in merged_folder.
% The only point of this function is to comply with the
% Parallel Computing Toolbox Transparency rules.
%
% Format:
%   mat.eeg (eeg is the eeglab structure)

    save([char(output_folder) char(eeg.SID)], 'eeg', '-v7.3');

end
