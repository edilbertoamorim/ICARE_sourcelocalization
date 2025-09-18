# Various utility functions

import os
import scipy
import scipy.io
import pandas as pd
import numpy as np
from datetime import datetime

########### Utilities for converting between samples and time ##################################

def sec_to_samples(s):
    # convert seconds to number of samples
    # assumes 200 is the sample rate
    return s*200

def samples_to_sec(s):
    # convert number of samples to seconds
    # assumes 200 is the sample rate
    return s/200.0

def samples_to_min(s):
    return samples_to_sec(s)/60.0

def min_to_samples(s):
    return sec_to_samples(s)*60

def samples_to_hour(s):
    return samples_to_min(s)/60.0

def hour_to_samples(s):
    return min_to_samples(s)*60

########### Utilities defining what outcomes are good vs bad ##################################

def is_good_outcome(outcome):
    # returns if an outcome (integer from 1 to 5) is good
    # if outcome is -1, meaning unavailable, returns False
    if outcome==-1:
        return False
    return {1:True, 2:True, 3:False, 4:False, 5:False}[outcome]
    
def is_bad_outcome(outcome):
    # returns if an outcome (integer from 1 to 5) is bad
    # if outcome is -1, meaning unavailable, returns False
    # Note: this is not the opposite of is_good_outcome because
    #   they are both False if outcome==-1
    if outcome==-1:
        return False
    return not is_good_outcome(outcome)


########### Utilities for parsing edfs, specific to the csail/icare dataset ##################################

def convert_new_pname_to_new_sid(pname):
    # converts eg, "mgh_2" to "mgh2"
    hosp, id_ = parse_patient_name(pname)
    return '{}{}'.format(hosp, id_)

def convert_new_sid_to_new_pname(pname):
    # converts eg, "mgh2" to "mgh_2"
    hosp, id_ = parse_patient_name(pname)
    return '{}_{}'.format(hosp, id_)
    
def get_pt_from_edf_name(f):
    # Takes in an edf name from the csail/icare dataset and returns the patient it is associated with
    # Ex: get_pt_from_edf_name("mgh_12_1_0_20000101_111111") returns "mgh_12"
    # Note: Be careful, and note that this returns the patient name format
    #       with an underscore before the id number! Some of the other files, 
    #       such as exclude list and outcomes, use the format without underscore. 
    f = os.path.basename(f)
    if 'CA_BIDMC' in f:
	    return ('_').join(f.split('_')[:3])
    if 'CA_MGH' in f:
        return ('_').join(f.split('_')[:3])
    return ('_').join(f.split('_')[:2])

def convert_datetime_to_timestamp(datetime):
    # convert a datettime object to a timestamp string
    return "{:%Y%m%d_%H%M%S}".format(datetime)

def convert_timestamp_to_datetime(timestamp):
    # convert a timestamp string to a datetime object
    return datetime.strptime(timestamp,"%Y%m%d_%H%M%S")

def parse_edf_name(edf, sort_by_ts=False, ts_datetime=False):
    # takes in an edf name from the csail/icare dataset and 
    # parses the pieces
    #
    # Eg: parse_edf_name("mgh_12_1_0_20000101_111111")
    #       -> "mgh", 12, 1, 0, 20000101,111111 
    #
    # If sort_by_ts is True, the returned tuple will have the date 
    #   part listed before the record number and segment number:
    #   Eg: parse_edf_name("mgh_12_1_0_20000101_111111", sort_by_ts=True)
    #       -> "mgh", 12, 20000101,111111, 1, 0
    # If ts_datetime is True, the returned date and time part will be
    # a python datetime object
    #   Eg: parse_edf_name("mgh_12_1_0_20000101_111111", ts_datetime=True)
    #       -> "mgh", 12, datetime(20000101, 111111), 1, 0

    if pd.isnull(edf):
        return edf, None, None, None, None, None
    if 'e not f' in edf:
        return '~'+edf, None, None, None, None, None
    edf = os.path.splitext(edf)[0]
    pt_name = get_pt_from_edf_name(edf)
    hosp, id_ = parse_patient_name(pt_name)
    if 'CA_BIDMC' in edf or 'CA_MGH' in edf:
        pieces = edf.split('_')[3:]
    else:
        pieces = edf.split('_')[2:]
    if 'T' in pieces[-1]:
        new_pieces = pieces[-1].split('T')
        assert(len(new_pieces)==2)
        pieces.pop()
        pieces.append(new_pieces[0])
        pieces.append(new_pieces[1])
    assert(len(pieces)==3 or len(pieces)==4)
    record_num = int(pieces[0])
    datetime_obj = convert_timestamp_to_datetime('_'.join(pieces[-2:]))
    date = int(pieces[-2])
    ts = int(pieces[-1])
    if len(pieces)==4:
        segment_num = int(pieces[1])
    else:
        segment_num = None
    if sort_by_ts:
        if ts_datetime:
            return hosp, id_, datetime_obj, record_num, segment_num
        return hosp, id_, date, ts, record_num, segment_num
    if ts_datetime:
        return hosp, id_, record_num, segment_num, datetime_obj
    return hosp, id_, record_num, segment_num, date, ts
        
def parse_patient_name(patient):  
    # input: patient - a string containin the hospital and the patient id number
    # return hospital piece as string, and id as integer
    return parse_out_patient_hosp(patient), parse_out_patient_id(patient)

def parse_out_patient_hosp(patient):
    # parse out the hospital from old or new naming scheme
    hosps_new_naming = ['bi', 'mgh', 'ynh', 'bwh']
    hosps_our_naming = ['CA_BIDMC', 'CA_MGH', 'ynh', 'bwh']
    match = False
    for hosp in hosps_new_naming + hosps_our_naming:
        if hosp in patient:
            match = True
            break
    assert(match==True), "patient {} matched no hospital".format(patient)
    return hosp

def parse_out_patient_id(patient):
    # parses out the id from the old or new naming scheme
    chars = []
    for c in patient:
        if str.isdigit(c):
            chars.append(c)
        else:
            assert(len(chars)==0)
    pid = int(''.join(chars))
    return pid

########### Random other utilities ##################################

def read_list(fn):
    # reads a txt file, returns a list containing each line of the file
    list_ = []
    with open(fn, 'r') as f:
        for l in f.readlines():
            list_.append(l.strip())
    return list_

def df_to_dict(df):
    # takes df with one column of index:value and makes it a dict
    column_0 = df.columns[0]
    if len(df.columns)==2:
        df = df.set_index(column_0)
    column = df.columns[0]
    df_dict = df.to_dict(orient='index')
    dicti = {}
    for d in df_dict:
        dicti[d] = df_dict[d][column]
    return dicti

def filter_by_pt(collection, pt):
    # collection: a list or dictionary
    # pt: a string, or a list of patients to filter by
    collection = [x for x in collection if not pd.isnull(x)]
    if type(pt)==str:
        pt = '{}_'.format(pt)
        return [x for x in collection if pt in x]
    elif type(pt)==list:
        return [x for x in collection if any(['{}_'.format(p) in x for p in pt])]

