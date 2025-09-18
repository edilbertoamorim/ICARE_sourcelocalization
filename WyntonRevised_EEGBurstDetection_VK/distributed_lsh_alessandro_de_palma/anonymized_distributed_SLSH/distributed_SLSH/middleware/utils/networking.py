'''
    File containing utilities for networking.
    [1] https://stackoverflow.com/questions/32274907/why-does-tcp-socket-slow-down-if-done-in-multiple-system-calls
'''

import numpy as np
import pickle
import struct
import socket


def read_data(receive_connection):
    '''
    Read data from connection receive_connection and return it.
    NOTE: this assumes the data was pickled before sending.

    :param receive_connection: the connection on which to receive.

    :return: the converted data.
    '''

    INTSIZE = 4
    packed_size = receive_connection.recv(INTSIZE)  # Receive size.
    size = struct.unpack_from("i", packed_size)[0]

    received = 0
    pickled_data = receive_connection.recv(size)
    received += len(pickled_data)

    # recv() returns if for some time data is not received. This is to avoid that in spite of unreliable networks.
    while received < size:
        partial_receive = receive_connection.recv(size - received)
        pickled_data += partial_receive
        received += len(partial_receive)

    data = pickle.loads(pickled_data)

    return data


def send_data(data, send_socket):
    '''
    Send data through send_socket.
    The data is pickled and the pickle size is sent as a separate message.

    :param data: the numpy array to send.
    :param send_socket: the socket to send on.

    :return: nothing.
    '''

    pickled = pickle.dumps(data)
    size = len(pickled)
    send_socket.sendall(bytearray(struct.pack(
        "i", size)))  # Send size separately first. This takes 4 bytes.
    send_socket.sendall(pickled)  # Send the object itself.


def create_socket_connections(node_addresses):
    """
    Create the client sockets used to connect to the nodes.

    :param node_addresses: the list of (ip, port) pairs for the nodes
    :return: nothing
    """

    nodes = []
    for node_address in node_addresses:
        node = socket.socket(socket.AF_INET,
                             socket.SOCK_STREAM)  # Use IPv4, TCP.
        node.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY,
                        1)  # Avoid problem described in [1]
        node.setblocking(True)  # Use blocking operations.
        node.connect(node_address)
        nodes.append(node)

    return nodes
