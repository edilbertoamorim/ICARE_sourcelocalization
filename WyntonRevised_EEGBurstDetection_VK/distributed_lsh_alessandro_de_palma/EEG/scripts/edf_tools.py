import numpy as np
import mne
from matplotlib import pyplot as plt

def read_edf(filename):
    edf = mne.io.read_raw_edf(filename)
    # Extract data from the first 2 channels, from 50 s to 100 s.
    print(edf.info['meas_date'])
    sfreq = edf.info['sfreq']
    data, times = edf[:2, int(sfreq * 50):int(sfreq * 100)]
    plt.plot(times, data.T)
    plt.grid(True)

    edf.plot(block=True)

if __name__ == "__main__":

    # Two consecutive files from the same patient have the same channels. They must be time slices, then.
    filename = "CA_BIDMC_14_21_20120409_044314.edf"
    read_edf(filename)
