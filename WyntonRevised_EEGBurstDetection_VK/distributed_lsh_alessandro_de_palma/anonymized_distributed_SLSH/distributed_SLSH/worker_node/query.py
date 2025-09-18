'''
    File definining the query class. A handy wrapper for code instrumentation and to encapsulate
    the query's output.
'''


class Query():
    '''
    Wrapper class for a query. It allows to keep the timestamps with the query.
    NOTE: every process is going to have its different timestamps,
    since (non-shared) objects are copied when passed from one process to another.
    '''

    def __init__(self, query_point):

        self.point = query_point

        self.time_slsh_start = 0  # Time of slsh query processing start.
        self.time_slsh_end = 0  # Time of slsh query processing end.
        self.time_linearsearch = 0  # Time of linear search start (within slsh).

        self.time_node_start = 0  # Time of query processing start at the node.
        self.time_node_end = 0  # Time of query processing end at the node.

        self.time_middleware_start = 0  # Time of query start on middleware.
        self.time_middleware_end = 0  # Time of query end on middleware.

        self.comparisons = 0  # Number of comparisons which were necessary for the query

        self.predicted_label = 0  # Query label, used for prediction.
        self.neighbors = None  # List of neighbors of the query.
        self.neighbors_labels = None  # List of the labels for the query's neighbors (used only for prediction).
