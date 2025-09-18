import os
import scipy
import scipy.io
import pandas as pd
import numpy as np
import json
from datetime import datetime
import sys
sys.path.append('..')
import utils

# Reads in the output created from running burst suppression detection in the matlab portion 
# of the repository (eg, the output created by running matlab/scripts/run/describe_bs.m) 

class DescribeBsOutputReader:
    def __init__(self, output_dir):
        # output_dir: the path to the directory containing all the output
        #   should contain a subdirectory for each patient, with output for that patient in the 
        #   corresponding subfolder
        # this will be the same as the "output_dir" specified in matlab/config_and_params/Config.m, 
        #   unless you renamed or moved the directory after it was created by the matlab script.
        self.output_dir = output_dir
    
    def get_edf_results(self, edf_name, filter_condition):
        # returns paths to output files for an edf for which filter_condition is true
        patient = utils.get_pt_from_edf_name(edf_name)
        results_dir = os.path.join(self.output_dir, patient, edf_name)
        edf_results = os.listdir(results_dir)
        edf_results = [x for x in edf_results if filter_condition(x)]
        edf_result_paths = [os.path.join(results_dir, x) for x in edf_results]
        return edf_result_paths
        
    def read_zs_bsr(self, edf_name):
        # edf_name: string, name of edf
        # returns zs_bsr_df: dataframe with two columns: 'bsr' and 'global_zs', with the 
        # bsr and global_zs values down the columns, respectively 
        zs_bsr_path = self.get_edf_results(edf_name, lambda x:('zs_bsr' in x and x[-3:]=='csv'))
        assert(len(zs_bsr_path)==1), "number zs_bsr results not 1 for edf {}".format(edf_name)
        zs_bsr_path = zs_bsr_path[0]
        zs_bsr_df = pd.read_csv(zs_bsr_path, delimiter='\t')
        return zs_bsr_df
    
    def get_bsr(self, edf_name):
        # edf_name: string, name of edf
        # returns bsr: vector of bsr values
        zs_bsr_df = self.read_zs_bsr(edf_name)
        bsr = zs_bsr_df[['bsr']].as_matrix().flatten()
        return bsr
    
    def get_global_zs(self, edf_name):
        # edf_name: string, name of edf
        # returns zs: vector of global zs values
        zs_bsr_df = self.read_zs_bsr(edf_name)
        zs = zs_bsr_df[['global_zs']].as_matrix().flatten()
        return zs
    
    def get_bs_episodes(self, edf_name, indices_only=False):
        # returns a dictionary where keys are episodes and values are lists of dictionaries
        # {(episode_start, episode_end):
        #                              [{'burst_data':..., 'burst_start_index':...}, 
        #                               {'burst_data':..., 'burst_start_index':...}]}
        # 'burst_data' is a nonempty list (not numpy array, not float)
        episode_file_paths = self.get_edf_results(edf_name, lambda x:'episode' in x)
        all_episode_burst_dicts = {}
        for episode_file in episode_file_paths:
            filename_splits = (os.path.basename(episode_file)).split('.')[0].split('_')
            assert(filename_splits[-3]=='episode')
            episode_start = int(filename_splits[-2])
            episode_end = int(filename_splits[-1])          
            episode_root_obj = json.load(open(episode_file))
            episode_name = list(episode_root_obj.keys())[0]
            episode_obj = episode_root_obj[episode_name]
            episode_burst_dicts_list = []  # list of dictionaries, where each dictionary has 'burst_data' and 'burst_start_index'
            for burst in episode_obj:
                assert(len(burst)==1)
                burst_dict = burst[0]
                burst_dict['burst_data'] = burst_dict.pop('burst_data')
                burst_dict['burst_start_index'] = burst_dict.pop('burst_start_index')
                if type(burst_dict['burst_data'])==float:
                    burst_dict['burst_data'] = [burst_dict['burst_data']]
                if indices_only:
                    burst_dict['burst_end_index'] = burst_dict['burst_start_index'] + len(burst_dict['burst_data']) - 1
                    del(burst_dict['burst_data'])
                episode_burst_dicts_list.append(burst_dict)
            all_episode_burst_dicts[(episode_start, episode_end)] = episode_burst_dicts_list
        return all_episode_burst_dicts
