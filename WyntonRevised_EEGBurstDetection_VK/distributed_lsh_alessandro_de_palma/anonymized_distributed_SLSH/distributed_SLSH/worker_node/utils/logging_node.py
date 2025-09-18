'''
    File containing logging utilities for intranode measurements.
'''

import logging
import numpy as np


class TableConstructionLog():
    def __init__(self):
        self.time_start = 0  # Timestamp for table construction start.
        self.time_end = 0  # Timestamp for table construction end.


def execute_node_logging(parameters,
                         queries,
                         table_log,
                         accuracy=-1,
                         recall=-1,
                         mcc=-5,
                         accparameters=None,
                         exhaustive=False):
    '''
    Log the execution into a file

    :param parameters: the parameters to use as filename
    :param queries: the queries logs
    :param table_log: the table construction log

    :return: nothing
    '''

    filename = '../results/intranode/{}-{}cores.txt'.format(
        parameters[0], parameters[1])

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
        logging.info("query,{},{},{},{},{},{}".format(
            query.time_node_start, query.time_node_end, query.time_slsh_start,
            query.time_slsh_end, query.time_linearsearch, query.comparisons))
        q_times.append(query.time_node_end - query.time_node_start)

    print("Table construction time: {}".format(table_log.time_end -
                                               table_log.time_start))
    median_query = np.median(np.array(q_times))
    print("Median query time: {}".format(median_query))
    median_maxcomparison = np.median([q.comparisons for q in queries])
    print("Median max number of comparisons: {}".format(median_maxcomparison))

    if exhaustive and accuracy != -1:
        with open("../results/" + "accuracy-testing.txt", "a") as file:
            print(
                "exhaustive_cores{}_acc{}_recall{}_mcc{}_medquery{}_comp{}_n{}_k{}".
                format(accparameters[2], accuracy, recall, mcc, median_query,
                       median_maxcomparison, accparameters[0],
                       accparameters[1]),
                file=file)

    elif accuracy != -1:
        with open("../results/" + "accuracy-testing.txt", "a") as file:
            print(
                "mout{}_Lout{}_min{}_Lin{}_alpha{}_acc{}_recall{}_mcc{}_medquery{}_comp{}_n{}_k{}".
                format(accparameters[0], accparameters[1], accparameters[2],
                       accparameters[3], accparameters[4], accuracy, recall,
                       mcc, median_query, median_maxcomparison,
                       accparameters[5], accparameters[6]),
                file=file)
