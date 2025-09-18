"""
Utils for handling ABP datasets.

"""

import numpy as np
import pickle
from math import ceil


def sample_dataset_and_queries(filename, n_queries):
    """
    From file filename pickle a dataset with the given rate of positives
    and n_queries random queries which will not be in the dataset.
    The dataset (and queries) format is a (point as numpy array, label) list.

    :param filename: the name of the file
    :return: nothing
    """

    positives = []
    negatives = []

    with open("datasets/" + filename, "r") as file:
        for line in file:
            split_label = line.split(" - ")
            point_string = split_label[0].split(" ")
            clabel = int(split_label[1])
            point = np.array([float(x) for x in point_string])

            if clabel == 0:
                negatives.append((point, clabel))
            else:
                positives.append((point, clabel))

    pos = len(positives)
    neg = len(negatives)
    n = pos + neg

    # Permute both positive and negatives.
    positives_order = np.random.permutation(len(positives))
    negatives_order = np.random.permutation(len(negatives))

    query_indices = np.sort(np.random.choice(n, size=n_queries, replace=False))
    # Enforce at least 20 positives are in the set.
    positive_queries = len([i for i in query_indices if i < len(positives)])
    while positive_queries <= 20:
        query_indices = np.sort(
            np.random.choice(n, size=n_queries, replace=False))
        positive_queries = len(
            [i for i in query_indices if i < len(positives)])

    queries = []
    dataset = []
    counter = 0
    query_index = 0

    for i in positives_order:
        cpositive = positives[i]
        if query_index < n_queries:
            if counter == query_indices[query_index]:
                queries.append(cpositive)
                counter += 1
                query_index += 1
                continue
        dataset.append(cpositive)
        counter += 1

    for i in negatives_order:
        cnegative = negatives[i]
        if query_index < n_queries:
            if counter == query_indices[query_index]:
                queries.append(cnegative)
                counter += 1
                query_index += 1
                continue
        dataset.append(cnegative)
        counter += 1

    with open("datasets/" + filename[:len(filename) - 5] + "-dataset.pickle",
              'wb') as file:
        pickle.dump(dataset, file)

    with open("datasets/" + filename[:len(filename) - 5] + "-queries.pickle",
              'wb') as file:
        pickle.dump(queries, file)


if __name__ == "__main__":

    filename = [
        "MIMICIII-ABP-AHE-lag30m-cond30m.data",
        "MIMICIII-ABP-AHE-lag5m-cond5m.data"
    ]
    n_queries = 2000

    for cfilename in filename:
        sample_dataset_and_queries(cfilename, n_queries)
