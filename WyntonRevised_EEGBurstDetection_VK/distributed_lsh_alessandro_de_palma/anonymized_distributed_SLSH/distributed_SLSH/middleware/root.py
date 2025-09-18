'''
    File containing the middleware implementation for a distributed (S)LSH system.
'''

import multiprocessing
from middleware.forwarder import execute_forwarder, check_termination
from middleware.reducer import execute_reducer
from middleware.utils.networking import *
from worker_node.utils.logging_node import TableConstructionLog
from math import ceil
from time import time, sleep
from worker_node.query import Query


def execute_middleware(node_addresses,
                       cores,
                       n,
                       d,
                       k,
                       X=[],
                       labels=[],
                       queries=[],
                       filename="",
                       synchronous=False,
                       prediction=False):
    """
    Execute a distributed SLSH's system middleware. It is in charge of distributing the dataset to the nodes,
    of broadcasting the queries and finally to yield the final output.

    :param node_addresses: the list of nodes' addresses in the form (IP, port).
    :param cores: the number of cores.
    :param filename: the name of the dataset's file (optional).
    :param n: the number of points the dataset cointains.
    :param d: the dimensionality of the dataset.
    :param X: the dataset as numpy matrix (if not provided, data is read from the filename).
    :param labels: the labels of the dataset points (if not provided, data is read from the filename).
    :param queries: a list of the queries to perform (if not provided, they are randomly sampled from the dataset).
    :param k: the number of nearest neighbors to retrieve.
    :param synchronous: a flag for whether the queries should be performed syhnchronously.
    :param prediction: a flag for whether prediction should be performed.

    :return: (table construction log, list of the queries with timestamps and their output)
    """

    if X == [] and filename == "":
        raise ValueError("At least one filename and X must be provided.")

    if prediction == True and (X == [] or labels == []):
        raise ValueError(
            "Prediction from filename not supported. Labels and X must be provided in advance."
        )

    # NOTE: the nodes use pipes instead of queries since each process would both read and write from the queue (this causes synchronization issues).

    # INFO.
    print("Middleware up and running.")
    """ Processes setup. """
    # Spawn forwarder.
    forwarder_queue = multiprocessing.Queue(
    )  # Use a queue to send the queries to the forwarder.
    forwarder = multiprocessing.Process(
        target=execute_forwarder, args=(node_addresses, forwarder_queue))
    forwarder.start()

    # Spawn reducer.
    # NOTE: the queries are processed sequentially (logically) at the nodes and sent in the same TCP stream, hence no reordering will occur.
    reducer_queue = multiprocessing.Queue(
    )  # Use a queue to retrieve the queries' outputs from the reducer.
    reducer = multiprocessing.Process(
        target=execute_reducer,
        args=(node_addresses, k, reducer_queue, synchronous, prediction))
    reducer.start()
    """ Table construction. """
    # Create a client socket connected to each node.
    # The root use the forwarder's port + 2.
    node_addresses = [(node_address[0], node_address[1] + 2)
                      for node_address in node_addresses]
    nodes = create_socket_connections(node_addresses)

    # INFO.
    print("Start table construction on nodes.")

    # Create table construction logging infrastructure.
    table_log = TableConstructionLog()
    table_log.time_start = time()  # Start measuring table construction time.

    # Send random seeds to have the same hashes over al l the tables.
    send_seeds(nodes, cores)

    # Send dataset stored in filename by slices.
    if filename != "":
        queries = send_by_contiguous_slices(
            n, d, nodes, X=X, labels=labels, filename=filename)
    else:
        send_by_contiguous_slices(
            n, d, nodes, X=X, labels=labels, filename=filename)

    # INFO.
    print("Dataset distributed, waiting for the nodes to construct tables.")

    # Synchronize after table construction.
    synchronize_table_construction(nodes)
    # End of table construction time.
    table_log.time_end = time()

    # INFO.
    print("Table construction terminated.")

    # Close root sockets.
    for node in nodes:
        node.close()
    """ Query resolution. Forwarder and Reducer are used, now. """
    counter = 0
    sampling_ratio = 20  # The sampling ratio for printing queries.

    # Synchronous query execution.
    if synchronous:
        for i in range(len(queries)):

            query = queries[i]

            # INFO.
            if counter % sampling_ratio == 0:
                print(
                    "Start to synchronously process query {}.".format(counter))

            # Start measuring time for the query.
            query.time_middleware_start = time()
            # Send it to the forwarder.
            forwarder_queue.put(query, block=True)
            # Retrieve output from reducer and store it.
            query = reducer_queue.get(block=True)
            queries[i] = query
            query.time_middleware_end = time(
            )  # This query's processing has ended.

            # INFO.
            if counter % sampling_ratio == 0:
                print("Query input: {} \nQuery output: {}".format(
                    query.point, query.neighbors))
                if prediction:
                    print("Query labels:{}".format(query.neighbors_labels))
            counter += 1

        # Terminate both the forwarder and the reducer.
        forwarder_queue.put("terminate", block=True)

    # Asynchronous query execution.
    else:
        # Send queries to the forwarder.
        for query in queries:

            # INFO.
            if counter % sampling_ratio == 0:
                print("Forwarding query {} to nodes.".format(counter))

            query.time_middleware_start = time(
            )  # Start measuring time for this query.
            forwarder_queue.put(query, block=True)
            sleep(0.2)  # Say, the queries arrive every 0.2 seconds.
            counter += 1

        # Terminate processes by sending a terminate message to the pipes.
        forwarder_queue.put("terminate", block=True)

        # Retrieve outputs from reducer.
        counter = 0  # Counter used to iterate on queries.
        while True:
            query = reducer_queue.get(block=True)
            # Break if the queries have ended.
            if check_termination(query):
                break

            queries[
                counter] = query  # Retrieve the query and substitute it in the list.

            # INFO.
            if counter % sampling_ratio == 0:
                print("Query input: {} \nQuery output: {}".format(
                    query.point, query.neighbors))
            counter += 1

    # INFO.
    print("Queries ended, terminating.")

    forwarder.join()
    reducer.join()

    return table_log, queries


def send_by_contiguous_slices(n, d, nodes, X=[], labels=[], filename=""):
    """
    Send the dataset by slices from file. Slicing is done by separating contiguous portions of the file.
    Only 1/len(nodes) of the file file fit into memory.
    In the file, each point occupies one line and the elements of the point are space-separated.

    :param filename: the name of the file to read the dataset from (optional).
    :param n: the number of points in the dataset.
    :param d: the dimensionality of the dataset.
    :param X: the dataset as numpy matrix (if not provided, data is read from the filename).
    :param labels: the labels of the dataset points (if not provided, data is read from the filename).

    :return: nothing.
    """

    queries = []

    # Read dataset from file.
    if filename != "":
        # Queries retrieval.
        n_queries = 2000
        n = n - n_queries
        query_indices = np.sort(
            np.random.choice(n, size=n_queries, replace=False))
        query_labels = []

        p = len(nodes)  # Number of nodes.
        slice_size = int(ceil(float(n) / p))
        remainder_size = n % slice_size

        with open(filename, "r") as file:
            counter = 0
            slice_index = 0
            query_index = 0
            line_number = 0
            # allocate numpy array containing the slice in which a point is a column.
            c_slice = np.empty((d, slice_size))

            for line in file:

                point_string = line.split(" ")
                point = np.array([float(x) for x in point_string])

                if query_index < n_queries:
                    if line_number == query_indices[query_index]:
                        queries.append(Query(point))
                        query_index += 1
                        line_number += 1
                        continue

                c_slice[:, counter] = point
                counter += 1

                # If the slice is full, send it to the nodes.
                if counter == slice_size:
                    send_slice(c_slice, nodes[slice_index], labels_slice=[])
                    slice_index += 1
                    counter = 0
                    if slice_index == p - 1:
                        slice_size = remainder_size
                    c_slice = np.empty((d, slice_size))

                line_number += 1

    # Use provided matrix, permute it and send it to the nodes.
    else:
        prediction = (labels != [])

        n = np.shape(X)[1]
        p = len(nodes)  # Number of nodes.
        slice_size = int(ceil(float(n) / p))

        # Permute matrix.
        permuted_indices = np.random.permutation(n)
        X = X[:, permuted_indices]
        if prediction:
            labels = labels[permuted_indices]

        for i in range(len(nodes)):
            c_labels = []
            if i != p - 1:
                c_slice = X[:, i * slice_size:(i + 1) * slice_size]
                if prediction:
                    c_labels = labels[i * slice_size:(i + 1) * slice_size]
            else:
                c_slice = X[:, i * slice_size:]
                if prediction:
                    c_labels = labels[i * slice_size:]

            send_slice(c_slice, nodes[i], labels_slice=c_labels)

    return queries


def synchronize_table_construction(nodes):
    """
    Wait for each node to terminate the table construction phase before sending the queries.

    :param nodes: the list of the node sockets
    :return: nothing
    """

    for node in nodes:
        message = read_data(node)
        if not isinstance(message, str):
            raise ValueError(
                "Wrong table construction synchronization message received.")
        else:
            if message != "tables-done":
                raise ValueError(
                    "Wrong table construction synchronization message received."
                )


def send_slice(slice, node, labels_slice=[]):
    """
    Send the slice to the node, in the correct format.

    :param slice: the slice to send
    :param node: the node to send it to
    :param labels_slice: optional, contains the corresponding slice of the label array.

    :return: nothing
    """

    send_data(slice, node)
    if len(labels_slice) > 0:
        send_data(labels_slice, node)


def send_seeds(nodes, cores):
    """
    Send each node a list of middleware-generated seeds to be used by each of its cores.
    This ensures that the hash functions generated at each node are identical to each other.

    :param nodes: the list of the nodes' addresses.
    :param cores: the number of cores.

    :return: nothing
    """

    # The list of seeds is a function of the current system time.
    seeds = [time() * i for i in range(cores)]

    for node in nodes:
        send_data(seeds, node)
