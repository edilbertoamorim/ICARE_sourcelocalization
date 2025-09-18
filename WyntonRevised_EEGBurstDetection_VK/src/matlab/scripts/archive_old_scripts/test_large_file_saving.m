code_folder = fullfile(Config.get_configs('repo_dir'), 'src/matlab');
ale_code_folder = fullfile(Config.get_configs('repo_dir'), 'distributed_lsh_alessandro_de_palma/EEG/scripts/');
addpath(genpath(code_folder));
addpath(genpath(ale_code_folder));

filename = 'ynh_137_1_0_20130712T090038.edf';
file_folder = '/Users/tzhan/Dropbox (MIT)/1 mit classes/thesis/sample_data/big_files';

% a large one requiring v7.3
file_folder = '/afs/csail.mit.edu/u/t/tzhan/NFS/EEG-dataset/outboxYALE/Batch3/';
filename = 'ynh_20_1_0_20121007T091051.edf';
% a even larger one giving nomem error
file_folder = '/afs/csail.mit.edu/u/t/tzhan/NFS/EEG-dataset/outboxYALE/Batch2/';
filename = 'ynh_124_1_0_20120122T112432.edf';
% a normal sized one
file_folder='/afs/csail.mit.edu/u/t/tzhan/NFS/EEG-dataset/outboxYALE/Batch2/';
filename = 'ynh_132_4_1_20150615T225601.edf';

disp('Preprocessing - start edf_to_struct');
tic
eeg_struct = edf_to_struct(filename, file_folder);
toc
disp('Preprocessing - done edf_to_struct');

SAMPLING_FREQUENCY = eeg_struct.header.frequency(1);  % This assumes that the sampling frequency does not change across channels.
SUB_EPOCH_LENGTH = SAMPLING_FREQUENCY*5;  % 5s sub-epochs.

% Unify nomenclature across hospitals, downsample, retrieve channel locations, convert to EEGLab.
disp('Preprocessing - start standardize_struct');
tic
standardized_struct = standardize_struct(eeg_struct);
toc
disp('Preprocessing - done standardize_struct');
disp('Preprocessing - start struct_to_EEGLab');
tic
eeg_eeglab_unprocessed = struct_to_EEGLab(standardized_struct, SUB_EPOCH_LENGTH);
toc
disp('Preprocessing - done struct_to_EEGLab');

[~, filename_no_ext, ~] = fileparts(filename);
disp('Saving normal')
tic
save([filename_no_ext '_eeglab.mat'], 'eeg_eeglab_unprocessed');
toc
disp('Saving 7.3 version')
tic
save([filename_no_ext '_eeglab_73.mat'], 'eeg_eeglab_unprocessed', '-v7.3');
toc
disp('Loading normal')
tic
load([filename_no_ext '_eeglab.mat'], 'eeg_eeglab_unprocessed');
toc
disp('Loading 7.3 version');
tic
load([filename_no_ext '_eeglab_73.mat'], 'eeg_eeglab_unprocessed');
toc
