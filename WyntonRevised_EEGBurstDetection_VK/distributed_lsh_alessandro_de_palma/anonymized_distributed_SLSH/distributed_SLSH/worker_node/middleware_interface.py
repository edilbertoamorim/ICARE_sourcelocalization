"""
    File containing a class acting as interface to the middleware. It provides all the methods to interact with it.
    [1] https://stackoverflow.com/questions/32274907/why-does-tcp-socket-slow-down-if-done-in-multiple-system-calls
"""

import socket
from middleware.utils.networking import *
from worker_node.query import Query


class MiddlewareInterface():
    """
        Class acting as interface to the middleware.
        It acts as a wrapper to all the communication to the middleware and manages the necessary sockets for the goal.
    """

    def __init__(self, address=('', 1025)):
        """
        Create and wait for a single connection on three different sockets:
        each of them is devoted to communication with a different middleware thread.

        :parameter address: optional, if a different address has to be used from (all available interfaces, port 1025).
        """

        forwarder_address = address
        reducer_address = (address[0], address[1] + 1)
        root_address = (address[0], address[1] + 2)

        # Initialize forwarder socket.
        forwarder_socket = socket.socket(socket.AF_INET,
                                         socket.SOCK_STREAM)  # Use IPv4, TCP.
        forwarder_socket.setsockopt(
            socket.SOL_SOCKET, socket.SO_REUSEADDR,
            1)  # Avoid "address already in use" issues.
        forwarder_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY,
                                    1)  # Avoid problem described in [1]
        forwarder_socket.setblocking(True)  # Use blocking operations.
        forwarder_socket.bind(
            forwarder_address
        )  # Receive on all available interfaces, on the specified port.
        forwarder_socket.listen(1)

        # Initialize receiver socket.
        reducer_socket = socket.socket(socket.AF_INET,
                                       socket.SOCK_STREAM)  # Use IPv4, TCP.
        reducer_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR,
                                  1)  # Avoid "address already in use" issues.
        reducer_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY,
                                  1)  # Avoid problem described in [1]
        reducer_socket.setblocking(True)  # Use blocking operations.
        reducer_socket.bind(
            reducer_address
        )  # Receive on all available interfaces, on the port for the forwarder+1.
        reducer_socket.listen(1)

        # Initialize root socket.
        root_socket = socket.socket(socket.AF_INET,
                                    socket.SOCK_STREAM)  # Use IPv4, TCP.
        root_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR,
                               1)  # Avoid "address already in use" issues.
        root_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY,
                               1)  # Avoid problem described in [1]
        root_socket.setblocking(True)  # Use blocking operations.
        root_socket.bind(
            root_address
        )  # Receive on all available interfaces, on the port for the forwarder+2.
        root_socket.listen(1)

        # Accept connections.
        root_connection, address = root_socket.accept()
        root_connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY,
                                   1)  # Avoid problem described in [1]
        reducer_connection, address = reducer_socket.accept()
        reducer_connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY,
                                      1)  # Avoid problem described in [1]
        forwarder_connection, address = forwarder_socket.accept()
        forwarder_connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY,
                                        1)  # Avoid problem described in [1]

        self.forwarder_socket = forwarder_socket
        self.forwarder_connection = forwarder_connection
        self.reducer_socket = reducer_socket
        self.reducer_connection = reducer_connection
        self.root_socket = root_socket
        self.root_connection = root_connection

    def receive_dataset(self):
        """
        Receive the dataset on a socket.

        :return: the dataset
        """

        X = read_data(self.root_connection)

        return X

    def receive_labels(self):
        """
        Receive labels on a socket.

        :return: the labels
        """

        labels = read_data(self.root_connection)

        return labels

    def receive_seeds(self):
        """
        Receive the random seeds from the middleware. This is to keep the hashes the same
        across nodes.

        :return: the list of seeds (one per core)
        """

        seeds = read_data(self.root_connection)

        return seeds

    def send_table_construction_notification(self):
        """
        Notify the middleware that all the tables have been constructed.

        :return: nothing
        """

        send_data("tables-done", self.root_connection)

    def receive_query(self):
        """
        Receive a query from the middleware.

        :return: a Query instance for the query or false in case of termination.
        """
        query = read_data(self.forwarder_connection)

        if isinstance(query, str):
            if query == "terminate":
                return False

        return query

    def send_query_output(self, query):
        """
        Send a query's local results.

        :param output: the results' list
        :param query: the query itself

        :return: nothing
        """

        send_data(query, self.reducer_connection)

    def send_termination(self):
        """
        Send the middleware a notification that the node has processed all queries.

        :return: nothing.
        """

        send_data("terminate", self.reducer_connection)

    def close(self):
        """
        Close interface to the middleware (all the sockets).

        :return: nothing.
        """

        self.forwarder_connection.shutdown(1)
        self.forwarder_connection.close()
        self.forwarder_socket.close()

        self.reducer_connection.shutdown(1)
        self.reducer_connection.close()
        self.reducer_socket.close()

        self.root_connection.shutdown(1)
        self.root_connection.close()
        self.root_socket.close()
