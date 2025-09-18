'''
    The code responsible for the forwarding of the queries and of the dataset to the nodes.
'''
from middleware.utils.networking import *
from math import ceil


def execute_forwarder(node_addresses, root_queue):
    """
    Run the forwarding process, which creates a socket per node and first forwards the dataset and then the queries
    as they arrive on the pipe.

    :param node_addresses: list of nodes' addresses in the form (IP, port).
    :param root_queue: the queue used to communicate with the middleware root

    :return: nothing
    """
    # Create a client socket connected to each node.
    nodes = create_socket_connections(node_addresses)

    # Wait for a query to arrive, then broadcast it. When the termination query is sent, forward it to the nodes and return.
    while True:
        query = root_queue.get(block=True)

        if check_termination(query):
            send_termination_nodes(
                nodes)  # Send termination query to the nodes.
            break

        # Broadcast query, adjusting its index to the node's range.
        for node in nodes:
            send_data(query, node)

    for node in nodes:
        node.close()


def send_termination_nodes(nodes):
    """
    Send a termination message to all the nodes. It is a list containing the "terminate" string.

    :param nodes: the list of the nodes' addresses.
    :return: nothing
    """

    for node in nodes:
        send_data("terminate", node)


def check_termination(element):
    """
    Check whether the queries have ended. This is done respecting the internal protocol,
    which requires the sent element to be a "terminate" string.

    :param element: what to check termination on.
    :return: True if the queries have terminated, False otherwise.
    """

    if not isinstance(element, str):
        return False

    else:
        return element == "terminate"
