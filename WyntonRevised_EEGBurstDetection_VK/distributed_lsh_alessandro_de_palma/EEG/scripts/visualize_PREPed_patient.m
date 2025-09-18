%{
    Save snapshots of a patient before/after PREP.
%}

%% Preliminaries.

% Five patients per hospital.
patient_cell = {
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BWH/bwh_14_4_0_20120929T085719-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BWH/bwh_82_1_0_20131026T133439-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BWH/bwh_106_1_0_20141118T182914-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BWH/bwh_59_1_0_20130905T165413-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BWH/bwh_133_1_0_20150502T070620-merged.mat',

    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/yale/ynh_125_3_0_20140310T004845-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/yale/ynh_132_4_0_20150615T120459-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/yale/ynh_49_1_0_20120411T162705-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/yale/ynh_73_1_0_20130318T114501-merged.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/yale/ynh_27_1_0_20130619T025235-merged.mat',

    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BIDMC/CA_BIDMC_8_7_20150607_232219.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BIDMC/CA_BIDMC_63_2_20150615_070033.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BIDMC/CA_BIDMC_30_41_20101026_173436.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BIDMC/CA_BIDMC_72_1_20110315_142935.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/BIDMC/CA_BIDMC_50_6_20101110_162139.mat',

    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/MGH/CA_MGH_sid46_02_20121109_100505.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/MGH/CA_MGH_sid104_04_20150823_155037.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/MGH/CA_MGH_sid159_02_20150208_082945.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/MGH/CA_MGH_sid142_02_20141103_161013.mat',
    '/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-PREPed/MGH/CA_MGH_sid62_03_20121129_161855.mat'
};

output_folder = '/afs/csail.mit.edu/u/a/adepalma/Documents/plots/';
snapshot_offset = 100*10; % for 10sec.
N_CHANNELS = 19;
EPOCH_LENGTH = 100*60*5;
labels = {'Fp1', 'Fp2','F7', 'F8', 'T3', 'T4', 'T5', 'T6', 'O1', 'O2', 'F3', 'F4', 'C3', 'C4', 'P3', 'P4', 'Fz', 'Cz', 'Pz'};
N_SNAPS = 10;

set(gca,'FontSize',4,'fontWeight','bold')
set(findall(gcf,'type','text'),'FontSize',4,'fontWeight','bold')

%% Plotting.

for index = 1:length(patient_cell)

    patient_filename = char(patient_cell{index})
    processed = load(patient_filename);

    r = randi([1 size(processed.eeg.data,2)], 1, N_SNAPS);  % Take N_SNAPS random snapshots.

    for snap_index = 1:N_SNAPS
        snapshot_start = r(snap_index);
        snapshot_end = snapshot_start + snapshot_offset;

        processed_data = processed.eeg.data(:, snapshot_start:snapshot_end);
        intepolated_channels = processed.eeg.interpolatedChannels{int32(ceil(snapshot_start/EPOCH_LENGTH))};
        % Set interpolated channels to 0.
        for j = 1:length(intepolated_channels)
            processed_data(j, :) = zeros(1, size(processed_data, 2));
        end

        [path, name, ext] = fileparts(patient_filename);
        if strcmp(name(1:2), char('CA'))
            name = [name '-merged'];
        end
        split = strsplit(path, '/');
        path = ['/afs/csail.mit.edu/u/a/adepalma/NFS/EEG-merged-dataset/' char(split{9}) '/'];
        unprocessed = load([path name ext]);
        unprocessed_data = unprocessed.matrix(:, snapshot_start:snapshot_end);

        % Plot unprocessed snapshot.
        figure(2*N_SNAPS*index + snap_index)
        for j = 1:N_CHANNELS
            subplot(N_CHANNELS, 1, j)
            plot(snapshot_start:snapshot_end, unprocessed_data(j, :))
            title(char(labels{j}))
            if j < N_CHANNELS
                set(gca,'xtick',[1 2 3 4 5], 'xticklabel',{}) % Make the labels of just one x axis visible.
            end
            set(gca,'FontSize',4,'fontWeight','bold')
            set(findall(gcf,'type','text'),'FontSize',4,'fontWeight','bold')
        end
        print([char(output_folder) char(name) '-unprocessed-snapshot' char(int2str(snap_index))], '-dpng')

        % Plot processed snapshot.
        figure(2*N_SNAPS*index + snap_index + 1)
        for j = 1:N_CHANNELS
            subplot(N_CHANNELS, 1, j)
            plot(snapshot_start:snapshot_end, processed_data(j, :))
            title(char(labels{j}))
            if j < N_CHANNELS
                set(gca,'xtick',[1 2 3 4 5], 'xticklabel',{})
            end
            set(gca,'FontSize',4,'fontWeight','bold')
            set(findall(gcf,'type','text'),'FontSize',4,'fontWeight','bold')
        end
        print([char(output_folder) char(name) '-processed-snapshot' char(int2str(snap_index))], '-dpng')
    end

end
