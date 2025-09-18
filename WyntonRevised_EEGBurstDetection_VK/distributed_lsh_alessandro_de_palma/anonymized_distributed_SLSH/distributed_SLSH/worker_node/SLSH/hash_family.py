import random
import numpy as np
from abc import ABCMeta


class HashFamily():
    """
    Abstract hash family class
    """
    __metaclass__ = ABCMeta

    def sample_fn(self):
        """
        Randomly return a function from the hash family
        :returns: hash function
        """
        pass


class L1LSH(HashFamily):
    def __init__(self, ranges):
        self.d = len(ranges)
        self.ranges = ranges  # a list of pairs indicating the extremes of the range.

    def sample_fn(self):
        """
        Randomly select an axis parallel hyperplane and returned function returns 0 or 1 depending on which side point lies on
        """
        i = int(random.random() * self.d)
        t = random.uniform(self.ranges[i][0], self.ranges[i][1])

        #print i,t
        def f(x):
            #x is an element in X^d
            return int(x[i] >= t)

        return f


class COSLSH(HashFamily):
    """
    data must be normalized for this
    """

    def __init__(self, d):
        self.d = d  # Dimensionality of the metric space.

    def sample_fn(self):
        """
        Randomly select a hyperplane and returned function returns 0 or 1 depending on which side point lies on
        """
        r = np.random.normal(size=self.d)

        def f(x):
            #x is an element in X^d
            return np.inner(x, r) >= 0  # Slightly faster than dot().

        return f


def normalize(X):
    """
    Normalize a corpus of data X
    :param X: dataset X
    :type X: list of tuples
    """
    ret = []
    for x in X:
        leng = np.sum(np.square(x))
        if leng == 0:
            ret.append(x)
        else:
            ret.append(tuple(np.array(x) / leng))
    return ret
