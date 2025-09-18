from .selectors import *
from time import time
import numpy as np


def L1(x, y):

    return np.linalg.norm(x - y, 1)


"""
Alternative way of hashing (slower according to some tests):
function = lambda index: g[l][index](x)
vfunction = np.vectorize(function)
key = np.fromfunction(vfunction, (len(g[l]),), dtype=int).data.tobytes()
"""

#TODO: possible optimization. Use numpy to store indices, this needs pre-allocation and striving not to change the size too much.


def lsh_indexing(m, L, X, X_shape, points, H, info=False):
    """
    Construct hash tables using randomly sampled member of H to LSH the elements of the dataset X contained in points.
    X is a matrix stored as a 1-D vector in column order.
    The tables contain integers, referring to the "point ID", i.e. its column index in the dataset.
    points refers to the points of the dataset that have to be hashed by point ID.

    :param m: # of hash functions per table
    :param L: # of hash tables
    :param X: shared dataset
    :param X_shape: tuple containing (n_rows, n_columns)
    :param points: list of dataset points to hash
    :param H: hash family
    :returns: (hash functions, list of hash tables)
    """

    g = [
        None
    ] * L  # Store the g instance for each table. g is the concatenation of m hashes from H.
    T = [None] * L

    for l in range(L):

        g[l] = [H.sample_fn() for j in range(m)]  #H is a hash family instance
        T[l] = collections.defaultdict(list)

        for i in points:
            x = X[i * X_shape[0]:(
                i + 1) * X_shape[0]]  # Access the current datapoint.

            key = tuple([f(x) for f in g[l]])
            T[l][key].append(i)

        if info:
            print("A core built table {}".format(l))

    return (g, T)


def lsh_querying(q, T, g, k, selector, d=L1):
    """
    Find the k "nearest" elements in the dataset hashed in the LSH tables to a given input point.
    Return the dataset point ID's corresponding to these elements.

    :param q: query point, instance of class Query
    :param T: hash tables
    :param g: hash family instances for each table
    :param k: number of neighbors to find
    :param d: distance metric for hash family used
    :param selector: function that filters best k

    :returns: list of k nearest points' indices.
    """
    # Collect query start timestamp.
    q.time_start = time()

    L = len(g)

    for l in range(L):
        key = tuple([f(q.point) for f in g[l]])
        # If there are candidates in this table:
        if key in T[l]:
            selector.add(
                T[l][key])  # Add to the selector the lists of candidates.

    q.time_linearsearch = time()  # Collect linear search timestamp.
    output = selector.filter(d, k, q, save_comparisons=True)

    # Collect query end timestamp.
    q.time_end = time()

    return output  # Return the k best candidates.
