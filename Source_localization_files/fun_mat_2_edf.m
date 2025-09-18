function [raw_data] = fun_mat_2_edf(dir_path,mat_edf_path)

% temp create .edf file 

mat_edf_path_whole=fullfile(dir_path,mat_edf_path);
load(mat_edf_path_whole);

% sometime eeg info is stored in EEG variable
if exist('EEG','var')
    x=EEG;
end
raw_data = eeglab2fieldtrip(x,'raw','none');

%hdr=ft_fetch_header(raw_data);
%data=raw_data.trial{1,1};


end