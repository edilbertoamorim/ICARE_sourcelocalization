"""
    The code responsible for the collection of each query's outputs and of its reduction to the final result.
"""

from middleware.utils.networking import *
from worker_node.SLSH.selectors import NearestPoints
from worker_node.SLSH.lsh import L1
import numpy as np
from time import time
from middleware.forwarder import check_termination


def execute_reducer(node_addresses, k, root_queue, synchronous, prediction):
    """
    Execute the reducer process, which retrieves the partial query outputs from the nodes
    and returns their reduction (i.e., the final output).

    :param node_addresses: the (ip, port) list of the nodes.
    :param k: the number of NN to retrieve.
    :param root_queue: the queue where to put the query output.
    :param synchronous: a flag for whether the queries should be performed syhnchronously.
    :param prediction: a flag for whether prediction should be performed.

    :return: nothing
    """

    # The reducers use the forwarders' port + 1.
    node_addresses = [(node_address[0], node_address[1] + 1)
                      for node_address in node_addresses]

    # Create a client socket connected to each node.
    nodes = create_socket_connections(node_addresses)

    # NOTE: the queries are processed sequentially (logically) at the nodes and sent in the same TCP stream, hence no reordering will occur.
    # Retrieve queries' outputs, perform reduction and send it to the root.
    termination_flag = False
    while True:
        selector = NearestPoints(use_dataset=False, prediction=prediction)
        c_queries = []
        for node in nodes:
            # The return value is (partial_query_output, query.point)
            query = read_data(node)

            # Check for queries termination.
            if check_termination(query):
                termination_flag = True
                break

            # Append query to list.
            c_queries.append(query)

            # Add the output list to the selector to collect partial outputs from all the nodes.
            if not prediction:
                selector.add(query.neighbors)
            else:
                # In case we perform prediction, we need to keep the labels associated to the points.
                selector.add((query.neighbors, query.neighbors_labels))

        if termination_flag:
            break

        query = max(c_queries, key=lambda q: q.comparisons)

        # Compute a single query's output and send it to the root via the queue.
        if not prediction:
            query_output = selector.filter(L1, k, query)
        else:
            query_output, query_output_labels = selector.filter(L1, k, query)
            query.neighbors_labels = query_output_labels
        query.neighbors = query_output

        if synchronous:
            root_queue.put(query, block=True)
        # In the asynchronous case, send the end time too.
        else:
            query.time_middleware_end = time()
            root_queue.put(query, block=True)

    if not synchronous:
        # Notify termination to the root.
        send_termination_root(root_queue)

    # Close sockets.
    for node in nodes:
        node.close()


def send_termination_root(root_queue):
    """
    Send a termination message to the root. It is the "terminate" string.

    :param nodes: the list of the nodes' addresses.
    :return: nothing
    """

    root_queue.put("terminate")
