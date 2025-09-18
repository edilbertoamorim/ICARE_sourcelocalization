MIN_BURST_SECS, MAX_BURST_SECS = 0.1, 5
MIN_EPISODE_MINS, MAX_EPISODE_MINS = 10, None

PAD_LENGTH = 4*200 # in samples, not seconds!
BATCH_BY_LEN = True

robust_scale = True # scale by median and IQR instead of mean and std
downsample_factor = 5 # set to None to use no downsampling
DATA_DIR = '/home/alice-eeg/NFS/script_output/describe_bs/'
MAX_NUM_PATIENTS = 500
MAX_NUM_BURSTS_PER_EPISODE = 500
train_split, dev_split = 0.7, 0.15

HIDDEN_SIZE = 100
INPUT_SIZE = 1 # This CANNOT be changed! 
BIDIRECTIONAL = True
NUM_LAYERS = 1
EXTRA_INPUT_DIM = False

BATCH_SIZE = 30 
NUM_EPOCHS = 300 # Normally use 50, but can stop early at 20
LR = 1e-3
WEIGHT_DECAY = 1e-4
TEACHER_FORCING_SLOPE = 0.005
TRAIN_REVERSED = True

SAVE_DIR = 'saved_encs'
USE_LOSSWISE = True

RUN_TAG = '100h_800pad_5ds_005tf'
