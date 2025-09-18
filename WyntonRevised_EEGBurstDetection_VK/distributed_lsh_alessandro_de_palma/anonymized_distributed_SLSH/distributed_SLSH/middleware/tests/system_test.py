import unittest
from worker_node.query import Query
from middleware.root import execute_middleware
import numpy as np


class TestDistributedSLSH(unittest.TestCase):
    def test_prediction_system(self):
        """
            Test the functioning of the system communicating to a node.
            It assumes distributed_test.py is already running and waiting locally.
            This function tests the system in prediction mode.
        """

        nodes_list = [("127.0.0.1", 1025)]
        cores = 2
        synchronous = True

        # The dataset is a unit matrix of size D.
        D = 80
        X = np.eye(D)
        labels = np.ones(80, dtype=int)
        labels[21] = 0

        # Create query and expected result.
        x = X[21]
        query1 = Query(x * 2)
        query2 = Query(x * 1.5)
        k = 1

        # Execute parallel code.
        temp1, queries = execute_middleware(
            nodes_list,
            cores,
            D,
            D,
            k,
            queries=[query1, query2],
            X=X,
            labels=labels,
            synchronous=synchronous,
            prediction=True)

        self.assertTrue(np.array_equal(queries[0].neighbors[0], x))
        self.assertTrue(np.array_equal(queries[0].neighbors_labels[0], 0))
