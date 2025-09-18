'''
    File containing each non-root's core "main" method.
'''

from worker_node.SLSH.slsh import *
import numpy as np
import random


def execute_core(pipe, barrier, seed, m_out, n_tables, m_in, L_in, dataset,
                 dataset_shape, H_out, H_in, alpha, k):
    '''
    The method each non-root core executes as his main.
    Build and populate the tables, then wait for queries.

    :param pipe: the pipe used for communicating queries.
    :param barrier: barrier used for synchronization.
    :param seed: the random seed which must be used by this core.
    :param m_out: # of hash functions per outer table
    :param n_tables: # of outer hash tables to build locally
    :param m_in: # of hash functions per inner table
    :param L_in: # of inner hash tables
    :param dataset: the shared dataset
    :param dataset_shape: its shape
    :param H_out: outer hash family
    :param H_in: inner hash family
    :param alpha: inner LSH population threshold
    :param k: number of nearest neighbors to retrieve

    :return:
    '''

    # Initialize random seed for process stream independence.
    initialize_prng(seed)

    # Treat shared dataset as numpy array with no copying.
    dataset_as_ndarray = np.frombuffer(
        dataset)  # No-copy method to treat dataset as numpy array.

    # Build tables.
    (T_out, g_out, T_in,
     g_in) = slsh_indexing(m_out, n_tables, m_in, L_in, dataset_as_ndarray,
                           dataset_shape, H_out, H_in, alpha)

    # Synchronize on barrier after table construction.
    barrier.wait()

    # Wait for a query to arrive. When the termination query is sent, return.
    query = get_query(pipe)
    while not_termination(query):
        # Execute query locally.
        selector = NearestPoints(X=dataset_as_ndarray, X_shape=dataset_shape)
        output = slsh_querying(query, T_out, g_out, T_in, g_in, k, selector)

        # Send the local output of the query (and the query with its measurements) to the root.
        pipe.send((output, query))

        # Fetch the next query.
        query = get_query(pipe)


def not_termination(query):
    """
    Returns True if the queries have not terminated.
    (termination is a "terminate" string)

    :param query: the query to check on
    :return: see above
    """

    return query != "terminate"


def initialize_prng(seed):
    """
    Initialize random seed to guarantee independent streams on the different cores.

    :param seed: the seed to use
    :return: nothing
    """

    seed = int(seed % pow(2, 31))
    random.seed(seed)
    np.random.seed(seed)


def get_query(pipe):
    """
    Retrieve with busy waiting (faster, and we have the CPU to do it) the query.

    :param pipe: the pipe to get the query from.
    :return: the query.
    """

    fetched_query = False
    while not fetched_query:
        if pipe.poll(-1):
            query = pipe.recv()
            fetched_query = True

    return query
