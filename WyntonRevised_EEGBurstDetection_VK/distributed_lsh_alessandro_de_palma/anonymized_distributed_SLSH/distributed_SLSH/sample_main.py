'''
    File containing measurements to be executed.
'''

import sys

from worker_node.SLSH.hash_family import *
from worker_node.node import execute_node
from worker_node.query import Query
from worker_node.utils.logging_node import execute_node_logging
from middleware.utils.logging_middleware import execute_middleware_logging
from middleware.root import execute_middleware
from prediction import *


def test_node(cores, d, m_out, L_out, m_in, L_in, k, alpha):
    """
    Test that a single node correctly executes in the distributed setting.
    It assumes middleware/tests/system_test.py is already running (set to a single node).
    This function tests the system in prediction mode.
    """

    H_out = L1LSH([(-5, 5)] * d)
    H_in = COSLSH(d)

    # Execute parallel code.
    table_log, queries = execute_node(
        cores,
        k,
        m_out,
        L_out,
        m_in,
        L_in,
        H_out,
        H_in,
        alpha,
        distributed=True,
        prediction=True)

    execute_node_logging(("testlog", cores), queries, table_log)


def test_orchestrator(nodes_list, cores, n, d, m_out, L_out, m_in, L_in, k,
                      alpha):
    """
        Test the functioning of the Orchestrator communicating to a node.
        It assumes distributed_test.py is already running and waiting locally.
        This function tests the system in prediction mode.
    """

    synchronous = True

    # The dataset is a unit matrix of size D.
    X = np.eye(d)
    labels = np.ones(80, dtype=int)
    labels[21] = 0

    # Create query and expected result.
    x = X[21]
    queries = [
        Query(x * 2),
        Query(x * 1.5),
        Query(X[15] * 1.1),
        Query(X[12] * 1.12)
    ]
    query_labels = np.array(
        [0, 0, 1, 0],
        dtype=int)  # Fourth query is intentionally a false positive.

    # Execute parallel code.
    table_log, queries = execute_middleware(
        nodes_list,
        cores,
        n,
        d,
        k,
        queries=queries,
        X=X,
        labels=labels,
        synchronous=synchronous,
        prediction=True)

    accuracy = compute_accuracy(queries, query_labels)
    print("The prediction accuracy is: {}".format(accuracy))

    recall = compute_recall(queries, query_labels)
    print("The recall is: {}".format(recall))

    mcc = compute_mcc(queries, query_labels)
    print("The mcc is: {}".format(mcc))

    execute_middleware_logging(
        ("testlog", len(nodes_list), cores),
        queries,
        table_log,
        accuracy=accuracy,
        recall=recall,
        mcc=mcc,
        accparameters=(m_out, L_out, m_in, L_in, alpha, n, k))


if __name__ == "__main__":

    # Number of cores to run the nodes on.
    cores = 2

    # List of nodes the orchestrator operates on.
    nodes_list = [("127.0.0.1", 1025)]

    # Dataset info.
    d = 80  # Dimensionality of a point.
    n = 80

    # SLSH parameters.
    m_out = 10
    L_out = 50
    m_in = 10
    L_in = 10
    k = 1
    alpha = 0.1

    role = sys.argv[1]  # First command line argument is role (node or orchestrator).
    if role == "node":
        test_node(cores, d, m_out, L_out, m_in, L_in, k, alpha)

    elif role == "orchestrator":
        test_orchestrator(nodes_list, cores, n, d, m_out, L_out, m_in, L_in, k,
                          alpha)
