import sys
import os
import numpy as np
sys.path.append('..')
import utils
import h5py
import pandas as pd

# Reads in the output created from running similarity in the matlab portion 
# of the repository (eg, the output created by running matlab/scripts/run/write_similarities.m) 
class SimilarityOutputReader:
    def __init__(self, output_dir):
        # output_dir: the path to the directory containing all the output
        #   should contain a subdirectory for each patient, with output for that patient in the 
        #   corresponding subfolder
        # this will be the same as the "output_dir" specified in matlab/config_and_params/Config.m, 
        #   unless you renamed or moved the directory after it was created by the matlab script.
        self.output_dir = output_dir
        
    def _get_similarity_files_for_edf(self, edf_name):
        # returns dictionary of similarity_fn to list of filenames of results
        # list will contain > 1 element when the results are in parts
        # eg, given 'CA_MGH_sid141_01_20140218', returns 
        # {'dtw':['CA_MGH_sid141_01_20140218_142742_dtw_part1_episode_idx_1_13.mat'], 'xcorr':['CA_MGH_sid141_01_20140218_142742_xcorr_part1_episode_idx_1_13.mat']}
        patient = utils.get_pt_from_edf_name(edf_name)
        edf_no_ext = edf_name.split('.')[0]
        patient_files = os.listdir(os.path.join(self.output_dir, patient, edf_no_ext))
        edf_files = [f for f in patient_files if edf_name in f and '.mat' in f]
       
        similarity_files = {'dtw':[], 'xcorr':[]}
        for f in edf_files:
            if 'dtw' in f:
                similarity_files['dtw'].append(f)
            elif 'xcorr' in f:
                similarity_files['xcorr'].append(f)
            else:
                print('File {} with unknown similarity function'.format(f))
        return similarity_files
    
    def _get_burst_ranges_files_for_edf(self, edf_name):
        # returns list of files that contain burst range info for an edf
        patient = utils.get_pt_from_edf_name(edf_name)
        edf_no_ext = edf_name.split('.')[0]
        patient_files = os.listdir(os.path.join(self.output_dir, patient, edf_no_ext))
        edf_files = [f for f in patient_files if edf_name in f]
        burst_ranges_files = [f for f in edf_files if 'burst_ranges' in f and f[-3:]=='csv']
        return burst_ranges_files

    def _read_similarity_matfile(self, similarity_matfile, convert_to_np):
        # returns np array of the data contained inside one similarity matfile 
        # (which is similarity array for one episode in one edf)
        patient = utils.get_pt_from_edf_name(similarity_matfile)
        if 'dtw' in similarity_matfile:
            sim_fn_idx = similarity_matfile.find('dtw')
        elif 'xcorr' in similarity_matfile:
            sim_fn_idx = similarity_matfile.find('xcorr')
        else:
            assert('dtw' in similarity_matfile or 'xcorr' in similarity_matfile)
        edf_name_no_ext = similarity_matfile[:sim_fn_idx-1]
        similarity_output_filepath = os.path.join(self.output_dir, patient, edf_name_no_ext, similarity_matfile)
        ## TODO TODO
        f = h5py.File(similarity_output_filepath, 'r')
        similarity_arr = np.array(f[f.keys()[0]]).transpose()
        # if the similarity_struct is empty, matlab would load properly as [], 
        # but h5py loads it as np array([0, 0], dtype=uint64)
        if np.array_equal(similarity_arr, np.array([0,0])):
            # similarity_struct should be empty
            similarity_arr = np.array([])
        else:
            assert(similarity_arr.shape[0]==1), "similarity_arr must have shape 1 x n"
            assert(len(similarity_arr.shape)==2), "similarity_arr must have shape 1 x n"
            similarity_arr = similarity_arr[0]
            if len(similarity_arr)==0:
                print('len sim is 0')
        return similarity_arr
    
    def _read_burst_ranges_file(self, burst_ranges_file):
        patient = utils.get_pt_from_edf_name(burst_ranges_file)
        burst_ranges_idx = burst_ranges_file.find('burst_ranges')
        edf_name_no_ext = burst_ranges_file[:burst_ranges_idx-1]
        burst_ranges_filepath = os.path.join(self.output_dir, patient, edf_name_no_ext, burst_ranges_file)
        burst_ranges_df = pd.read_csv(burst_ranges_filepath, delimiter='\t')
        return burst_ranges_df.as_matrix()
    
    def flatten_similarities_list(self, similarities_list):
        # takes in the output of get_similarities and returns flat array of all similarities across all episodes
        all_episode_similarities = []
        for episode in similarities_list:
            assert(not episode['similarities'] is None)
            if len(episode['similarities'])==0:
                print('warning: flatten_similarities_list: episode with empty similarity array')
            else:
                # The similarities can be None if there were no bursts
                all_episode_similarities.extend(episode['similarities'])
        return np.array(all_episode_similarities)

    def get_similarities(self, edf_name, similarity_fn, convert_to_np=False, min_episode_length=0):
        # Input:
        #   edf_name: string, name of edf to read output for
        #   similarity_fn: string, must be either "dtw" or "xcorr"
        #   min_episode_length: minimum length of a burst suppression episode to include
        #                   if an episode is shorter than this, it will be ignored
        # Output:
        #   episode_to_similarities_list: list of dictionaries, where each dictionary 
        #       represents a single burst suppression episode in the edf and has 
        #       three keys: "episode_start_index", "episode_end_index", and "similarities" 
        #       The "episode_start_index" and "episode_end_index" values are integers, representing 
        #       the start and end indices of the episode within the eeg, and the "similarities" 
        #       value is a vector containing the similarity scores of the burst pairs
        similarity_matfiles = self._get_similarity_files_for_edf(edf_name)
        similarity_matfile_list = similarity_matfiles[similarity_fn]
        min_episode_s_length = utils.min_to_samples(min_episode_length)
        episode_to_similarities_list = []
        for similarity_matfile in similarity_matfile_list:
            # each similarity_matfile corresponds to one episode for this edf
            assert('part' in similarity_matfile), 'similarity mat output {} without "part" in name'.format(similarity_matfile)
            episode_dict = {}
            similarity_matfile_pieces = (similarity_matfile.split('.')[0]).split('_')
            episode_dict['episode_start_index'] = int(similarity_matfile_pieces[-2])
            episode_dict['episode_end_index'] = int(similarity_matfile_pieces[-1])
            if episode_dict['episode_end_index'] - episode_dict['episode_start_index'] < min_episode_s_length:
                continue
            episode_dict['similarities'] = self._read_similarity_matfile(similarity_matfile, convert_to_np)
            episode_to_similarities_list.append(episode_dict)
        return episode_to_similarities_list
    
    def get_burst_ranges(self, edf_name):
        # returns dictionary whose keys are (episode_start_index, episode_end_index) and whose values
        # are the matrix of burst ranges used in creating the similarities for that episode
        # this is the python equivalent of the filtered_burst_ranges_cell 
        # object in the matlab repository (see matlab/pipeline/similarity/similarity.m)
        burst_ranges_files = self._get_burst_ranges_files_for_edf(edf_name)
        episode_to_burst_ranges = {}
        for burst_ranges_file in burst_ranges_files:
            burst_ranges = self._read_burst_ranges_file(burst_ranges_file)
            burst_ranges_file_pieces = (burst_ranges_file.split('.')[0]).split('_')
            episode_start_index = int(burst_ranges_file_pieces[-2])
            episode_end_index = int(burst_ranges_file_pieces[-1])
            episode_to_burst_ranges[(episode_start_index, episode_end_index)] = burst_ranges
        return episode_to_burst_ranges
