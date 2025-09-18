
import pandas as pd
import numpy as np
import os

import sys
sys.path.append('..')
import utils

# reads in the patient information given in the patient_info_dir, 
# or the patient_info directory of the repository

# NOTE: the patient_info directory MUST be updated for YOUR SPECIFIC DATASET
#   Our patient_info directory files are specific to the csail dataset only

class PatientInfo:
    def __init__(self, patient_info_dir,
                merge_info_csv='merge_info.csv',
                exclude_list='exclude_patient_sids.txt',
                outcome_csv='new_outcomes.csv'
                ):
        # patient_info_dir: directory containing the merge_info_csv, exclude_list, and outcome_csv
        # merge_info_csv: name of the csv containing list of edfs and timestamps for 
        #   all patients
        # exclude_list: name of the txt file containing sids of patients to be excluded
        # outcome_csv: name of the csv contiaining patient outcomes

        merge_info_csv = os.path.join(patient_info_dir, merge_info_csv)
        exclude_list = os.path.join(patient_info_dir, exclude_list)
        outcome_csv = os.path.join(patient_info_dir, outcome_csv)
 
        self.merge_info_df = pd.read_csv(merge_info_csv)
        self.exclude_patients = utils.read_list(exclude_list)
        self.outcomes_df = pd.read_csv(outcome_csv, index_col=0)
    
    def is_excluded(self, new_sid):
        # returns whether or not patient is in the exclude list
        return new_sid in self.exclude_patients
    
    def get_all_sids(self):
        # returns list of all new sids in patient_merge_info
        # Note that none of the sids in the merge info csv are in the exclude list 
        all_sids = list(set(list(self.merge_info_df['sid'])))
        all_sids.sort(key=utils.parse_patient_name)
        return all_sids
    
    def get_edfs_and_indices(self, new_sid, max_num_hours=72):
        # for a new sid (ie, an sid in the icare dataset format, not the old 
        # csail dataset format), returns all the edfs and start/end indices of each edf
        # in the merged data record, taking the first occurring timestamp as index 0, and
        # assuming sample rate of 200. 
        #
        # max_num_hours: maximum duration of the merged data record. 
        #
        # Note: edfs with unreliable timestamps are ignored. "First occuring timestamp" is the first
        # reliable timestamp for a patient. "Reliable" means that either the 
        # "is_timestamp_guessed_from_old_edf_name" column is false, or the 
        # "is_guessed_timestamp_correct_seeming" column is true
        #
        # the return object is a list of tuples, like [(edf_name, start_index, end_index), ...] 
        #
        # Ex: get_edfs_and_indices('bi2')
        # -> [('CA_BIDMC_2_5_20130927_100601', 0, 7811840), ('CA_BIDMC_2_6_20130927_205703', 7812400, 15048240), 
        #     ('CA_BIDMC_2_1_20130928_070114', 15062800, 22874640), ('CA_BIDMC_2_2_20130928_175216', 22875200, 30687040), 
        #     ('CA_BIDMC_2_3_20130929_044319', 30687800, 32328760), ('CA_BIDMC_2_4_20130929_070115', 32342800, 34587920)] 
        
        rows = self.merge_info_df[self.merge_info_df['sid']==new_sid]
        max_index = utils.hour_to_samples(max_num_hours) - 1
        edfs_and_indices = []
        if len(rows)==0:
            return edfs_and_indices
        reference_timestamp = self._get_reference_timestamp(rows)
        if reference_timestamp is None:
            return edfs_and_indices
        for i, row in rows.iterrows():
            start_timestamp = row['timestamp']
            nsamples = row['nsamples']
            timestamp_guessed = row['is_timestamp_guessed_from_old_edf_name']
            if not self._is_timestamp_okay(row):
                continue
            start_index = self._convert_timestamp_to_index(reference_timestamp, start_timestamp)
            if start_index >= max_index:
                continue
            end_index = int(min(start_index + nsamples, max_index))
            edfs_and_indices.append((row['csail_edf_name'], start_index, end_index))
        edfs_and_indices = [x for x in edfs_and_indices if not self._is_edf_redundant(x, edfs_and_indices)]
        return edfs_and_indices
    
    def get_edf_duration(self, edf_name):
        # returns the duration, in number of samples, of an edf
        merge_info_row = self.merge_info_df[self.merge_info_df['csail_edf_name']==edf_name]
        if len(merge_info_row)==0:
            print('edf {} not in merge_info.csv'.format(edf_name))
        assert(len(merge_info_row)==1), 'Must be exactly 1 row in merge_info.csv matching edf {}'.format(edf_name)
        return int(merge_info_row['nsamples'])
        
    def has_good_outcome(self, patient_sid, vb=False):
        # returns if the patient has a good outcome
        # see utils.has_good_outcome
        outcome = self.get_outcome(patient_sid, vb)
        return utils.is_good_outcome(outcome)
    
    def has_bad_outcome(self, patient_sid, vb=False):
        # returns if the patient has a bad outcome
        # see utils.is_bad_outcome 
        outcome = self.get_outcome(patient_sid, vb)
        return utils.is_bad_outcome(outcome)
    
    def get_patient_clinical_info(self, patient_sid):
        # returns a pandas series containing the row of outcomes_csv
        # that corresponds to the patient with patient_sid
        return self.outcomes_df.loc[patient_sid]
    
    def get_outcome(self, patient_sid, vb=False):
        # returns the outcome of the patient (either 1-5, or -1 if no outcome is found)
        try:
            outcome = self.outcomes_df['bestCpcBy6Mo'][patient_sid]
        except KeyError:
            if vb:
                if patient_sid in self.exclude_patients:
                    print('{} excluded'.format(patient_sid))
                else:
                    print('KeyError on {}'.format(patient_sid))
            return -1
        if np.isnan(outcome):
            if vb:
                if patient_sid in self.exclude_list:
                    print('{} excluded'.format(patient_sid))
                else:
                    print('Isnan outcome on {}'.format(patient_sid))
            return -1
        return outcome
    
    def _convert_timestamp_to_index(self, reference_timestamp, timestamp):
        # converts timestamp to index relative to reference_timestamp being index 0
        reference_datetime = utils.convert_timestamp_to_datetime(reference_timestamp)
        datetime = utils.convert_timestamp_to_datetime(timestamp)
        timediff_secs = (datetime-reference_datetime).total_seconds()
        timediff_samples = utils.sec_to_samples(timediff_secs)
        return int(timediff_samples)
    
    def _get_reference_timestamp(self, rows):
        # returns the first row in the dataframe "rows" whose timestamp 
        # is reliable

        # rows - a pandas dataframe containing rows from the merge_info csv
        
        for i, row in rows.iterrows():
            if self._is_timestamp_okay(row):
                return row['timestamp']
            
    def _is_timestamp_okay(self, row):
        # returns whether or not the timestamp is reliable, which we define as either:
        # - the is_timestamp_guessed_from_old_edf_name is False
        # OR - the _is_guessed_timestamp_correct_seeming is True
        timestamp_guessed = row['is_timestamp_guessed_from_old_edf_name']
        if timestamp_guessed:
            guessed_timestamp_okay = row['is_guessed_timestamp_correct_seeming']
            assert(not pd.isnull(guessed_timestamp_okay)), 'guessed_timestamp_null {}'.format(row)
            if not guessed_timestamp_okay:
                return False
        return True
    
    def _is_edf_redundant(self, edf_and_index, edfs_and_indices):
        # for edf, returns whether or not its range [start_index-end_index] is contained entirely 
        # inside another edf's range
        edf, start_index, end_index = edf_and_index
        for edf_other, start_index_other, end_index_other in edfs_and_indices:
            if edf==edf_other:
                continue
            if start_index >= start_index_other and end_index<=end_index_other:
                return True
        return False
            
