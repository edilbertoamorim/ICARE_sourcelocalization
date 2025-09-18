import unittest
import numpy as np
from worker_node.SLSH.hash_family import *
from worker_node.node import *


class TestDistributedlSLSH(unittest.TestCase):
    def test_distributed_prediction(self):
        """
        Test that a single node correctly executes in the distributed setting.
        It assumes middleware/tests/system_test.py is already running (set to a single node).
        This function tests the system in prediction mode.
        """

        cores = 2
        D = 80  # Dimensionality of a point.
        H_out = L1LSH([(-5, 5)] * D)
        H_in = COSLSH(D)

        m_out = 10
        L_out = 50
        m_in = 10
        L_in = 10
        k = 1
        alpha = 0.1

        # Execute parallel code.
        temp1, queries = execute_node(
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

        self.assertTrue(np.shape(queries[0].neighbors[0])[0] == D)
        self.assertTrue(np.array_equal(queries[0].neighbors_labels[0], 0))
