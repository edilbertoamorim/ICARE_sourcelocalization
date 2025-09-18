"""
File containing all necessary methods to perform prediction from K-NN.

"""

from math import sqrt


def compute_accuracy(queries, query_labels):
    """
    Compute the accuracy over the set of queries, provided their labels.
    Labels and queries must have the same ordering.

    :param queries: the list of queries
    :param query_labels: the list of labels
    :return: accuracy
    """

    correctly_classified = 0
    for i in range(len(queries)):
        query = queries[i]
        clabel = compute_query_label(query)
        if clabel == query_labels[i]:
            correctly_classified += 1

    return float(correctly_classified) / len(queries)


def compute_recall(queries, query_labels):
    """
    Compute the recall on positive AHE over the set of queries, provided their labels.
    Labels and queries must have the same ordering.

    :param queries: the list of queries
    :param query_labels: the list of labels
    :return: accuracy
    """

    positives = len([lab for lab in query_labels if lab == 1])

    if positives == 0:
        return -2

    true_positives = 0
    for i in range(len(queries)):
        query = queries[i]
        clabel = compute_query_label(query)
        if query_labels[i] == 1:
            if clabel == query_labels[i]:
                true_positives += 1

    return float(true_positives) / positives


def compute_mcc(queries, query_labels):
    """
    Compute the Matthews correlation coefficient over the set of queries, provided their labels.
    Labels and queries must have the same ordering.

    :param queries: the list of queries
    :param query_labels: the list of labels
    :return: mcc
    """

    true_positives = 0
    true_negatives = 0
    false_positives = 0
    false_negatives = 0
    for i in range(len(queries)):
        query = queries[i]
        clabel = compute_query_label(query)
        if query_labels[i] == 1:
            if clabel == query_labels[i]:
                true_positives += 1
            else:
                false_negatives += 1
        elif query_labels[i] == 0:
            if clabel == query_labels[i]:
                true_negatives += 1
            else:
                false_positives += 1

    denominator_2 = (true_positives + false_positives) * (
        true_positives + false_negatives
    ) * (true_negatives + false_positives) * (true_negatives + false_negatives)
    if denominator_2 == 0:
        return -2
    numerator = true_positives * true_negatives - false_positives * false_negatives

    return float(numerator) / sqrt(denominator_2)


def compute_query_label(query):
    """
    Compute the label of the query by majority voting on its neighbors.

    :param query: the query whose feature must be computed
    :return: binary label (1 or 0)
    """

    ones = 0
    zeros = 0
    for clabel in query.neighbors_labels:
        if clabel == 0:
            zeros += 1
        elif clabel == 1:
            ones += 5  # Count a positive neighbor way more to account for query unbalance.

    return int(ones >= zeros)
