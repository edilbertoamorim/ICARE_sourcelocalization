import os
import sys

sys.path.append('..')

import utils
import readers
from readers import patient_info, describe_bs_output_reader 

import numpy as np
import torch
import torch.utils.data
from torch import Tensor
import random
import json
import math

class BurstDataset(torch.utils.data.Dataset):
    def __init__(self, data_dir, all_bursts=None, all_burst_masks=None, all_burst_info=None, sort_len=False):
        # min_episode_mins : min duration of a episode (mins). Default 0. 
        # max_episode_mins : max duration of a episode (mins). Default none. 
        # min_burst_secs : min duration of a burst (secs). Default 0. 
        # max_burst_secs : max duration of a burst (secs). Default none. 
        # sort_len: whether or not to sort the dataset by length, so that batches get 
        #   bursts with similar lengths
        self.data_dir = data_dir
        self.patientInfoReader = patient_info.PatientInfo('../../../patient_outcome_info/')
        self.burstReader = describe_bs_output_reader.DescribeBsOutputReader(data_dir)
        
        self.sort_len = sort_len
        if all_bursts is not None and all_burst_masks is not None and all_burst_info is not None:
            self.all_bursts = all_bursts
            self.all_burst_masks = all_burst_masks
            self.all_burst_info = all_burst_info
            if self.sort_len==True:
		print('sorting dataset by length...')
                self._sort_dataset_by_burst_length()
            assert(len(self.all_bursts)==len(self.all_burst_info))
            assert(len(self.all_bursts)==len(self.all_burst_masks))
        else:
            print('Creating empty BurstDataset--call init_dataset() to fill with data!')
       
    def _sort_dataset_by_burst_length(self):
        # sorts the dataset by burst length
        burst_lens = self.all_burst_masks.sum(axis=1)
        data_zipped = zip(burst_lens, self.all_bursts, self.all_burst_masks, self.all_burst_info)
        data_zipped.sort(key=lambda x: x[0])
        burst_lens, all_bursts, all_burst_masks, all_burst_info = zip(*data_zipped)
        self.all_bursts = np.array(all_bursts)
        self.all_burst_masks = np.array(all_burst_masks)
        self.all_burst_info = all_burst_info
        
    def init_dataset(self, pad_length, min_episode_mins=0, max_episode_mins=None, min_burst_secs=0, max_burst_secs=None, 
                     downsample_factor=None, max_num_patients=9999, max_num_bursts_per_episode=None):
        # max_num_patients: used for testing, to limit dataset size. Default: very large number.
        
        self.pad_length = pad_length        
        if max_burst_secs is None:
            max_burst_secs = 72 * 60 * 60 # set max duration to 72 hours, which is duration of entire EEG.
        if max_episode_mins is None:
            max_episode_mins = 72 * 60 # set max duration to 72 hours
        self.min_episode_s_len = utils.min_to_samples(min_episode_mins)
        self.max_episode_s_len = utils.min_to_samples(max_episode_mins)
        self.min_burst_s_len = utils.sec_to_samples(min_burst_secs)
        self.max_burst_s_len = utils.sec_to_samples(max_burst_secs)
        self.downsample_factor = downsample_factor
        self.max_num_bursts_per_episode = max_num_bursts_per_episode

        print('Reading data...')
        all_bursts = []
        all_burst_masks = []
        all_burst_info = []
        num_bs_patients = 0
        for i, patient in enumerate(self.patientInfoReader.get_all_sids()):
            if num_bs_patients == max_num_patients:
                break
            patient_bursts = []
            patient_burst_masks = []
            patient_burst_info = []
            for (edf, _, _) in self.patientInfoReader.get_edfs_and_indices(patient, max_num_hours=72):
                edf_bursts, edf_burst_masks, edf_burst_info = self._create_edf_bursts(edf)
                patient_bursts.extend(edf_bursts)
                patient_burst_masks.extend(edf_burst_masks)
                patient_burst_info.extend(edf_burst_info)
	    if len(patient_bursts)!=0:
	        sys.stdout.write('{}...'.format(num_bs_patients))
	        sys.stdout.flush()
	        num_bs_patients +=1
            all_bursts.extend(patient_bursts)
            all_burst_masks.extend(patient_burst_masks)
            all_burst_info.extend(patient_burst_info)
        self.all_bursts = np.array(all_bursts)
        self.all_burst_masks = np.array(all_burst_masks)
        self.all_burst_info = all_burst_info
        if self.sort_len:
	    print('sorting dataset by length...')
            self._sort_dataset_by_burst_length()
        assert(len(self.all_bursts)==len(self.all_burst_info))
        assert(len(self.all_bursts)==len(self.all_burst_masks))
        
    def split(self, train_split, val_split, split_sort_len=True):
        # splits data by the percentages given by train_split and val_split into train, val, and test
        # split_sort_len: whether or not splits of datasets should be sorted by len
        l = len(self)
        shuffle_indices = np.arange(l)
        np.random.shuffle(shuffle_indices)
        train_end = int(l * train_split)
        val_end = int(l * train_split) + int(l * val_split)
        train_inds = shuffle_indices[:train_end]
        val_inds = shuffle_indices[train_end:val_end]
        test_inds = shuffle_indices[val_end:]
        
        train_dataset = BurstDataset(self.data_dir, all_bursts=self.all_bursts[train_inds], 
                                     all_burst_info=[self.all_burst_info[i] for i in train_inds],
                                     all_burst_masks=self.all_burst_masks[train_inds], sort_len=split_sort_len)
        val_dataset = BurstDataset(self.data_dir, all_bursts=self.all_bursts[val_inds], 
                                     all_burst_info=[self.all_burst_info[i] for i in val_inds],
                                   all_burst_masks=self.all_burst_masks[val_inds], sort_len=split_sort_len)
        test_dataset = BurstDataset(self.data_dir, all_bursts=self.all_bursts[test_inds], 
                                     all_burst_info=[self.all_burst_info[i] for i in test_inds],
                                    all_burst_masks=self.all_burst_masks[test_inds], sort_len=split_sort_len)
        for dataset in [train_dataset, val_dataset, test_dataset]:
            dataset.pad_length = self.pad_length
            dataset.downsample_factor = self.downsample_factor
        return train_dataset, val_dataset, test_dataset
        
    def _burst_has_bad_duration(self, burst_obj):
        # returns True or False, for whether or not the burst duration is out of our allowed durations
        burst_duration = len(burst_obj['burst_data'])
        return burst_duration < self.min_burst_s_len or burst_duration > self.max_burst_s_len
        
    def _is_bad_episode_duration(self, duration_n_samples):
        # returns True or False, for whether or not the episode duration is out of our allowed durations
        return duration_n_samples < self.min_episode_s_len or duration_n_samples > self.max_episode_s_len
    
    def _pad_bursts(self, episode_bursts_list, episode_burst_info):
        # takes in list of bursts and pads them into an array and downsamples
        # returns np array of [num_bursts x pad_length]
        # num_bursts is cut to be at most self.max_num_bursts_per_episode
        # 
        # episode_bursts is list of bursts,
        # which are lists of lengths between 1 and pad_length, inclusive
        num_bursts = min(len(episode_bursts_list), self.max_num_bursts_per_episode)
        episode_bursts = np.zeros((num_bursts, self.pad_length))
        episode_burst_masks = np.zeros((num_bursts, self.pad_length))
        episode_burst_info_cut = []
        for i, burst_data in enumerate(episode_bursts_list):
            if i == self.max_num_bursts_per_episode:
                break
            data_index = len(burst_data)
            episode_bursts[i, :data_index] = burst_data[:data_index]
            episode_burst_masks[i, :data_index] = 1
            episode_burst_info_cut.append(episode_burst_info[i])
        episode_bursts = episode_bursts[:, ::self.downsample_factor]
        episode_burst_masks = episode_burst_masks[:, ::self.downsample_factor]
        return episode_bursts, episode_burst_masks, episode_burst_info_cut
    
    def _create_edf_bursts(self, edf_name):
        # for bs output for a given edf, returns np array of 
        # all bursts in all episodes [num_bursts x pad_length] 
        bs_episodes = self.burstReader.get_bs_episodes(edf_name)
        edf_burst_masks = []
        edf_bursts = []
        # tells enough about burst to get the full data later: edf_name, episode_indices, 
        # and index in burst_dict_list for the episode
        edf_burst_info = []  
        for episode_indices in bs_episodes:
            start_index, end_index = episode_indices
            duration = end_index - start_index
            if self._is_bad_episode_duration(duration):
                continue
            burst_dict_list = bs_episodes[episode_indices]
            episode_bursts = []
            episode_burst_info = []
            for burst_dict_list_index, burst_dict in enumerate(burst_dict_list):
                if self._burst_has_bad_duration(burst_dict):
                    continue
                burst_data = burst_dict['burst_data']
                data_index = min(len(burst_data), self.pad_length)
                #burst_data = torch.nn.functional.pad(burst_data, (0, self.pad_length - burst_data_len))
                episode_bursts.append(burst_data[:data_index])
                episode_burst_info.append('{}_{}_{}_{}'.format(edf_name, start_index, end_index, burst_dict_list_index))
            episode_bursts, episode_burst_masks, episode_burst_info = self._pad_bursts(episode_bursts, episode_burst_info)
            edf_bursts.extend(episode_bursts)
            edf_burst_masks.extend(episode_burst_masks)
            edf_burst_info.extend(episode_burst_info)
        return np.array(edf_bursts), np.array(edf_burst_masks), edf_burst_info
    
    def __len__(self):
        return len(self.all_bursts)
        
    def __getitem__(self, index):
        burst = self.all_bursts[index]
        mask = self.all_burst_masks[index]
#        if self.downsample_factor is not None:
#            burst = burst[::self.downsample_factor]
#            mask = mask[::self.downsample_factor]
        return dict(burst=torch.FloatTensor(burst), mask=torch.Tensor(mask))
    
    def parse_burst_info(self, burst_info):
        burst_info_pieces = tuple(burst_info.split('_'))
        edf_name = '_'.join(burst_info_pieces[:-3])
        episode_start_index, episode_end_index = int(burst_info_pieces[-3]), int(burst_info_pieces[-2])
        burst_dict_list_index = int(burst_info_pieces[-1])
        return edf_name, episode_start_index, episode_end_index, burst_dict_list_index
        
    def get_burst_by_burst_info(self, burst_info, standardizer, robust):
        edf_name, start_index, end_index, burst_dict_list_index = self.parse_burst_info(burst_info)
        bs_episodes = self.burstReader.get_bs_episodes(edf_name)
        burst_dict_list = bs_episodes[(start_index, end_index)]
        burst_dict = burst_dict_list[burst_dict_list_index]
        burst_data = burst_dict['burst_data']
        burst = np.zeros(self.pad_length)
        mask = np.zeros(self.pad_length)
        data_index = min(len(burst_data), self.pad_length)
        burst[:data_index] = burst_data[:data_index]
        mask[:data_index] = 1
        burst_standardized = standardizer.transform_one_burst(burst, 1-mask, robust=robust)
        return burst_standardized, mask
        
    def get_undownsampled_item(self, index, standardizer, robust):
        # if standardizer and robust are passed in, it will check to make sure
        # we got the right item
        orig_downsampled_burst = self.all_bursts[index]
        burst_info = self.all_burst_info[index]
        burst_standardized, mask = self.get_burst_by_burst_info(burst_info, standardizer, robust)
        assert(self._are_numpy_arrays_equal(burst_standardized[::self.downsample_factor], orig_downsampled_burst))
        return dict(burst=torch.FloatTensor(burst_standardized), mask=torch.Tensor(mask))
    
    def _are_numpy_arrays_equal(self, arr1, arr2):
        assert(len(arr1)==len(arr2))
        for i in range(len(arr1)):
            if abs(arr1[i]-arr2[i]) > 1e-5:
                return False
        return True

class ShuffledBatchSequentialSampler(torch.utils.data.sampler.BatchSampler):
    def __init__(self, data_source, batch_size, drop_last):
        self.data_source = data_source
        self.batch_size = batch_size
        self.drop_last = drop_last
        
        
    def __iter__(self):
        self.data_indices = range(len(self.data_source))
        batch_indices = torch.randperm(len(self)).tolist()
        for batch_idx in batch_indices:
            # batch with batch_idx corresponds to data at indices 
            # [batch_idx * batch_size:batch_idx * batch_size+batch_size]
            start_ind = batch_idx * self.batch_size
            end_ind = min(start_ind + self.batch_size, len(self.data_indices))
            batch = self.data_indices[start_ind:end_ind]
            yield batch
            
    def __len__(self):
        if self.drop_last:
            return len(self.data_source) // self.batch_size
        else:
            return (len(self.data_source) + self.batch_size - 1) // self.batch_size


class FakeBurstDataset(torch.utils.data.Dataset):
    def __init__(self, amp=None, phase_shift=None, freq=None, noise_std = 0.1, dataset_len=10000, pad_len=200):
        self.pad_len = pad_len
        self.amp = amp
        self.phase_shift = phase_shift
        self.freq = freq
        self.noise_std = noise_std
        burst_len = pad_len / 200.
        self.x = np.arange(0, burst_len, 1/200.)
        self.dataset_len = dataset_len
        self.create_dataset()
        
    def __len__(self):
        return self.dataset_len
    
    def create_dataset(self):
        self.all_bursts = np.zeros((self.dataset_len, self.pad_len))
        for i in range(self.dataset_len):
            self.all_bursts[i] = self.generate_item()
            
    def generate_item(self):
        if self.freq is None:
            freq = np.random.uniform(0.75, 1.25)
        else:
            freq = self.freq
        if self.phase_shift is None:
            phase_shift = np.random.uniform(0, 2*np.pi)
        else:
            phase_shift = self.phase_shift
        if self.amp is None:
            amp = np.random.uniform(0.8, 1.2)
        else:
            amp = self.amp
        
        noise = np.random.normal(0, self.noise_std, len(self.x))
        burst = amp * np.sin(2 * np.pi * freq * self.x + phase_shift) + noise
        return burst
        
    def __getitem__(self, index):
        burst = self.all_bursts[index]
        mask = np.ones(len(burst))
        return dict(burst=torch.FloatTensor(burst), mask=torch.Tensor(mask))


# In[ ]:


# %matplotlib inline
# import matplotlib.pyplot as plt
# a = FakeBurstDataset(noise_std=0.1, dataset_len=10000, burst_len=1)


# In[ ]:


# b = a[2]['burst'].numpy()
# plt.plot(b)


# In[ ]:


# from prep_dataset import *
# data_dir = '/Users/tzhan/Dropbox (MIT)/1 mit classes/thesis/script_output/describe_bs'
# d = BurstDataset(min_burst_secs=0.1, max_burst_secs=5, min_episode_mins=10, max_episode_mins=None, sort_len=False)
# d.init_dataset(data_dir, 20)
# a, b, c = d.split(0.60, 0.20, split_sort_len=True)
# standardizer = BurstDatasetStandardizer()
# standardizer.fit_transform(a)
# standardizer.transform(b)
# standardizer.transform(c)

