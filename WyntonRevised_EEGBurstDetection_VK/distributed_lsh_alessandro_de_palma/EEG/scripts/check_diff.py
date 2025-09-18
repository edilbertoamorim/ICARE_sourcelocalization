import os

def check_diff():
    """
    Check consistency between file ordering obtained with internal and external timestamps.
    RESULTS:
        MGH and BIDMC are consistent.
        BWH and yale get different results.
    """

    os.system("find /afs/csail.mit.edu/u/a/adepalma/NFS/EEG-dataset/patients-internal-timestamp -print | grep \"patient_\" > temp_list.txt")

    with open("temp_list.txt", "r") as file:

        for line in file:
            (path, filename)  = os.path.split(line)

            if line.strip().split("/")[9] == "MGH" or line.strip().split("/")[9] == "BIDMC":
                os.system("diff {} /afs/csail.mit.edu/u/a/adepalma/NFS/EEG-dataset/patients/{}/{}".format(line.strip(), line.strip().split("/")[9], filename))

    return


if __name__ == "__main__":

    check_diff()
