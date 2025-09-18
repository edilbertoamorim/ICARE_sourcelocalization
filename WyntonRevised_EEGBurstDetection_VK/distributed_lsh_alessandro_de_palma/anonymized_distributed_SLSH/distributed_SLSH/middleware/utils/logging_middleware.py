"""
    File containing logging utilities for measurements on the middleware (global).
"""

import logging
import numpy as np


def execute_middleware_logging(parameters,
                               queries,
                               table_log,
                               accuracy=-1,
                               recall=-1,
                               mcc=-5,
                               accparameters=None):
    """
    Log the execution into a file

    :param parameters: the parameters to use as filename
    :param queries: the queries logs
    :param table_log: the table construction log

    :return: nothing
    """

    filename = '../results/distributed/{}-{}nodes-{}cores.txt'.format(
        parameters[0], parameters[1], parameters[2])

    logging.basicConfig(
        filename=filename,
        format='%(message)s',
        level=logging.INFO,
        filemode='w')

    # Log table construction timestamps.
    logging.info("tables,{},{}".format(table_log.time_start,
                                       table_log.time_end))

    # Log query timestamps.
    q_times = []
    for query in queries:
        logging.info("query,{},{},{}".format(query.time_middleware_start,
                                             query.time_middleware_end,
                                             query.comparisons))
        q_times.append(query.time_middleware_end - query.time_middleware_start)

    print("Table construction time: {}".format(table_log.time_end -
                                               table_log.time_start))
    median_query = np.median(np.array(q_times))
    print("Median query time: {}".format(median_query))
    median_maxcomparison = np.median([q.comparisons for q in queries])
    print("Median max number of comparisons: {}".format(median_maxcomparison))

    if accuracy != -1:
        with open("../results/" + "accuracy-testing.txt", "a") as file:
            print(
                "mout{}_Lout{}_min{}_Lin{}_alpha{}_acc{}_recall{}_mcc{}_medquery{}_comp{}_n{}_k{}".
                format(accparameters[0], accparameters[1], accparameters[2],
                       accparameters[3], accparameters[4], accuracy, recall,
                       mcc, median_query, median_maxcomparison,
                       accparameters[5], accparameters[6]),
                file=file)
