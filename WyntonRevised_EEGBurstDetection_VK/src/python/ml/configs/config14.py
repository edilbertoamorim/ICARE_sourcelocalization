MIN_BURST_SECS, MAX_BURST_SECS = 0.1, 5
MIN_EPISODE_MINS, MAX_EPISODE_MINS = 10, None

PAD_LENGTH = 2*200 # in samples, not seconds!
BATCH_BY_LEN = True

robust_scale = True # scale by median and IQR instead of mean and std
downsample_factor = 2 # set to None to use no downsampling
DATA_DIR = '/afs/csail.mit.edu/u/t/tzhan/NFS/script_output/describe_bs/'
MAX_NUM_PATIENTS = 200 
train_split, dev_split = 0.6, 0.2

HIDDEN_SIZE = 100
INPUT_SIZE = 1 # This CANNOT be changed! 
BIDIRECTIONAL = True
NUM_LAYERS = 2
EXTRA_INPUT_DIM = False

BATCH_SIZE = 30 
NUM_EPOCHS = 150 # Normally use 50, but can stop early at 20
LR = 1e-3
WEIGHT_DECAY = 1e-4
TEACHER_FORCING_SLOPE = 0.005
TRAIN_REVERSED = True

SAVE_DIR = 'saved_encs'
USE_LOSSWISE = True

RUN_TAG = '100h_400pad_robust_2ds_005tf_2lay'
