from .lsh import *


def slsh_indexing(m_out,
                  L_out,
                  m_in,
                  L_in,
                  X,
                  X_shape,
                  H_out,
                  H_in,
                  alpha,
                  info=False):
    """
    Construct SLSH tables from input data. X is a matrix stored as a 1-D vector in column order.
    The tables contain integers, referring to the "point ID", i.e. its row index in the dataset.

    :param m_out: # of hash functions per outer table
    :param L_out: # of outer hash tables
    :param m_in: # of hash functions per inner table
    :param X: shared dataset
    :param X_shape: tuple containing (n_rows, n_columns)
    :param H_out: outer hash family
    :param H_in: inner hash family
    :param alpha: inner LSH threshold
    :returns: (outer hash tables, outer hash functions, inner hash tables, inner hash functions)
    """
    outer_points = range(X_shape[1])  # Use all points.
    g_out, T_out = lsh_indexing(
        m_out, L_out, X, X_shape, outer_points, H_out, info=info)
    T_in = [None] * L_out  #inner hash tables
    g_in = [None] * L_out  #inner hash functions

    if info:
        print(
            "A core built the outer tables and is now starting inner tables.")

    for l in range(L_out):
        T_in[l] = {}
        g_in[l] = {}

        for key in T_out[l]:
            # This is a populous bucket: add the second SLSH layer using only the points in the bucket.
            if len(T_out[l][key]) >= (alpha * X_shape[1]):
                inner_points = T_out[l][key]
                g_in[l][key], T_in[l][key] = lsh_indexing(
                    m_in, L_in, X, X_shape, inner_points, H_in)

    if info:
        print("A core built the inner tables")

    return (T_out, g_out, T_in, g_in)


def slsh_querying(q, T_out, g_out, T_in, g_in, k, selector, d=L1):
    """
    Query k nearest neighbors to a given input point in the tables' dataset using SLSH.
    Return the dataset point ID's corresponding to these elements.

    :param q: query point, instance of class Query
    :param T_out: outer hash tables
    :param g_out: outer hash functions
    :param T_in: inner hash tables
    :param g_in: inner hash functions
    :param k: # of nearest neighbors to find
    :param d: distance metric function for outer hash table

    :returns: list of k elements' indices closest to q
    """
    # Collect query start timestamp.
    q.time_slsh_start = time()

    L_out = len(g_out)

    for l in range(L_out):
        key = tuple([f(q.point) for f in g_out[l]])
        # If there are candidates in this outer table:
        if key in T_out[l]:
            # If the key is in the g_in[l] dictionary it means that there is a second SLSH layer.
            if key in g_in[l]:
                L_in = len(g_in[l][key])

                for l2 in range(L_in):
                    key2 = tuple([f(q.point) for f in g_in[l][key][l2]])
                    # If there are candidates in this inner table:
                    if key2 in T_in[l][key][l2]:
                        selector.add(T_in[l][key][l2][key2])
            # No second SLSH layer.
            else:
                selector.add(T_out[l][key])

    q.time_linearsearch = time()  # Collect linear search timestamp.
    output = selector.filter(d, k, q, save_comparisons=True)

    # Collect query end timestamp.
    q.time_slsh_end = time()

    return output  # Return the k best candidates.
