"""
    Rename files according to the timestamp corrections.
    Must be executed from timestamps-corrections folder and assumes all the spreadsheets are in place.
"""

import pandas as pd

def rename_BWH():

    xl = pd.ExcelFile("timestamps-corrections/MGH_BWH_data_EDF_demographics.xlsx")  # Open file.
    df = xl.parse(xl.sheet_names[0], header=None)  # Open correct sheet for the first name conversion.
    # df[i] indices the i-th column, which is a list of elements.

    # Create map from current file name to the original file name (corrections spreadsheets use them).
    original_name_map = dict()
    for index in range(len(df[0])):
        original_name_map[df[]]
