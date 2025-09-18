import multiprocessing
from math import ceil
from worker_node.core import *
from worker_node.utils.logging_node import TableConstructionLog
from worker_node.middleware_interface import MiddlewareInterface
from time import time
from sklearn.neighbors import NearestNeighbors
import numpy as np
import gc  # Garbage collector.
'''
    This file contains the method to execute a node from the root's perspectiv                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          e.
'''


def share_dataset(X):
    '''
    Convert the dataset matrix X into a 1-D array in column order (inevitable) and share it with the other processors.

    :param X: the dataset matrix
    :return: the shared dataset array
    '''

    size = np.shape(X)[0] * np.shape(X)[1]

    # Create a shared array of doubles without an automatic lock (it will be used only for reading).
    dataset = multiprocessing.Array(
        'd', np.reshape(np.transpose(X), size), lock=False)

    return dataset, np.shape(X)[0], np.shape(X)[1]


def spawn_cores(cores, barrier, seeds, m_out, L_out, m_in, L_in, dataset,
                dataset_shape, H_out, H_in, alpha, k):
    '''
    Spawn the processes for the non-root cores. Then let them build their share of tables.
    Everyone synchronizes on a barrier after table construction.

    :param cores: the number of cores
    :param barrier: barrier to synchronize on after table construction
    :param seeds: the random seeds which must be used by the cores.
    :param m_out: # of hash functions per outer table
    :param L_out: total (across processes) # of outer hash tables
    :param m_in: # of hash functions per inner table
    :param L_in: # of inner hash tables
    :param dataset: the shared dataset
    :param dataset_shape: its shape
    :param H_out: outer hash family
    :param H_in: inner hash family
    :param alpha: inner LSH population threshold
    :param k: number of nearest neighbors to retrieve

    :return: (list of processes, list of pipes)
    '''

    processes = []
    pipes = []
    n_tables = ceil(float(L_out) / cores)
    for i in range(0, cores - 1):
        # Build a biridectional communication pipe for interprocess communication.
        root_pipe, core_pipe = multiprocessing.Pipe(duplex=True)
        pipes.append(root_pipe)

        # Each process calls execute_core, which build the tables and then waits for queries.
        process = multiprocessing.Process(
            target=execute_core,
            args=(core_pipe, barrier, seeds[i + 1], m_out, n_tables, m_in,
                  L_in, dataset, dataset_shape, H_out, H_in, alpha, k))
        processes.append(process)
        process.start()

    return processes, pipes


def execute_queries(processes,
                    pipes,
                    T_out,
                    dataset,
                    dataset_shape,
                    g_out,
                    T_in,
                    g_in,
                    k,
                    queries=[],
                    distributed=False,
                    interface=None,
                    labels=[],
                    exhaustive=False):
    '''
    Execute all the queries in parallel and return their output.
    Partial results are filtered sequentially on the root.
    Wait on the processes to terminate before returning.

    :param queries: list of queries to perform
    :param processes: list of processes
    :param pipes: list of communication pipes (one per process)
    :param T_out: list of outer tables
    :param dataset: the shared dataset
    :param dataset_shape: its shape
    :param g_out: list of outer hash functions
    :param T_in: list of inner tables
    :param g_in: list of inner hash functions
    :param k: number of nearest neighbors to retrieve
    :param labels: list of labels for the dataset points. If non-empty, then we are performing prediction locally.
    :param exhaustive: flag for whether exhaustive search should be run instead of slsh.

    :return: list of Query instances.
    '''

    slsh = not exhaustive

    query_number = 0  # The current query number (a counter).
    sampling_ratio = 20  # The sampling ratio for printing queries.

    if not distributed:
        n_queries = len(queries)
    else:
        queries = [
        ]  # Store the queries and return them for instrumentation purposes.

    if exhaustive:
        # Set up scikit model.
        scikitmodel = NearestNeighbors(
            n_neighbors=k,
            algorithm='brute',
            metric='manhattan',
            n_jobs=processes)
        scikitmodel.fit(dataset)
    elif slsh:
        other_cores = len(pipes)  # The number of non-root cores.

    while True:

        query_results = []  # Store each query's partial results.
        query_measurement_list = [
        ]  # Store the processing times across all cores.

        if not distributed:
            query = queries[query_number]
        else:
            query = interface.receive_query()
            # If the queries have ended,query_measurement_list send termination message and close interface.
            if query == False:
                interface.send_termination()
                interface.close()
                break
            queries.append(query)
        query_measurement_list.append(query)

        # INFO.
        if query_number % sampling_ratio == 0:
            print("Start to process query {}.".format(query_number))

        # Start measuring the intranode total query processing time.
        time_node_start = time()

        if slsh:
            # Send the query to the other cores.
            for pipe in pipes:
                pipe.send(query)

            # Perform the query locally.
            selector = NearestPoints(X=dataset, X_shape=dataset_shape)
            root_output = slsh_querying(query, T_out, g_out, T_in, g_in, k,
                                        selector)
            query_results.append(root_output)

            # Retrieve the partial outputs. This is done with busy waiting (which performs better).
            retrieved_results = 0
            while retrieved_results < other_cores:
                active_pipes = multiprocessing.connection.wait(
                    pipes, timeout=-1)  # Return immediately
                for pipe in active_pipes:
                    core_output = pipe.recv(
                    )  # Block if the core has not finished yet.
                    query_results.append(
                        core_output[0])  # Append the query result.
                    query_measurement_list.append(
                        core_output[1])  # Append the query measurements.
                    retrieved_results += 1

            # Filter the partial outputs sequentially on the root.
            selector = NearestPoints(X=dataset, X_shape=dataset_shape)

            for partial_result in query_results:
                selector.add(partial_result)
            # Gather this node's output for the query.
            local_query_result = np.array(
                selector.filter(L1, k, query), dtype=int)

        else:
            # Exhaustive search.
            local_query_result = scikitmodel.kneighbors(
                X=query.point.reshape(1, -1),
                return_distance=False)[0].astype(int)

        # Stop measuring the intranode total query processing time.
        time_node_end = time()

        # Keep as query the one with the max query time across all cores.
        query = max(
            query_measurement_list,
            key=lambda q: q.time_slsh_end - q.time_slsh_start)
        query.comparisons = max([
            q.comparisons for q in query_measurement_list
        ])  # Store max number of comparisons per query.
        query.time_node_start = time_node_start
        query.time_node_end = time_node_end

        # Update query output.
        query.neighbors = indices_to_points(
            local_query_result, dataset, dataset_shape, exhaustive=exhaustive)
        # Store neighbor's labels, if they are available.
        if len(labels) > 0:
            query.neighbors_labels = labels[local_query_result].tolist()

        queries[query_number] = query
        query_number += 1  # Update query number.

        if not distributed:
            # Check for end of queries.
            if query_number >= n_queries:
                break

            # INFO.
            if query_number % sampling_ratio == 0:
                print("Query input: {} \nQuery output: {}".format(
                    query.point,
                    indices_to_points(
                        local_query_result,
                        dataset,
                        dataset_shape,
                        exhaustive=exhaustive)))

        # Send the output of the current query to the middleware in the distributed setting.
        else:
            interface.send_query_output(query)

            # INFO.
            if query_number % sampling_ratio == 0:
                print("Query input: {} \nQuery output: {}".format(
                    query.point, query.neighbors))

    if slsh:
        # Terminate all the processes by sending a terminate message to the pipes.
        send_termination_cores(pipes)

        # Wait for all the processes to quit.
        for process in processes:
            process.join()

    return queries


def execute_node(cores,
                 k,
                 m_out,
                 L_out,
                 m_in,
                 L_in,
                 H_out,
                 H_in,
                 alpha,
                 X=[],
                 queries=[],
                 distributed=False,
                 port=1025,
                 labels=[],
                 prediction=False,
                 exhaustive=False):
    """
    Share the input dataset X.
    Build ceil(L_out/p) tables per core and hash the shared dataset into them.
    Finally, execute queries queries.

    :param cores: number of cores per machine.
    :param X: the input dataset, a numpy matrix where a column is a point.
    :param queries: the list of queries to perform.
    :param k: the number of nearest neighbors to retrieve.
    :param m_out: # of hash functions per outer table
    :param L_out: the total number of outer tables to build (distributed across the cores)
    :param m_in: # of hash functions per inner table
    :param L_in: # of inner hash tables
    :param H_out: outer hash family
    :param H_in: inner hash family
    :param alpha: inner LSH population threshold
    :param distributed: if True, dataset and queries come from a middleware. Otherwise, execute locally (and dataset and queries must be provided).
    :param port: the port to accept connections on.
    :param labels: list of labels for the dataset points. If non-empty, then we are performing prediction locally.
    :param prediction: flag for whether we should perform prediction in the distributed setting.
    :param exhaustive: flag for whether exhaustive search should be run instead of slsh.

    :return: A TableConstructionLog instance and the queries themselves (containing their output).
    """

    slsh = not exhaustive

    if not distributed and (len(X) == 0 or len(queries) == 0):
        raise ValueError("Local execution needs dataset and queries upfront.")

    if distributed and len(labels) > 0:
        raise ValueError(
            "Labels should be provided only for local execution of the system in prediction mode."
        )

    # INFO.
    print("Node up and running.")

    if distributed:
        interface = MiddlewareInterface(address=('', port))
        # Receive seeds from the middleware.
        seeds = interface.receive_seeds()
        # Retrieve dataset from middleware.
        X = interface.receive_dataset()
        if prediction:
            # Retrieve labels from middleware.
            labels = interface.receive_labels()
        # INFO.
        print("Dataset received.")
    else:
        interface = []
        seeds = generate_seeds(cores)

    # Initialize root's PRNG's. This guarantees both core streams' independence and that the nodes use the same functions.
    initialize_prng(seeds[0])

    if slsh:

        # This part of the code is sequential, on the root process.
        dataset, n_rows, n_columns = share_dataset(
            X
        )  # This is preprocessing time, not included in algorithm measurements.
        dataset_shape = (n_rows, n_columns)
        X = None
        gc.collect()  # Free memory

        print("Dataset shape: {}".format(dataset_shape))

        barrier = multiprocessing.Barrier(
            cores)  # Create a barrier for all the cores.

        # INFO.
        print("Started table construction.")

        # Set timestamp for table construction start.
        table_log = TableConstructionLog()
        table_log.time_start = time()

        # Spawn processes (it gets parallel, now).
        processes, pipes = spawn_cores(cores, barrier, seeds, m_out, L_out,
                                       m_in, L_in, dataset, dataset_shape,
                                       H_out, H_in, alpha, k)

        # Treat shared dataset as numpy array with no copying.
        dataset_as_ndarray = np.frombuffer(
            dataset)  # No-copy method to treat dataset as numpy array.

        # The root builds its own tables.
        root_tables = L_out - ceil(L_out / cores) * (cores - 1)
        (T_out, g_out, T_in, g_in) = slsh_indexing(
            m_out,
            root_tables,
            m_in,
            L_in,
            dataset_as_ndarray,
            dataset_shape,
            H_out,
            H_in,
            alpha,
            info=True)

        # INFO.
        print("Waiting for the other cores to terminate table construction.")
        # Synchronize on barrier after table construction.
        barrier.wait()
        # Notify the middleware that the tables have been constructed.
        if distributed:
            interface.send_table_construction_notification()

        # Set timestamp for table construction end.
        table_log.time_end = time()

        # INFO.
        print("Table construction terminated.")

    else:
        # Exhaustive search.
        dataset_as_ndarray = X.T
        dataset_shape = np.shape(dataset_as_ndarray)
        processes = cores
        # Dummy arguments, not used.
        pipes = None
        T_out = None
        g_out = None
        T_in = None
        g_in = None
        table_log = TableConstructionLog()

    # Execute all the queries in parallel and retrieve their output.
    queries = execute_queries(
        processes,
        pipes,
        T_out,
        dataset_as_ndarray,
        dataset_shape,
        g_out,
        T_in,
        g_in,
        k,
        queries=queries,
        distributed=distributed,
        interface=interface,
        labels=labels,
        exhaustive=exhaustive)

    # INFO.
    print("Queries ended, terminating.")

    # The code is sequential again.

    return table_log, queries


def indices_to_points(indices, X, X_shape, exhaustive=False):
    """
    Convert point ID's (here, indices) to points.

    :param indices: the point ID's
    :param X: the shared dataset
    :param X_shape: its shape
    :param exhaustive: for exhaustive search, the conversion behaves differently

    :return: a list of points
    """

    if not exhaustive:
        return [X[i * X_shape[0]:(i + 1) * X_shape[0]] for i in indices]
    else:
        return [X[i, :] for i in indices]


def send_termination_cores(pipes):
    """
    Send termination (a "terminate" string) to all the non-root cores.

    :param pipes: the list of the pipes on which to communicate to the other cores.
    :return: nothing
    """

    for pipe in pipes:
        pipe.send("terminate")


def generate_seeds(cores):
    """
    Generate the seeds each core uses. This function is used in case of single node usage.
    Without it, the hash functions used by each core would be identical.

    :param cores: number of cores

    :return: the list of seeds
    """

    # The list of seeds is a function of the current system time.
    seeds = [time() * (i + 1) for i in range(cores)]

    return seeds
